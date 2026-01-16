extends Control

## 타이틀 화면 컨트롤러
## 새 게임, 계속하기, 설정 기능 지원

var main_controller: Node = null
var settings_menu_scene: PackedScene = null

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/Title
@onready var save_info_label: Label = $VBoxContainer/SaveInfoLabel

# 설정 메뉴 씬 경로
const SETTINGS_MENU_PATH = "res://scenes/settings_menu.tscn"

func _ready() -> void:
	_connect_buttons()
	_update_continue_button()
	_play_entrance_animation()
	_play_title_bgm()

func _connect_buttons() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		start_button.mouse_entered.connect(_on_button_hover.bind(start_button))

	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		continue_button.mouse_entered.connect(_on_button_hover.bind(continue_button))

	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
		settings_button.mouse_entered.connect(_on_button_hover.bind(settings_button))

	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		quit_button.mouse_entered.connect(_on_button_hover.bind(quit_button))

func _update_continue_button() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		if continue_button:
			continue_button.visible = false
		if save_info_label:
			save_info_label.visible = false
		return

	var has_save = save_manager.has_save_file()

	if continue_button:
		continue_button.visible = has_save
		continue_button.disabled = not has_save

	if save_info_label:
		if has_save:
			var save_info = save_manager.get_save_info()
			save_info_label.text = "Day %d | %s | 손님 %d명" % [
				save_info.get("day", 1),
				save_info.get("playtime", "0분"),
				save_info.get("customers_completed", 0)
			]
			save_info_label.visible = true
		else:
			save_info_label.visible = false

func _play_entrance_animation() -> void:
	# 타이틀 페이드 인 애니메이션
	if title_label:
		title_label.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(title_label, "modulate:a", 1.0, 1.0)

	# 버튼들 순차적으로 페이드 인
	var buttons = [start_button, continue_button, settings_button, quit_button]
	var delay = 0.3
	for button in buttons:
		if button and button.visible:
			button.modulate.a = 0.0
			var btn_tween = create_tween()
			btn_tween.tween_property(button, "modulate:a", 1.0, 0.5).set_delay(delay)
			delay += 0.15

func set_main_controller(controller: Node) -> void:
	main_controller = controller

func setup(_data: Dictionary) -> void:
	# 게임 상태 초기화
	GameManager.reset_game()
	_update_continue_button()
	_play_title_bgm()

func _play_title_bgm() -> void:
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_bgm"):
		audio_manager.play_bgm("title")

func _play_sfx(sfx_name: String) -> void:
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(sfx_name)

func _on_button_hover(button: Button) -> void:
	if button.disabled:
		return
	var hover_tween = create_tween()
	hover_tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	hover_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	_play_sfx("button_hover")

func _on_start_pressed() -> void:
	_play_sfx("button_click")

	# 저장 파일 삭제 확인 (기존 저장이 있을 경우)
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.has_save_file():
		# 새 게임 시작 시 기존 저장 덮어쓰기 경고
		# 프로토타입에서는 바로 시작
		save_manager.delete_save()

	_start_new_game()

func _start_new_game() -> void:
	GameManager.reset_game()
	GameManager.game_started = true
	GameManager.start_day()

	if main_controller:
		main_controller.change_scene("pawnshop")

func _on_continue_pressed() -> void:
	_play_sfx("button_click")

	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.load_game():
		GameManager.game_started = true
		GameManager.start_day()

		if main_controller:
			main_controller.change_scene("pawnshop")
	else:
		# 불러오기 실패
		if save_info_label:
			save_info_label.text = "저장 파일을 불러올 수 없습니다."

func _on_settings_pressed() -> void:
	_play_sfx("button_click")
	_show_settings_menu()

func _show_settings_menu() -> void:
	# 설정 메뉴 씬 로드
	if not settings_menu_scene:
		if ResourceLoader.exists(SETTINGS_MENU_PATH):
			settings_menu_scene = load(SETTINGS_MENU_PATH)

	if settings_menu_scene:
		var settings_instance = settings_menu_scene.instantiate()
		settings_instance.settings_closed.connect(_on_settings_closed.bind(settings_instance))
		add_child(settings_instance)
	else:
		# 씬이 없으면 간단한 메시지
		print("[TitleScreen] Settings menu scene not found")

func _on_settings_closed(_instance: Node) -> void:
	# 설정 메뉴가 자체적으로 queue_free()를 호출함
	pass

func _on_quit_pressed() -> void:
	_play_sfx("button_click")
	get_tree().quit()

func _input(event: InputEvent) -> void:
	# 아무 키나 누르면 새 게임 시작 (로고 화면 같은 느낌)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_quit_pressed()
