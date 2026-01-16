extends Control

## 엔딩 화면 컨트롤러

var main_controller: Node = null

@onready var ending_title: Label = $VBoxContainer/EndingTitle
@onready var ending_subtitle: Label = $VBoxContainer/EndingSubtitle
@onready var customer_summary: RichTextLabel = $VBoxContainer/SummaryPanel/MarginContainer/VBox/CustomerSummary
@onready var mercy_value: Label = $VBoxContainer/ReputationSummary/MercyBox/Value
@onready var justice_value: Label = $VBoxContainer/ReputationSummary/JusticeBox/Value
@onready var profit_value: Label = $VBoxContainer/ReputationSummary/ProfitBox/Value
@onready var restart_button: Button = $VBoxContainer/ButtonContainer/RestartButton
@onready var quit_button: Button = $VBoxContainer/ButtonContainer/QuitButton

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	_setup_ending()

func set_main_controller(controller: Node) -> void:
	main_controller = controller

func setup(_data: Dictionary) -> void:
	_setup_ending()

func _setup_ending() -> void:
	# 평판 표시
	mercy_value.text = str(GameManager.reputation.mercy)
	justice_value.text = str(GameManager.reputation.justice)
	profit_value.text = str(GameManager.reputation.profit)

	# 손님 결과 요약 생성
	var summary_text = ""
	for customer_id in GameManager.customer_results:
		var result = GameManager.customer_results[customer_id]
		var customer_name = _get_customer_name(customer_id)
		var result_text = _get_result_text(customer_id, result)
		summary_text += "[color=#a855f7]%s[/color]: %s\n" % [customer_name, result_text]

	if summary_text.is_empty():
		summary_text = "아직 만난 손님이 없습니다."

	customer_summary.text = summary_text

	# 엔딩 타입에 따른 메시지
	var ending_type = GameManager.get_ending_type()
	_set_ending_message(ending_type)

func _get_customer_name(customer_id: String) -> String:
	match customer_id:
		"minji":
			return "민지"
		"park_elder":
			return "박 노인"
		"jung_seokhyun":
			return "정석현"
		_:
			return "손님"

func _get_result_text(customer_id: String, result: String) -> String:
	match result:
		"accept":
			return "기억을 매입했습니다"
		"reject":
			return "거래를 거절했습니다"
		"modify":
			return "기억을 수정했습니다"
		_:
			return "알 수 없음"

func _set_ending_message(ending_type: String) -> void:
	match ending_type:
		"mercy":
			ending_title.text = "자비로운 전당포지기"
			ending_subtitle.text = "당신은 손님들의 아픔을 이해하려 했습니다"
			ending_title.modulate = Color(0.4, 0.8, 0.9, 1)
		"justice":
			ending_title.text = "정의로운 전당포지기"
			ending_subtitle.text = "당신은 옳고 그름의 경계를 지켰습니다"
			ending_title.modulate = Color(0.9, 0.7, 0.4, 1)
		"profit":
			ending_title.text = "냉철한 전당포지기"
			ending_subtitle.text = "당신은 거래의 본질을 잊지 않았습니다"
			ending_title.modulate = Color(0.5, 0.9, 0.5, 1)

func _on_restart_pressed() -> void:
	GameManager.reset_game()
	if main_controller:
		main_controller.change_scene("title")

func _on_quit_pressed() -> void:
	get_tree().quit()
