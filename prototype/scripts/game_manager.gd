extends Node

## 게임 전체 상태를 관리하는 오토로드 싱글톤
## 멀티데이 구조 및 손님 스케줄링 지원

signal reputation_changed(reputation_type: String, value: int)
signal day_changed(day: int)
signal customer_completed(customer_id: String, result: String)
signal day_ended(day: int)
signal game_over(ending_type: String)
signal news_triggered(text: String)

# 게임 설정
const MAX_DAYS: int = 7
const CUSTOMERS_PER_DAY: Dictionary = {
	1: 1,  # 튜토리얼
	2: 2,
	3: 2,
	4: 2,
	5: 2,
	6: 1,
	7: 1   # 최종일
}

# 게임 상태
var current_day: int = 1
var current_customer_index: int = 0
var game_started: bool = false
var day_in_progress: bool = false

# 평판 시스템 (0-100)
var reputation: Dictionary = {
	"mercy": 50,      # 자비
	"justice": 50,    # 정의
	"profit": 50      # 이익
}

# 손님 데이터 (JSON에서 로드하여 동적으로 구성)
var today_customers: Array = []
var completed_customers: Array = []

# 손님 결과 기록
var customer_results: Dictionary = {}

# 손님 스케줄 (Day -> [customer_ids])
var customer_schedule: Dictionary = {}

# 결과 연쇄 (특정 결과에 따른 후속 손님)
var pending_followups: Array = []

# 뉴스 큐
var pending_news: Array = []

# 수입 기록
var daily_earnings: Dictionary = {}
var total_earnings: int = 0

func _ready() -> void:
	_initialize_customer_schedule()

func _initialize_customer_schedule() -> void:
	# 기본 스케줄 설정
	# Day 1: 튜토리얼 (민지)
	# Day 2: 상승 (박 노인, 김 상병, 하늘)
	# Day 3: 전개 (정석현, 이 교수, 강 회장)
	# Day 4: 클라이맥스 (민지 어머니 - 조건부)
	# Day 5: 진실 (김수연 - 주인공 스토리)
	# Day 6-7: 해결 및 엔딩
	customer_schedule = {
		1: ["minji"],
		2: ["park_elder", "soldier_kim", "idol_trainee"],
		3: ["jung_seokhyun", "professor_lee", "debt_collector"],
		4: [],  # 조건부 손님 (minji_mother)
		5: ["jinwoo_sister"],  # 주인공 스토리
		6: [],  # 결과에 따른 후속
		7: []   # 최종 엔딩
	}

	# DialogueManager에서 손님별 day 정보 로드
	await get_tree().process_frame  # DialogueManager 로드 대기

	if Engine.has_singleton("DialogueManager") or has_node("/root/DialogueManager"):
		_sync_schedule_from_dialogues()

func _sync_schedule_from_dialogues() -> void:
	# DialogueManager의 대화 데이터에서 스케줄 동기화
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if not dialogue_manager:
		return

	# 스케줄 초기화
	for day in range(1, MAX_DAYS + 1):
		if not customer_schedule.has(day):
			customer_schedule[day] = []

	var customer_ids = dialogue_manager.get_all_customer_ids()
	for customer_id in customer_ids:
		var metadata = dialogue_manager.get_customer_metadata(customer_id)
		var day = metadata.get("day", 1)

		if day <= MAX_DAYS and not customer_schedule[day].has(customer_id):
			# 기존 스케줄에 없으면 추가
			if not _is_customer_scheduled(customer_id):
				customer_schedule[day].append(customer_id)

func _is_customer_scheduled(customer_id: String) -> bool:
	for day in customer_schedule:
		if customer_schedule[day].has(customer_id):
			return true
	return false

func start_day() -> void:
	day_in_progress = true
	current_customer_index = 0

	# 오늘의 손님 목록 구성
	today_customers = _get_customers_for_today()

	# 결과 연쇄에 의한 추가 손님
	_add_followup_customers()

	# 평판에 따른 특별 손님
	_add_reputation_based_customers()

	print("[GameManager] Day %d started with %d customers" % [current_day, today_customers.size()])

func _get_customers_for_today() -> Array:
	var customers = []
	var scheduled = customer_schedule.get(current_day, [])

	for customer_id in scheduled:
		if not completed_customers.has(customer_id):
			var customer_data = _create_customer_data(customer_id)
			if not customer_data.is_empty():
				customers.append(customer_data)

	return customers

func _create_customer_data(customer_id: String) -> Dictionary:
	# DialogueManager에서 메타데이터 가져오기
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if not dialogue_manager:
		return {}

	var metadata = dialogue_manager.get_customer_metadata(customer_id)
	if metadata.is_empty():
		return {}

	# 신뢰 요구 체크
	var trust_required = metadata.get("trust_required", 0)
	# 평판 체크 (향후 구현)

	return {
		"id": customer_id,
		"name": metadata.get("name", dialogue_manager.get_dialogue_data(customer_id).get("name", "Unknown")),
		"age": metadata.get("age", 0),
		"portrait": metadata.get("portrait", ""),
		"portrait_key": metadata.get("portrait_key", customer_id),
		"memory_type": metadata.get("memory_type", "unknown"),
		"memory_color": _parse_color(metadata.get("memory_color", [1, 1, 1, 1])),
		"summary": metadata.get("summary", ""),
		"puzzle_difficulty": metadata.get("puzzle_difficulty", 1)
	}

func _parse_color(color_data) -> Color:
	if color_data is Array and color_data.size() >= 3:
		var r = color_data[0]
		var g = color_data[1]
		var b = color_data[2]
		var a = color_data[3] if color_data.size() >= 4 else 1.0
		return Color(r, g, b, a)
	return Color.WHITE

func _add_followup_customers() -> void:
	# 결과 연쇄로 추가된 손님 처리
	var to_remove = []
	for followup in pending_followups:
		if followup.day == current_day:
			var customer_data = _create_customer_data(followup.customer_id)
			if not customer_data.is_empty():
				today_customers.append(customer_data)
			to_remove.append(followup)

	for item in to_remove:
		pending_followups.erase(item)

func _add_reputation_based_customers() -> void:
	# 평판에 따른 특별 손님 추가 (향후 구현)
	# Mercy > 70: 더 많은 정보 공유하는 손님
	# Justice > 70: 경찰 의뢰
	# Profit > 70: 암시장 딜러

	if reputation.mercy > 70:
		# 특별 손님 로직
		pass

	if reputation.justice > 70:
		# 경찰 관련 손님
		pass

	if reputation.profit > 70:
		# 암시장 딜러
		pass

func get_current_customer() -> Dictionary:
	if current_customer_index < today_customers.size():
		return today_customers[current_customer_index]
	return {}

func complete_customer(result: String) -> void:
	var customer = get_current_customer()
	if customer.is_empty():
		return

	var customer_id = customer.id
	customer_results[customer_id] = result
	completed_customers.append(customer_id)

	# 평판 변화 적용 (JSON에서 로드)
	_apply_reputation_from_json(customer_id, result)

	# 결과 연쇄 처리
	_process_consequences(customer_id, result)

	# 수입 기록
	_record_earnings(customer_id, result)

	emit_signal("customer_completed", customer_id, result)
	current_customer_index += 1

	# 자동 저장
	_trigger_auto_save()

func _apply_reputation_from_json(customer_id: String, result: String) -> void:
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if not dialogue_manager:
		return

	var effects = dialogue_manager.get_reputation_effects(customer_id, result)
	for rep_type in effects:
		_change_reputation(rep_type, effects[rep_type])

func _process_consequences(customer_id: String, result: String) -> void:
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if not dialogue_manager:
		return

	var consequences = dialogue_manager.get_consequences(customer_id, result)
	if consequences.is_empty():
		return

	# 뉴스 추가
	if consequences.has("news"):
		var news_day = current_day + 1  # 다음 날 뉴스
		pending_news.append({"day": news_day, "text": consequences.news})

	# 후속 손님 추가
	if consequences.has("followup_day") and consequences.followup_day != null:
		if consequences.has("followup_customer"):
			pending_followups.append({
				"day": consequences.followup_day,
				"customer_id": consequences.followup_customer
			})

func _record_earnings(customer_id: String, result: String) -> void:
	var earnings = 0
	match result:
		"accept":
			# 손님에 따라 다른 금액
			match customer_id:
				"minji":
					earnings = 5000000
				"park_elder":
					earnings = 3000000
				"jung_seokhyun":
					earnings = 10000000
				_:
					earnings = 5000000
		"modify":
			earnings = 2000000
		"reject":
			earnings = 0

	if not daily_earnings.has(current_day):
		daily_earnings[current_day] = 0
	daily_earnings[current_day] += earnings
	total_earnings += earnings

func _change_reputation(rep_type: String, amount: int) -> void:
	if not reputation.has(rep_type):
		return
	reputation[rep_type] = clampi(reputation[rep_type] + amount, 0, 100)
	emit_signal("reputation_changed", rep_type, reputation[rep_type])

func has_more_customers() -> bool:
	return current_customer_index < today_customers.size()

func end_day() -> void:
	day_in_progress = false

	# 오늘의 뉴스 발생
	_trigger_daily_news()

	emit_signal("day_ended", current_day)

	# 자동 저장
	_trigger_auto_save()

func start_new_day() -> void:
	current_day += 1
	current_customer_index = 0

	if current_day > MAX_DAYS:
		_trigger_game_over()
		return

	emit_signal("day_changed", current_day)
	start_day()

func _trigger_daily_news() -> void:
	var today_news = []
	for news in pending_news:
		if news.day == current_day:
			today_news.append(news.text)
			emit_signal("news_triggered", news.text)

	# 발생한 뉴스 제거
	pending_news = pending_news.filter(func(n): return n.day != current_day)

func get_pending_news_for_today() -> Array:
	var result = []
	for news in pending_news:
		if news.day == current_day:
			result.append(news.text)
	return result

func _trigger_game_over() -> void:
	var ending_type = get_ending_type()
	emit_signal("game_over", ending_type)

func _trigger_auto_save() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.has_method("auto_save"):
		save_manager.auto_save()

func reset_game() -> void:
	current_day = 1
	current_customer_index = 0
	game_started = false
	day_in_progress = false
	reputation = {"mercy": 50, "justice": 50, "profit": 50}
	today_customers.clear()
	completed_customers.clear()
	customer_results.clear()
	pending_followups.clear()
	pending_news.clear()
	daily_earnings.clear()
	total_earnings = 0

	_initialize_customer_schedule()

func get_ending_type() -> String:
	# 기본 엔딩: 가장 높은 평판
	var max_rep = "mercy"
	var max_value = reputation.mercy

	for key in reputation:
		if reputation[key] > max_value:
			max_value = reputation[key]
			max_rep = key

	return max_rep

func get_detailed_ending_type() -> String:
	# 확장된 엔딩 타입 (스토리 기반)
	var base_ending = get_ending_type()

	# 특수 조건 체크
	# 모든 손님 최적 결과 → 완벽한 기억
	if _check_perfect_ending():
		return "perfect"

	# 주인공 기억 관련 플래그 체크
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		if save_manager.has_flag("jinwoo_truth_revealed"):
			if save_manager.has_flag("chose_forget"):
				return "forgotten"
			elif save_manager.has_flag("chose_remember"):
				return "returner"

		if save_manager.has_flag("exposed_neocorp"):
			return "liberator"

	return base_ending

func _check_perfect_ending() -> bool:
	# 모든 손님에게 최적의 결과를 줬는지 체크
	var optimal_results = {
		"minji": "reject",      # 기억 지키기
		"park_elder": "modify", # 감정 흔적
		"jung_seokhyun": "modify"  # 단서 남기기
	}

	for customer_id in optimal_results:
		if customer_results.get(customer_id, "") != optimal_results[customer_id]:
			return false

	return true

func get_day_summary() -> Dictionary:
	return {
		"day": current_day,
		"customers_seen": current_customer_index,
		"earnings": daily_earnings.get(current_day, 0),
		"reputation": reputation.duplicate()
	}

func get_total_earnings() -> int:
	return total_earnings

func get_reputation_level(rep_type: String) -> String:
	var value = reputation.get(rep_type, 50)
	if value >= 80:
		return "very_high"
	elif value >= 60:
		return "high"
	elif value >= 40:
		return "medium"
	elif value >= 20:
		return "low"
	else:
		return "very_low"
