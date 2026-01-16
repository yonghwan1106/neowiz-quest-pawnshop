extends Node

## 게임 전체 상태를 관리하는 오토로드 싱글톤

signal reputation_changed(reputation_type: String, value: int)
signal day_changed(day: int)
signal customer_completed(customer_id: String, result: String)

# 게임 상태
var current_day: int = 1
var current_customer_index: int = 0
var game_started: bool = false

# 평판 시스템 (0-100)
var reputation: Dictionary = {
	"mercy": 50,      # 자비
	"justice": 50,    # 정의
	"profit": 50      # 이익
}

# 손님 데이터
var customers: Array[Dictionary] = []
var completed_customers: Array[String] = []

# 손님 결과 기록
var customer_results: Dictionary = {}

func _ready() -> void:
	_initialize_customers()

func _initialize_customers() -> void:
	customers = [
		{
			"id": "minji",
			"name": "민지",
			"age": 17,
			"portrait": "res://assets/portraits/minji.png",
			"memory_type": "happiness",
			"memory_color": Color(1.0, 0.85, 0.3),  # 황금빛
			"summary": "사이버네틱 팔 수술비를 위해 할머니와의 추억을 팔러 온 소녀",
			"dialogue_file": "res://resources/dialogues/minji.json",
			"puzzle_difficulty": 1
		},
		{
			"id": "park_elder",
			"name": "박 노인",
			"age": 72,
			"portrait": "res://assets/portraits/park_elder.png",
			"memory_type": "love",
			"memory_color": Color(1.0, 0.4, 0.6),  # 분홍빛
			"summary": "치매 아내를 위해 첫사랑 기억을 이식하려는 노인",
			"dialogue_file": "res://resources/dialogues/park_elder.json",
			"puzzle_difficulty": 2
		},
		{
			"id": "jung_seokhyun",
			"name": "정석현",
			"age": 28,
			"portrait": "res://assets/portraits/jung_seokhyun.png",
			"memory_type": "guilt",
			"memory_color": Color(0.6, 0.2, 0.2),  # 어두운 붉은빛
			"summary": "3년 전 범죄 기억을 팔아 죄책감에서 벗어나려는 남자",
			"dialogue_file": "res://resources/dialogues/jung_seokhyun.json",
			"puzzle_difficulty": 3
		}
	]

func get_current_customer() -> Dictionary:
	if current_customer_index < customers.size():
		return customers[current_customer_index]
	return {}

func complete_customer(result: String) -> void:
	var customer = get_current_customer()
	if customer.is_empty():
		return

	customer_results[customer.id] = result
	completed_customers.append(customer.id)

	# 평판 변화 적용
	_apply_reputation_change(customer.id, result)

	emit_signal("customer_completed", customer.id, result)
	current_customer_index += 1

func _apply_reputation_change(customer_id: String, result: String) -> void:
	match customer_id:
		"minji":
			match result:
				"accept":
					_change_reputation("mercy", 10)
					_change_reputation("profit", 5)
				"reject":
					_change_reputation("mercy", -5)
					_change_reputation("justice", 5)
				"modify":
					_change_reputation("mercy", 5)
					_change_reputation("justice", 5)
		"park_elder":
			match result:
				"accept":
					_change_reputation("mercy", 15)
					_change_reputation("justice", -5)
				"reject":
					_change_reputation("justice", 10)
					_change_reputation("mercy", -10)
				"modify":
					_change_reputation("mercy", 5)
					_change_reputation("justice", 10)
		"jung_seokhyun":
			match result:
				"accept":
					_change_reputation("profit", 20)
					_change_reputation("justice", -20)
				"reject":
					_change_reputation("justice", 15)
					_change_reputation("mercy", 5)
				"modify":
					_change_reputation("justice", 20)
					_change_reputation("mercy", 10)

func _change_reputation(rep_type: String, amount: int) -> void:
	reputation[rep_type] = clampi(reputation[rep_type] + amount, 0, 100)
	emit_signal("reputation_changed", rep_type, reputation[rep_type])

func has_more_customers() -> bool:
	return current_customer_index < customers.size()

func start_new_day() -> void:
	current_day += 1
	emit_signal("day_changed", current_day)

func reset_game() -> void:
	current_day = 1
	current_customer_index = 0
	game_started = false
	reputation = {"mercy": 50, "justice": 50, "profit": 50}
	completed_customers.clear()
	customer_results.clear()

func get_ending_type() -> String:
	var max_rep = "mercy"
	var max_value = reputation.mercy

	for key in reputation:
		if reputation[key] > max_value:
			max_value = reputation[key]
			max_rep = key

	return max_rep
