extends Control

## 전당포 메인 화면 컨트롤러
## 뉴스 티커, 일일 결산, 대기 손님 시각화 지원

var main_controller: Node = null

@onready var day_label: Label = $UI/DayLabel
@onready var mercy_bar: ProgressBar = $UI/ReputationPanel/VBox/MercyBar/ProgressBar
@onready var justice_bar: ProgressBar = $UI/ReputationPanel/VBox/JusticeBar/ProgressBar
@onready var profit_bar: ProgressBar = $UI/ReputationPanel/VBox/ProfitBar/ProgressBar
@onready var status_label: Label = $BottomPanel/MarginContainer/VBox/StatusLabel
@onready var wait_button: Button = $BottomPanel/MarginContainer/VBox/WaitButton
@onready var next_day_button: Button = $BottomPanel/MarginContainer/VBox/NextDayButton
@onready var customer_portrait: TextureRect = $CustomerArea/CustomerPortrait
@onready var neon_sign: Label = $ShopInterior/NeonSign

# 뉴스 티커 (새로 추가)
@onready var news_ticker_container: PanelContainer = $NewsTicker
@onready var news_ticker_label: Label = $NewsTicker/MarginContainer/HBox/NewsLabel

# 대기열 표시 (새로 추가)
@onready var queue_indicator: HBoxContainer = $UI/QueueIndicator
@onready var queue_count_label: Label = $UI/QueueIndicator/QueueCount

# 캐릭터 포트레잇 경로 매핑
const PORTRAIT_PATHS: Dictionary = {
	"minji": "res://assets/portraits/portrait_minji.png",
	"park_elder": "res://assets/portraits/portrait_park_elder.png",
	"jung": "res://assets/portraits/portrait_jung.png",
	"jung_seokhyun": "res://assets/portraits/portrait_jung.png",
	"soldier_kim": "res://assets/portraits/portrait_soldier_kim.png",
	"idol_trainee": "res://assets/portraits/portrait_haneul.png",
	"professor_lee": "res://assets/portraits/portrait_professor_lee.png",
	"debt_collector": "res://assets/portraits/portrait_gang.png",
	"minji_mother": "res://assets/portraits/portrait_minji_mother.png",
	"jinwoo_sister": "res://assets/portraits/portrait_suyeon.png"
}

var customer_entered: bool = false
var news_queue: Array = []
var news_scroll_tween: Tween = null

func _ready() -> void:
	_connect_signals()
	_update_ui()
	_animate_neon_sign()
	_play_pawnshop_bgm()
	_setup_news_ticker()
	_update_queue_indicator()

func _connect_signals() -> void:
	if wait_button:
		wait_button.pressed.connect(_on_wait_button_pressed)
		wait_button.mouse_entered.connect(_on_button_hover.bind(wait_button))

	if next_day_button:
		next_day_button.pressed.connect(_on_next_day_pressed)
		next_day_button.mouse_entered.connect(_on_button_hover.bind(next_day_button))

	GameManager.reputation_changed.connect(_on_reputation_changed)
	GameManager.customer_completed.connect(_on_customer_completed)
	GameManager.news_triggered.connect(_on_news_triggered)

func set_main_controller(controller: Node) -> void:
	main_controller = controller

func setup(_data: Dictionary) -> void:
	_update_ui()
	_play_pawnshop_bgm()
	_setup_news_ticker()
	_update_queue_indicator()

func _play_pawnshop_bgm() -> void:
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_bgm"):
		audio_manager.play_bgm("pawnshop")

func _play_sfx(sfx_name: String) -> void:
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(sfx_name)

func _on_button_hover(button: Button) -> void:
	if button.disabled:
		return
	var hover_tween = create_tween()
	hover_tween.tween_property(button, "scale", Vector2(1.03, 1.03), 0.1)
	hover_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	_play_sfx("button_hover")

func _update_ui() -> void:
	if day_label:
		day_label.text = "Day %d / %d" % [GameManager.current_day, GameManager.MAX_DAYS]

	if mercy_bar:
		mercy_bar.value = GameManager.reputation.mercy
	if justice_bar:
		justice_bar.value = GameManager.reputation.justice
	if profit_bar:
		profit_bar.value = GameManager.reputation.profit

	_update_buttons_state()
	_update_queue_indicator()

func _update_buttons_state() -> void:
	if GameManager.has_more_customers():
		if wait_button:
			wait_button.visible = true
			wait_button.disabled = false
		if next_day_button:
			next_day_button.visible = false
		if status_label:
			var remaining = GameManager.today_customers.size() - GameManager.current_customer_index
			status_label.text = "전당포 문을 열었습니다. 손님 %d명이 기다리고 있습니다..." % remaining
	else:
		if wait_button:
			wait_button.visible = false
		if next_day_button:
			next_day_button.visible = true
			next_day_button.disabled = false
		if status_label:
			status_label.text = "오늘의 손님을 모두 만났습니다."

func _animate_neon_sign() -> void:
	if not neon_sign:
		return
	var tween = create_tween().set_loops()
	tween.tween_property(neon_sign, "modulate:a", 0.7, 0.5)
	tween.tween_property(neon_sign, "modulate:a", 1.0, 0.5)

# ===== 뉴스 티커 =====

func _setup_news_ticker() -> void:
	# 오늘의 뉴스 가져오기
	var today_news = GameManager.get_pending_news_for_today()

	# 기본 뉴스 추가 (첫 날 또는 뉴스가 없을 때)
	if today_news.is_empty():
		today_news = _get_default_news_for_day(GameManager.current_day)

	news_queue = today_news

	if news_ticker_container and news_queue.size() > 0:
		news_ticker_container.visible = true
		_start_news_scroll()
	elif news_ticker_container:
		news_ticker_container.visible = false

func _get_default_news_for_day(day: int) -> Array:
	# 날짜별 기본 뉴스
	match day:
		1:
			return ["[네오시티 뉴스] 기억 거래 시장 연 매출 10조 돌파... 윤리 논란 계속"]
		2:
			return ["[속보] 네오코프, 강제 기억 추출 의혹 부인... '자발적 기증'"]
		3:
			return ["[사회] 기억 이식 부작용으로 3명 사망... 당국 조사 착수"]
		4:
			return ["[경제] 기억 전당포 업계, 규제 강화에 반발"]
		5:
			return ["[독점] 네오코프 내부 고발자 등장? '진실이 밝혀질 것'"]
		6:
			return ["[긴급] 기억 거래 관련 대규모 시위 예정"]
		7:
			return ["[최종] 오늘, 기억 거래법 개정안 표결... 전당포의 운명은?"]
		_:
			return []

func _start_news_scroll() -> void:
	if not news_ticker_label or news_queue.is_empty():
		return

	var full_text = " +++ ".join(news_queue) + " +++ "
	news_ticker_label.text = full_text

	# 스크롤 애니메이션
	_animate_news_ticker()

func _animate_news_ticker() -> void:
	if not news_ticker_label:
		return

	# 기존 트윈 정리
	if news_scroll_tween and news_scroll_tween.is_valid():
		news_scroll_tween.kill()

	# 시작 위치 설정
	var container_width = news_ticker_container.size.x if news_ticker_container else 800
	var text_width = news_ticker_label.size.x

	news_ticker_label.position.x = container_width

	# 스크롤 트윈 (무한 루프)
	news_scroll_tween = create_tween().set_loops()
	var duration = (container_width + text_width) / 100.0  # 속도 조절
	news_scroll_tween.tween_property(news_ticker_label, "position:x", -text_width, duration)
	news_scroll_tween.tween_callback(_reset_news_position)

func _reset_news_position() -> void:
	if news_ticker_label and news_ticker_container:
		news_ticker_label.position.x = news_ticker_container.size.x

func _on_news_triggered(news_text: String) -> void:
	if not news_queue.has(news_text):
		news_queue.append(news_text)
		_start_news_scroll()

# ===== 대기열 표시 =====

func _update_queue_indicator() -> void:
	if not queue_indicator:
		return

	var remaining = GameManager.today_customers.size() - GameManager.current_customer_index - 1
	if remaining <= 0:
		queue_indicator.visible = false
		return

	queue_indicator.visible = true

	# 대기 손님 수 업데이트
	if queue_count_label:
		queue_count_label.text = str(remaining)

# ===== 손님 처리 =====

func _on_wait_button_pressed() -> void:
	if not GameManager.has_more_customers():
		return

	_play_sfx("button_click")
	if wait_button:
		wait_button.disabled = true
	if status_label:
		status_label.text = "누군가 문을 두드립니다..."

	# 손님 등장 애니메이션
	await get_tree().create_timer(1.0).timeout

	var customer = GameManager.get_current_customer()
	_show_customer(customer)

func _show_customer(customer: Dictionary) -> void:
	if customer.is_empty():
		return

	# 손님 입장 효과음
	_play_sfx("customer_enter")

	# 캐릭터 포트레잇 로드
	var portrait_key = customer.get("portrait_key", customer.id)
	if customer_portrait:
		if PORTRAIT_PATHS.has(portrait_key):
			var portrait_texture = load(PORTRAIT_PATHS[portrait_key])
			if portrait_texture:
				customer_portrait.texture = portrait_texture

		customer_portrait.visible = true
		customer_portrait.modulate.a = 0.0

		var tween = create_tween()
		tween.tween_property(customer_portrait, "modulate:a", 1.0, 0.5)

		await tween.finished

	if status_label:
		status_label.text = "%s (%d세) - %s" % [customer.name, customer.age, customer.summary]

	await get_tree().create_timer(1.5).timeout

	# 대화 씬으로 전환
	if main_controller:
		main_controller.change_scene("dialogue", {"customer_id": customer.id})

func _on_reputation_changed(_rep_type: String, _value: int) -> void:
	_update_ui()

func _on_customer_completed(_customer_id: String, _result: String) -> void:
	if customer_portrait:
		customer_portrait.visible = false
	customer_entered = false
	_update_ui()

# ===== 다음 날 =====

func _on_next_day_pressed() -> void:
	_play_sfx("button_click")

	# 일일 결산 화면으로 이동 또는 바로 다음 날
	if GameManager.current_day >= GameManager.MAX_DAYS:
		# 최종일 - 엔딩으로
		if main_controller:
			main_controller.change_scene("ending")
	else:
		# 일일 결산 화면이 있다면 그쪽으로
		_show_day_summary()

func _show_day_summary() -> void:
	# 일일 결산 표시 (간단 버전 - 프로토타입)
	var summary = GameManager.get_day_summary()

	if status_label:
		var earnings_text = _format_earnings(summary.get("earnings", 0))
		status_label.text = "Day %d 완료 | 수입: %s" % [summary.day, earnings_text]

	# 잠시 대기 후 다음 날로
	await get_tree().create_timer(2.0).timeout

	_go_to_next_day()

func _format_earnings(amount: int) -> String:
	if amount >= 10000000:
		return "%d,000만원" % (amount / 10000000)
	elif amount >= 10000:
		return "%d만원" % (amount / 10000)
	else:
		return "%d원" % amount

func _go_to_next_day() -> void:
	GameManager.end_day()
	GameManager.start_new_day()

	# UI 업데이트
	_update_ui()
	_setup_news_ticker()

	# 다음 날 시작 메시지
	if status_label:
		status_label.text = "Day %d - 새로운 하루가 시작됩니다..." % GameManager.current_day

	# 자동 저장
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.has_method("auto_save"):
		save_manager.auto_save()
