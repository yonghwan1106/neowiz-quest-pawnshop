extends Control

## 대화 시스템 컨트롤러

var main_controller: Node = null
var customer_id: String = ""
var current_lines: Array = []
var current_line_index: int = 0
var dialogue_phase: String = "intro"  # intro, after_puzzle, choices, ending
var selected_result: String = ""
var is_typing: bool = false
var typing_speed: float = 0.03

@onready var speaker_label: Label = $DialogueBox/MarginContainer/VBox/SpeakerLabel
@onready var dialogue_label: RichTextLabel = $DialogueBox/MarginContainer/VBox/DialogueLabel
@onready var continue_hint: Label = $DialogueBox/MarginContainer/VBox/ContinueHint
@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var choice_container: VBoxContainer = $ChoiceContainer
@onready var choice1_button: Button = $ChoiceContainer/Choice1
@onready var choice2_button: Button = $ChoiceContainer/Choice2
@onready var choice3_button: Button = $ChoiceContainer/Choice3
@onready var customer_portrait: TextureRect = $CharacterArea/CustomerPortrait
@onready var customer_name_label: Label = $CharacterArea/CustomerPortrait/NameLabel
@onready var protagonist_portrait: TextureRect = $CharacterArea/ProtagonistPortrait

# 캐릭터 포트레잇 경로 매핑
const PORTRAIT_PATHS: Dictionary = {
	"minji": "res://assets/portraits/portrait_minji.png",
	"park_elder": "res://assets/portraits/portrait_park_elder.png",
	"jung": "res://assets/portraits/portrait_jung.png",
	"jinwoo": "res://assets/portraits/portrait_jinwoo.png"
}

func _ready() -> void:
	choice1_button.pressed.connect(_on_choice_pressed.bind(0))
	choice2_button.pressed.connect(_on_choice_pressed.bind(1))
	choice3_button.pressed.connect(_on_choice_pressed.bind(2))

func set_main_controller(controller: Node) -> void:
	main_controller = controller

func setup(data: Dictionary) -> void:
	if data.has("customer_id"):
		customer_id = data.customer_id
		_setup_customer()

		# 퍼즐에서 돌아온 경우
		if data.get("from_puzzle", false):
			DialogueManager.start_dialogue(customer_id)
			resume_after_puzzle()
		else:
			_start_dialogue()

func _setup_customer() -> void:
	var customer = GameManager.get_current_customer()
	if customer.is_empty():
		return

	customer_name_label.text = customer.name

	# 캐릭터 포트레잇 로드
	var portrait_key = customer.get("portrait_key", customer_id)
	if PORTRAIT_PATHS.has(portrait_key):
		var portrait_texture = load(PORTRAIT_PATHS[portrait_key])
		if portrait_texture:
			customer_portrait.texture = portrait_texture
			customer_portrait.visible = true

func _start_dialogue() -> void:
	DialogueManager.start_dialogue(customer_id)
	dialogue_phase = "intro"
	current_lines = DialogueManager.get_intro_lines()
	current_line_index = 0
	_show_current_line()

func _show_current_line() -> void:
	if current_line_index >= current_lines.size():
		_on_phase_complete()
		return

	var line = current_lines[current_line_index]
	speaker_label.text = line.speaker
	dialogue_label.text = ""
	continue_hint.visible = false

	# 화자에 따라 포트레잇 하이라이트
	_highlight_speaker(line.speaker)

	# 타이핑 효과
	is_typing = true
	await _type_text(line.text)
	is_typing = false
	continue_hint.visible = true

func _type_text(text: String) -> void:
	dialogue_label.text = ""
	for i in range(text.length()):
		if not is_typing:
			dialogue_label.text = text
			return
		dialogue_label.text += text[i]
		await get_tree().create_timer(typing_speed).timeout

func _highlight_speaker(speaker: String) -> void:
	if speaker == "진우":
		protagonist_portrait.modulate = Color(1, 1, 1, 1)
		customer_portrait.modulate = Color(0.5, 0.5, 0.5, 1)
	elif speaker == "내레이션":
		protagonist_portrait.modulate = Color(0.5, 0.5, 0.5, 1)
		customer_portrait.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		protagonist_portrait.modulate = Color(0.5, 0.5, 0.5, 1)
		customer_portrait.modulate = Color(1, 1, 1, 1)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if is_typing:
			is_typing = false
		elif continue_hint.visible:
			_advance_dialogue()

func _advance_dialogue() -> void:
	current_line_index += 1
	_show_current_line()

func _on_phase_complete() -> void:
	match dialogue_phase:
		"intro":
			# 퍼즐로 이동
			if main_controller:
				main_controller.change_scene("puzzle", {"customer_id": customer_id})
		"after_puzzle":
			# 선택지 표시
			_show_choices()
		"ending":
			# 전당포로 복귀
			GameManager.complete_customer(selected_result)
			DialogueManager.end_dialogue()
			if main_controller:
				main_controller.change_scene("pawnshop")

func _show_choices() -> void:
	dialogue_phase = "choices"
	dialogue_box.visible = false
	choice_container.visible = true

	var choices = DialogueManager.get_choices()
	if choices.size() >= 3:
		choice1_button.text = choices[0].text
		choice2_button.text = choices[1].text
		choice3_button.text = choices[2].text

func _on_choice_pressed(choice_index: int) -> void:
	var choices = DialogueManager.get_choices()
	if choice_index < choices.size():
		selected_result = choices[choice_index].result

	choice_container.visible = false
	dialogue_box.visible = true

	# 엔딩 대화 시작
	dialogue_phase = "ending"
	current_lines = DialogueManager.get_ending_lines(selected_result)
	current_line_index = 0
	_show_current_line()

# 퍼즐 완료 후 호출됨
func resume_after_puzzle() -> void:
	dialogue_phase = "after_puzzle"
	current_lines = DialogueManager.get_after_puzzle_lines()
	current_line_index = 0
	_show_current_line()
