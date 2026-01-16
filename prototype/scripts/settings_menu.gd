extends Control

## 설정 메뉴 컨트롤러

signal settings_closed()

@onready var bgm_slider: HSlider = $Panel/MarginContainer/VBox/BGMContainer/BGMSlider
@onready var bgm_value_label: Label = $Panel/MarginContainer/VBox/BGMContainer/BGMValue
@onready var sfx_slider: HSlider = $Panel/MarginContainer/VBox/SFXContainer/SFXSlider
@onready var sfx_value_label: Label = $Panel/MarginContainer/VBox/SFXContainer/SFXValue
@onready var text_speed_slider: HSlider = $Panel/MarginContainer/VBox/TextSpeedContainer/TextSpeedSlider
@onready var text_speed_value: Label = $Panel/MarginContainer/VBox/TextSpeedContainer/TextSpeedValue
@onready var fullscreen_check: CheckButton = $Panel/MarginContainer/VBox/FullscreenContainer/FullscreenCheck
@onready var apply_button: Button = $Panel/MarginContainer/VBox/ButtonContainer/ApplyButton
@onready var close_button: Button = $Panel/MarginContainer/VBox/ButtonContainer/CloseButton

func _ready() -> void:
	_load_current_settings()
	_connect_signals()

func _connect_signals() -> void:
	if bgm_slider:
		bgm_slider.value_changed.connect(_on_bgm_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if text_speed_slider:
		text_speed_slider.value_changed.connect(_on_text_speed_changed)
	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _load_current_settings() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		return

	# 볼륨 설정
	if bgm_slider:
		bgm_slider.value = save_manager.get_setting("bgm_volume", 0.7) * 100
		_update_bgm_label()

	if sfx_slider:
		sfx_slider.value = save_manager.get_setting("sfx_volume", 0.8) * 100
		_update_sfx_label()

	# 텍스트 속도
	if text_speed_slider:
		text_speed_slider.value = save_manager.get_setting("text_speed", 1.0) * 100
		_update_text_speed_label()

	# 전체화면
	if fullscreen_check:
		fullscreen_check.button_pressed = save_manager.get_setting("fullscreen", false)

func _update_bgm_label() -> void:
	if bgm_value_label and bgm_slider:
		bgm_value_label.text = "%d%%" % int(bgm_slider.value)

func _update_sfx_label() -> void:
	if sfx_value_label and sfx_slider:
		sfx_value_label.text = "%d%%" % int(sfx_slider.value)

func _update_text_speed_label() -> void:
	if text_speed_value and text_speed_slider:
		var speed = text_speed_slider.value / 100.0
		var speed_text = "보통"
		if speed < 0.7:
			speed_text = "느림"
		elif speed > 1.3:
			speed_text = "빠름"
		text_speed_value.text = speed_text

func _on_bgm_changed(value: float) -> void:
	var volume = value / 100.0
	_update_bgm_label()

	# 즉시 적용
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("set_bgm_volume"):
		audio_manager.set_bgm_volume(volume)

	# 저장
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		save_manager.set_setting("bgm_volume", volume)

func _on_sfx_changed(value: float) -> void:
	var volume = value / 100.0
	_update_sfx_label()

	# 즉시 적용
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("set_sfx_volume"):
		audio_manager.set_sfx_volume(volume)

	# 테스트 효과음
	if audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx("button_click")

	# 저장
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		save_manager.set_setting("sfx_volume", volume)

func _on_text_speed_changed(value: float) -> void:
	var speed = value / 100.0
	_update_text_speed_label()

	# 저장
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		save_manager.set_setting("text_speed", speed)

func _on_fullscreen_toggled(pressed: bool) -> void:
	# 즉시 적용
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# 저장
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		save_manager.set_setting("fullscreen", pressed)

func _on_apply_pressed() -> void:
	_play_sfx("button_click")

	# 모든 설정 저장 확인
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.has_method("save_settings"):
		save_manager.save_settings()

	# 적용 완료 피드백 (버튼 텍스트 임시 변경)
	if apply_button:
		apply_button.text = "적용됨!"
		apply_button.disabled = true
		await get_tree().create_timer(1.0).timeout
		apply_button.text = "적용"
		apply_button.disabled = false

func _on_close_pressed() -> void:
	_play_sfx("button_click")
	emit_signal("settings_closed")
	queue_free()

func _play_sfx(sfx_name: String) -> void:
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(sfx_name)

func _input(event: InputEvent) -> void:
	# ESC로 닫기
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
