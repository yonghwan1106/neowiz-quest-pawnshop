extends Node

## 대화 시스템을 관리하는 오토로드 싱글톤
## JSON 기반 대화 로딩 및 분기 시스템 지원

signal dialogue_started(customer_id: String)
signal dialogue_line_displayed(speaker: String, text: String)
signal dialogue_choice_requested(choices: Array)
signal dialogue_ended(customer_id: String)
signal branch_selected(branch_id: String)

var current_dialogue: Dictionary = {}
var current_line_index: int = 0
var current_customer_id: String = ""
var is_dialogue_active: bool = false

# 대화 데이터 저장 (JSON에서 로드)
var dialogues: Dictionary = {}

# 대화 중 신뢰도 및 발견 플래그
var customer_trust: int = 0  # -10 ~ 10
var discovered_flags: Array = []

# JSON 파일 경로 매핑
const DIALOGUE_PATH: String = "res://resources/dialogues/"

func _ready() -> void:
	_load_all_dialogues()

func _load_all_dialogues() -> void:
	# dialogues 디렉토리의 모든 JSON 파일 로드
	var dir = DirAccess.open(DIALOGUE_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var customer_id = file_name.replace(".json", "")
				var dialogue_data = _load_dialogue_json(DIALOGUE_PATH + file_name)
				if dialogue_data:
					dialogues[customer_id] = dialogue_data
			file_name = dir.get_next()
		dir.list_dir_end()

	# 디버그: 로드된 대화 수 출력
	print("[DialogueManager] Loaded %d dialogues" % dialogues.size())

func _load_dialogue_json(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_error("Dialogue file not found: " + file_path)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open dialogue file: " + file_path)
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("JSON parse error in %s at line %d: %s" % [file_path, json.get_error_line(), json.get_error_message()])
		return {}

	return json.data

func reload_dialogues() -> void:
	dialogues.clear()
	_load_all_dialogues()

func get_dialogue_data(customer_id: String) -> Dictionary:
	return dialogues.get(customer_id, {})

func get_customer_metadata(customer_id: String) -> Dictionary:
	var dialogue_data = get_dialogue_data(customer_id)
	return dialogue_data.get("metadata", {})

func start_dialogue(customer_id: String) -> void:
	if not dialogues.has(customer_id):
		push_error("Dialogue not found for customer: " + customer_id)
		return

	current_customer_id = customer_id
	current_dialogue = dialogues[customer_id].get("dialogue", {})
	current_line_index = 0
	is_dialogue_active = true
	customer_trust = 0
	discovered_flags.clear()
	emit_signal("dialogue_started", customer_id)

func get_intro_lines() -> Array:
	return current_dialogue.get("intro", [])

func get_after_puzzle_lines() -> Array:
	return current_dialogue.get("after_puzzle", [])

func get_choices() -> Array:
	var choices = current_dialogue.get("choices", [])
	# 신뢰도에 따라 선택지 필터링 가능
	return _filter_choices_by_trust(choices)

func _filter_choices_by_trust(choices: Array) -> Array:
	var filtered = []
	for choice in choices:
		var trust_required = choice.get("trust_required", -999)
		if customer_trust >= trust_required:
			filtered.append(choice)
	return filtered

func get_ending_lines(result: String) -> Array:
	var endings = current_dialogue.get("endings", {})
	return endings.get(result, [])

func get_branch_lines(branch_id: String) -> Array:
	var branches = current_dialogue.get("branches", {})
	return branches.get(branch_id, [])

func get_reputation_effects(customer_id: String, result: String) -> Dictionary:
	var dialogue_data = get_dialogue_data(customer_id)
	var effects = dialogue_data.get("reputation_effects", {})
	return effects.get(result, {})

func get_consequences(customer_id: String, result: String) -> Dictionary:
	var dialogue_data = get_dialogue_data(customer_id)
	var consequences = dialogue_data.get("consequences", {})
	return consequences.get(result, {})

func modify_trust(amount: int) -> void:
	customer_trust = clampi(customer_trust + amount, -10, 10)

func add_discovered_flag(flag: String) -> void:
	if not discovered_flags.has(flag):
		discovered_flags.append(flag)

func has_discovered_flag(flag: String) -> bool:
	return discovered_flags.has(flag)

func get_current_trust() -> int:
	return customer_trust

func end_dialogue() -> void:
	emit_signal("dialogue_ended", current_customer_id)
	current_customer_id = ""
	current_dialogue = {}
	current_line_index = 0
	is_dialogue_active = false
	customer_trust = 0
	discovered_flags.clear()

# 대화 데이터에서 감정 정보 추출
func get_line_emotion(line: Dictionary) -> String:
	return line.get("emotion", "neutral")

# 분기점 체크
func is_branch_point(line: Dictionary) -> bool:
	return line.get("branch_point", false)

func get_branch_options(line: Dictionary) -> Array:
	return line.get("options", [])

# 모든 고객 ID 반환
func get_all_customer_ids() -> Array:
	return dialogues.keys()

# 특정 날짜에 등장할 고객 목록 반환
func get_customers_for_day(day: int) -> Array:
	var result = []
	for customer_id in dialogues:
		var metadata = get_customer_metadata(customer_id)
		if metadata.get("day", 1) == day:
			result.append(customer_id)
	return result
