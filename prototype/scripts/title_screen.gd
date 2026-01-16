extends Control

## 타이틀 화면 컨트롤러

var main_controller: Node = null

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/Title

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 타이틀 페이드 인 애니메이션
	title_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)

func set_main_controller(controller: Node) -> void:
	main_controller = controller

func setup(_data: Dictionary) -> void:
	# 게임 상태 초기화
	GameManager.reset_game()

func _on_start_pressed() -> void:
	if main_controller:
		GameManager.game_started = true
		main_controller.change_scene("pawnshop")

func _on_quit_pressed() -> void:
	get_tree().quit()
