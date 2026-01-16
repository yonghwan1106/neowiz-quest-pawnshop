extends Control

## 기억 감정 미니게임 컨트롤러
## 난이도 스케일링 및 퍼즐 결과가 스토리에 영향

var main_controller: Node = null
var customer_id: String = ""
var customer_data: Dictionary = {}

@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var memory_orb: TextureRect = $PuzzleArea/MemoryOrb
@onready var slot_container: Control = $PuzzleArea/SlotContainer
@onready var fragment_container: Control = $PuzzleArea/FragmentContainer
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var progress_label: Label = $ProgressLabel
@onready var hint_label: Label = $HintLabel
@onready var timer_label: Label = $TimerLabel

var slots: Array[Panel] = []
var fragments: Array[Control] = []
var slot_states: Array[bool] = []
var correct_placements: int = 0
var total_slots: int = 4
var is_puzzle_complete: bool = false

var dragging_fragment: Control = null
var drag_offset: Vector2 = Vector2.ZERO

# 난이도 시스템
var puzzle_difficulty: int = 1  # 1: Easy, 2: Normal, 3: Hard
var time_limit: float = 0.0  # 0 = 무제한
var time_remaining: float = 0.0
var has_time_limit: bool = false
var decoy_fragments: int = 0
var fragment_fade_enabled: bool = false

# 퍼즐 결과
var puzzle_result: String = "perfect"  # perfect, good, rushed, failed
var start_time: float = 0.0

# 파편 색상 (기억 유형에 따라 달라짐)
var fragment_colors: Array[Color] = [
	Color(0.9, 0.7, 0.3, 0.9),
	Color(0.6, 0.8, 0.95, 0.9),
	Color(0.9, 0.5, 0.6, 0.9),
	Color(0.5, 0.9, 0.6, 0.9)
]

func _ready() -> void:
	_play_puzzle_bgm()

func set_main_controller(controller: Node) -> void:
	main_controller = controller

func setup(data: Dictionary) -> void:
	if data.has("customer_id"):
		customer_id = data.customer_id
		customer_data = GameManager.get_current_customer()
		_setup_difficulty()
		_setup_puzzle()
		_play_puzzle_bgm()

func _setup_difficulty() -> void:
	# 손님 데이터에서 난이도 가져오기
	puzzle_difficulty = customer_data.get("puzzle_difficulty", 1)

	match puzzle_difficulty:
		1:  # Easy
			total_slots = 4
			time_limit = 0.0  # 무제한
			decoy_fragments = 0
			fragment_fade_enabled = false
			if hint_label:
				hint_label.text = "파편을 올바른 슬롯에 배치하세요"
		2:  # Normal
			total_slots = 6
			time_limit = 120.0  # 2분
			decoy_fragments = 1
			fragment_fade_enabled = false
			if hint_label:
				hint_label.text = "시간 내에 파편을 배치하세요. 미끼 조각 주의!"
		3:  # Hard
			total_slots = 8
			time_limit = 90.0  # 1분 30초
			decoy_fragments = 2
			fragment_fade_enabled = true
			if hint_label:
				hint_label.text = "파편이 희미해집니다. 빠르게 배치하세요!"

	# 타이머 설정
	has_time_limit = time_limit > 0
	time_remaining = time_limit

	# 슬롯 상태 초기화
	slot_states.clear()
	for i in range(total_slots):
		slot_states.append(false)

func _play_puzzle_bgm() -> void:
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_bgm"):
		audio_manager.play_bgm("memory_puzzle")

func _play_sfx(sfx_name: String) -> void:
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(sfx_name)

func _setup_puzzle() -> void:
	# 고객 데이터에 따라 색상 설정
	if customer_data.has("memory_color"):
		var base_color = customer_data.memory_color
		fragment_colors = _generate_color_palette(base_color)
		if memory_orb:
			memory_orb.modulate = base_color.lightened(0.3)

	# 슬롯 참조 저장
	_init_slots()

	# 파편 초기화
	_init_fragments()

	# 오브 글로우 애니메이션
	_animate_orb()

	# 시작 시간 기록
	start_time = Time.get_unix_time_from_system()

	# 타이머 시작
	if has_time_limit:
		_update_timer_display()

func _generate_color_palette(base_color: Color) -> Array[Color]:
	var palette: Array[Color] = []
	var count = total_slots + decoy_fragments

	for i in range(count):
		var variation = float(i) / float(count)
		var color = base_color.lightened(0.2 - variation * 0.4)
		color.a = 0.9
		palette.append(color)

	return palette

func _init_slots() -> void:
	slots.clear()
	if not slot_container:
		return

	for i in range(total_slots):
		var slot_name = "Slot" + str(i + 1)
		var slot = slot_container.get_node_or_null(slot_name) as Panel
		if slot:
			slots.append(slot)
			slot.visible = true
		else:
			# 동적으로 슬롯 생성 (난이도에 따라)
			var new_slot = _create_slot(i)
			slot_container.add_child(new_slot)
			slots.append(new_slot)

	# 여분 슬롯 숨기기
	for i in range(total_slots, 10):
		var extra_slot = slot_container.get_node_or_null("Slot" + str(i + 1))
		if extra_slot:
			extra_slot.visible = false

func _create_slot(index: int) -> Panel:
	var slot = Panel.new()
	slot.name = "Slot" + str(index + 1)
	slot.custom_minimum_size = Vector2(80, 80)

	var label = Label.new()
	label.name = "Label"
	label.text = str(index + 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.add_child(label)

	return slot

func _init_fragments() -> void:
	fragments.clear()
	if not fragment_container:
		return

	var total_fragments = total_slots + decoy_fragments

	for i in range(total_fragments):
		var fragment_name = "Fragment" + str(i + 1)
		var fragment = fragment_container.get_node_or_null(fragment_name)

		if not fragment:
			# 동적으로 파편 생성
			fragment = _create_fragment(i)
			fragment_container.add_child(fragment)

		# 드래그 가능하도록 설정
		fragment.mouse_filter = Control.MOUSE_FILTER_STOP
		fragment.set_meta("fragment_id", i)
		fragment.set_meta("original_position", fragment.position)
		fragment.set_meta("is_decoy", i >= total_slots)

		# 색상 틴트 적용
		if i < fragment_colors.size():
			fragment.modulate = fragment_colors[i]

		# 파편 번호 레이블
		_add_fragment_label(fragment, i)

		fragment.visible = true
		fragments.append(fragment)

	# 여분 파편 숨기기
	for i in range(total_fragments, 10):
		var extra = fragment_container.get_node_or_null("Fragment" + str(i + 1))
		if extra:
			extra.visible = false

	# 파편 위치 랜덤 셔플
	_shuffle_fragment_positions()

func _create_fragment(index: int) -> Panel:
	var fragment = Panel.new()
	fragment.name = "Fragment" + str(index + 1)
	fragment.custom_minimum_size = Vector2(70, 70)
	fragment.size = Vector2(70, 70)
	fragment.position = Vector2(100 + (index % 4) * 90, 50 + (index / 4) * 90)
	return fragment

func _add_fragment_label(fragment: Control, index: int) -> void:
	# 기존 레이블 제거
	for child in fragment.get_children():
		if child is Label:
			child.queue_free()

	var label = Label.new()
	label.text = str(index + 1)

	# 미끼 조각은 특수 표시
	if index >= total_slots:
		label.text = "?"

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	fragment.add_child(label)

func _shuffle_fragment_positions() -> void:
	var positions: Array[Vector2] = []
	for fragment in fragments:
		positions.append(fragment.position)

	positions.shuffle()

	for i in range(fragments.size()):
		fragments[i].position = positions[i]
		fragments[i].set_meta("original_position", positions[i])

func _animate_orb() -> void:
	if not memory_orb:
		return
	var tween = create_tween().set_loops()
	tween.tween_property(memory_orb, "modulate:a", 0.7, 1.0)
	tween.tween_property(memory_orb, "modulate:a", 1.0, 1.0)

func _process(delta: float) -> void:
	if is_puzzle_complete:
		return

	# 타이머 업데이트
	if has_time_limit:
		time_remaining -= delta
		_update_timer_display()

		if time_remaining <= 0:
			_on_time_up()

	# 파편 페이드 효과 (Hard 난이도)
	if fragment_fade_enabled:
		_update_fragment_fade(delta)

func _update_timer_display() -> void:
	if not timer_label:
		return

	if has_time_limit:
		timer_label.visible = true
		var minutes = int(time_remaining) / 60
		var seconds = int(time_remaining) % 60
		timer_label.text = "%d:%02d" % [minutes, seconds]

		# 시간 부족 경고
		if time_remaining < 30:
			timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	else:
		timer_label.visible = false

func _update_fragment_fade(delta: float) -> void:
	for fragment in fragments:
		if fragment.visible and not fragment.get_meta("is_decoy", false):
			# 서서히 희미해짐
			fragment.modulate.a = max(0.3, fragment.modulate.a - delta * 0.05)

func _on_time_up() -> void:
	puzzle_result = "failed"
	_complete_puzzle()

func _input(event: InputEvent) -> void:
	if is_puzzle_complete:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_try_pick_fragment(event.position)
			else:
				_try_drop_fragment(event.position)

	elif event is InputEventMouseMotion:
		if dragging_fragment:
			dragging_fragment.global_position = event.position - drag_offset

func _try_pick_fragment(mouse_pos: Vector2) -> void:
	for fragment in fragments:
		if fragment.visible and _is_point_in_rect(mouse_pos, fragment.get_global_rect()):
			dragging_fragment = fragment
			drag_offset = mouse_pos - fragment.global_position
			fragment.z_index = 10

			# 드래그 시 밝기 복원 (Hard 모드)
			if fragment_fade_enabled:
				fragment.modulate.a = 0.9

			_play_sfx("button_click")
			return

func _try_drop_fragment(mouse_pos: Vector2) -> void:
	if not dragging_fragment:
		return

	var fragment_id = dragging_fragment.get_meta("fragment_id")
	var is_decoy = dragging_fragment.get_meta("is_decoy", false)
	var placed = false

	# 슬롯에 드롭 체크
	for i in range(slots.size()):
		if slot_states[i]:
			continue

		var slot = slots[i]
		var slot_rect = slot.get_global_rect()

		if _is_point_in_rect(mouse_pos, slot_rect):
			if is_decoy:
				# 미끼 조각 - 페널티
				_on_decoy_placed(dragging_fragment, i)
			else:
				# 일반 조각 배치
				_place_fragment_in_slot(dragging_fragment, i)
			placed = true
			break

	if not placed:
		# 원래 위치로 되돌리기
		var original_pos = dragging_fragment.get_meta("original_position")
		var tween = create_tween()
		tween.tween_property(dragging_fragment, "position", original_pos, 0.2)

	dragging_fragment.z_index = 0
	dragging_fragment = null

func _on_decoy_placed(fragment: Control, _slot_index: int) -> void:
	# 미끼 조각 페널티
	_play_sfx("button_click")  # 오류 효과음으로 변경 가능

	# 파편 흔들림 효과
	var original_pos = fragment.get_meta("original_position")
	var tween = create_tween()
	tween.tween_property(fragment, "position", original_pos + Vector2(10, 0), 0.05)
	tween.tween_property(fragment, "position", original_pos - Vector2(10, 0), 0.05)
	tween.tween_property(fragment, "position", original_pos, 0.05)

	# 시간 감소 페널티
	if has_time_limit:
		time_remaining -= 10.0

	# 힌트 업데이트
	if hint_label:
		hint_label.text = "미끼 조각입니다! 시간 -10초"

func _place_fragment_in_slot(fragment: Control, slot_index: int) -> void:
	var slot = slots[slot_index]
	var fragment_id = fragment.get_meta("fragment_id")

	_play_sfx("memory_fragment")

	# 파편을 슬롯 위치로 이동
	var slot_size = slot.size
	fragment.reparent(slot_container)
	fragment.position = slot.position + (slot_size - fragment.size) / 2
	fragment.visible = false

	# 슬롯 색상 변경
	var slot_style = StyleBoxFlat.new()
	if fragment_id < fragment_colors.size():
		slot_style.bg_color = fragment_colors[fragment_id]
	else:
		slot_style.bg_color = Color(0.5, 0.5, 0.5)
	slot.add_theme_stylebox_override("panel", slot_style)

	var slot_label = slot.get_node_or_null("Label")
	if slot_label:
		slot_label.text = ""

	slot_states[slot_index] = true

	# 정답 체크
	if fragment_id == slot_index:
		correct_placements += 1

	_update_progress()

func _update_progress() -> void:
	var filled_slots = slot_states.count(true)
	var progress = float(filled_slots) / float(total_slots) * 100.0

	if progress_bar:
		progress_bar.value = progress
	if progress_label:
		progress_label.text = "감정 진행도: %d%%" % int(progress)

	if filled_slots >= total_slots:
		_evaluate_result()
		_complete_puzzle()

func _evaluate_result() -> void:
	var elapsed_time = Time.get_unix_time_from_system() - start_time
	var accuracy = float(correct_placements) / float(total_slots)

	if accuracy >= 1.0:
		if has_time_limit and elapsed_time < time_limit * 0.5:
			puzzle_result = "perfect"
		else:
			puzzle_result = "perfect"
	elif accuracy >= 0.75:
		puzzle_result = "good"
	elif accuracy >= 0.5:
		puzzle_result = "rushed"
	else:
		puzzle_result = "failed"

	# 퍼즐 결과 저장 (스토리에 영향)
	_save_puzzle_result()

func _save_puzzle_result() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		save_manager.unlock_flag("puzzle_%s_%s" % [customer_id, puzzle_result])

func _complete_puzzle() -> void:
	is_puzzle_complete = true

	_play_sfx("memory_complete")

	# 결과에 따른 메시지
	match puzzle_result:
		"perfect":
			if hint_label:
				hint_label.text = "완벽한 감정! 숨겨진 기억이 드러납니다."
			if subtitle_label:
				subtitle_label.text = "기억의 모든 세부사항을 파악했습니다..."
		"good":
			if hint_label:
				hint_label.text = "좋은 감정! 기억의 대부분을 파악했습니다."
			if subtitle_label:
				subtitle_label.text = "기억의 윤곽이 보입니다..."
		"rushed":
			if hint_label:
				hint_label.text = "급한 감정. 일부 맥락을 놓쳤습니다."
			if subtitle_label:
				subtitle_label.text = "기억이 불완전하게 드러납니다..."
		"failed":
			if hint_label:
				hint_label.text = "감정 실패. 기억이 손상되었을 수 있습니다."
			if subtitle_label:
				subtitle_label.text = "기억의 파편만 간신히 읽을 수 있습니다..."

	# 오브 글로우 강화
	if memory_orb:
		var tween = create_tween()
		tween.tween_property(memory_orb, "modulate", Color(1.2, 1.0, 1.4, 1.0), 1.0)
		tween.parallel().tween_property(memory_orb, "scale", Vector2(1.2, 1.2), 1.0)

	await get_tree().create_timer(2.0).timeout

	# 대화 씬으로 돌아가기
	if main_controller:
		main_controller.change_scene("dialogue", {
			"customer_id": customer_id,
			"from_puzzle": true,
			"puzzle_result": puzzle_result
		})

func _is_point_in_rect(point: Vector2, rect: Rect2) -> bool:
	return rect.has_point(point)

func get_puzzle_result() -> String:
	return puzzle_result
