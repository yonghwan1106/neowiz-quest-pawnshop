extends Control

## 전당포 메인 화면 컨트롤러

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

# 캐릭터 포트레잇 경로 매핑
const PORTRAIT_PATHS: Dictionary = {
	"minji": "res://assets/portraits/portrait_minji.png",
	"park_elder": "res://assets/portraits/portrait_park_elder.png",
	"jung": "res://assets/portraits/portrait_jung.png"
}

var customer_entered: bool = false

func _ready() -> void:
	wait_button.pressed.connect(_on_wait_button_pressed)
	next_day_button.pressed.connect(_on_next_day_pressed)

	GameManager.reputation_changed.connect(_on_reputation_changed)
	GameManager.customer_completed.connect(_on_customer_completed)

	_update_ui()
	_animate_neon_sign()

func set_main_controller(controller: Node) -> void:
	main_controller = controller

func setup(_data: Dictionary) -> void:
	_update_ui()

func _update_ui() -> void:
	day_label.text = "Day %d" % GameManager.current_day

	mercy_bar.value = GameManager.reputation.mercy
	justice_bar.value = GameManager.reputation.justice
	profit_bar.value = GameManager.reputation.profit

	if GameManager.has_more_customers():
		wait_button.visible = true
		next_day_button.visible = false
		status_label.text = "전당포 문을 열었습니다. 손님을 기다리는 중..."
	else:
		wait_button.visible = false
		next_day_button.visible = true
		status_label.text = "오늘의 손님을 모두 만났습니다."

func _animate_neon_sign() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(neon_sign, "modulate:a", 0.7, 0.5)
	tween.tween_property(neon_sign, "modulate:a", 1.0, 0.5)

func _on_wait_button_pressed() -> void:
	if not GameManager.has_more_customers():
		return

	wait_button.disabled = true
	status_label.text = "누군가 문을 두드립니다..."

	# 손님 등장 애니메이션
	await get_tree().create_timer(1.0).timeout

	var customer = GameManager.get_current_customer()
	_show_customer(customer)

func _show_customer(customer: Dictionary) -> void:
	# 캐릭터 포트레잇 로드
	var portrait_key = customer.get("portrait_key", customer.id)
	if PORTRAIT_PATHS.has(portrait_key):
		var portrait_texture = load(PORTRAIT_PATHS[portrait_key])
		if portrait_texture:
			customer_portrait.texture = portrait_texture

	customer_portrait.visible = true
	customer_portrait.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(customer_portrait, "modulate:a", 1.0, 0.5)

	await tween.finished

	status_label.text = "%s (%d세) - %s" % [customer.name, customer.age, customer.summary]

	await get_tree().create_timer(1.5).timeout

	# 대화 씬으로 전환
	if main_controller:
		main_controller.change_scene("dialogue", {"customer_id": customer.id})

func _on_reputation_changed(_rep_type: String, _value: int) -> void:
	_update_ui()

func _on_customer_completed(_customer_id: String, _result: String) -> void:
	customer_portrait.visible = false
	customer_entered = false
	_update_ui()

func _on_next_day_pressed() -> void:
	if main_controller:
		main_controller.change_scene("ending")
