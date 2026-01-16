extends Control

## 기억 감정 미니게임 컨트롤러
## 파편을 드래그하여 올바른 슬롯에 배치하는 퍼즐

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

var slots: Array[Panel] = []
var fragments: Array[Control] = []
var slot_states: Array[bool] = [false, false, false, false]  # 각 슬롯이 채워졌는지
var correct_placements: int = 0
var total_slots: int = 4
var is_puzzle_complete: bool = false

var dragging_fragment: Control = null
var drag_offset: Vector2 = Vector2.ZERO

# 파편 색상 (기억 유형에 따라 달라짐)
var fragment_colors: Array[Color] = [
	Color(0.9, 0.7, 0.3, 0.9),   # 황금빛
	Color(0.6, 0.8, 0.95, 0.9),  # 하늘빛
	Color(0.9, 0.5, 0.6, 0.9),   # 분홍빛
	Color(0.5, 0.9, 0.6, 0.9)    # 녹색빛
]

func _ready() -> void:
	# 슬롯 참조 저장
	for i in range(4):
		var slot = slot_container.get_node("Slot" + str(i + 1)) as Panel
		if slot:
			slots.append(slot)

func set_main_controller(controller: Node) -> void:
	main_controller = controller

func setup(data: Dictionary) -> void:
	if data.has("customer_id"):
		customer_id = data.customer_id
		customer_data = GameManager.get_current_customer()
		_setup_puzzle()

func _setup_puzzle() -> void:
	# 고객 데이터에 따라 색상 설정
	if customer_data.has("memory_color"):
		var base_color = customer_data.memory_color
		fragment_colors = [
			base_color.lightened(0.2),
			base_color,
			base_color.darkened(0.1),
			base_color.darkened(0.2)
		]
		memory_orb.modulate = base_color.lightened(0.3)

	# 파편 초기화 (씬에 있는 기존 파편 사용)
	_init_fragments()

	# 오브 글로우 애니메이션
	_animate_orb()

func _init_fragments() -> void:
	# 씬에 있는 기존 파편들 초기화
	fragments.clear()

	for i in range(4):
		var fragment_name = "Fragment" + str(i + 1)
		var fragment = fragment_container.get_node_or_null(fragment_name)
		if fragment:
			# 드래그 가능하도록 설정
			fragment.mouse_filter = Control.MOUSE_FILTER_STOP
			fragment.set_meta("fragment_id", i)
			fragment.set_meta("original_position", fragment.position)

			# 색상 틴트 적용
			fragment.modulate = fragment_colors[i]

			fragments.append(fragment)

func _animate_orb() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(memory_orb, "modulate:a", 0.7, 1.0)
	tween.tween_property(memory_orb, "modulate:a", 1.0, 1.0)

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
			return

func _try_drop_fragment(mouse_pos: Vector2) -> void:
	if not dragging_fragment:
		return

	var fragment_id = dragging_fragment.get_meta("fragment_id")
	var placed = false

	# 슬롯에 드롭 체크
	for i in range(slots.size()):
		if slot_states[i]:
			continue  # 이미 채워진 슬롯

		var slot = slots[i]
		var slot_rect = slot.get_global_rect()

		if _is_point_in_rect(mouse_pos, slot_rect):
			# 슬롯에 배치
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

func _place_fragment_in_slot(fragment: Control, slot_index: int) -> void:
	var slot = slots[slot_index]
	var fragment_id = fragment.get_meta("fragment_id")

	# 파편을 슬롯 위치로 이동
	var slot_size = slot.size

	fragment.reparent(slot_container)
	fragment.position = slot.position + (slot_size - fragment.size) / 2
	fragment.visible = false  # 숨기고

	# 슬롯 색상 변경
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = fragment_colors[fragment_id]
	slot.add_theme_stylebox_override("panel", slot_style)
	slot.get_node("Label").text = ""

	slot_states[slot_index] = true

	# 정답 체크 (간단히: 같은 번호가 같은 슬롯에)
	if fragment_id == slot_index:
		correct_placements += 1

	_update_progress()

func _update_progress() -> void:
	var filled_slots = slot_states.count(true)
	var progress = float(filled_slots) / float(total_slots) * 100.0

	progress_bar.value = progress
	progress_label.text = "감정 진행도: %d%%" % int(progress)

	if filled_slots >= total_slots:
		_complete_puzzle()

func _complete_puzzle() -> void:
	is_puzzle_complete = true

	# 완료 애니메이션
	hint_label.text = "기억 감정 완료!"
	subtitle_label.text = "기억의 내용이 드러납니다..."

	# 오브 글로우 강화
	var tween = create_tween()
	tween.tween_property(memory_orb, "modulate", Color(1.2, 1.0, 1.4, 1.0), 1.0)
	tween.parallel().tween_property(memory_orb, "scale", Vector2(1.2, 1.2), 1.0)

	await get_tree().create_timer(2.0).timeout

	# 대화 씬으로 돌아가기
	if main_controller:
		main_controller.change_scene("dialogue", {
			"customer_id": customer_id,
			"from_puzzle": true
		})

func _is_point_in_rect(point: Vector2, rect: Rect2) -> bool:
	return rect.has_point(point)
