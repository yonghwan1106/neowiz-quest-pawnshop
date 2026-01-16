extends Node

## 저장/불러오기 시스템을 관리하는 오토로드 싱글톤

signal save_completed(success: bool)
signal load_completed(success: bool)
signal settings_changed()

const SAVE_FILE_PATH: String = "user://memory_pawnshop_save.json"
const SETTINGS_FILE_PATH: String = "user://memory_pawnshop_settings.json"
const SAVE_VERSION: String = "1.0"

# 기본 저장 데이터 구조
var save_data: Dictionary = {
	"version": SAVE_VERSION,
	"current_day": 1,
	"reputation": {"mercy": 50, "justice": 50, "profit": 50},
	"completed_customers": [],
	"customer_results": {},
	"unlocked_flags": [],
	"news_history": [],
	"protagonist_memories": [],
	"total_earnings": 0,
	"playtime_seconds": 0
}

# 설정 데이터
var settings: Dictionary = {
	"bgm_volume": 0.7,
	"sfx_volume": 0.8,
	"text_speed": 1.0,
	"fullscreen": false,
	"language": "ko",
	"auto_save": true
}

# 플레이 시간 추적
var _session_start_time: float = 0.0

func _ready() -> void:
	_session_start_time = Time.get_unix_time_from_system()
	load_settings()

func _process(_delta: float) -> void:
	# 매 프레임 플레이타임 업데이트 (무거우면 타이머로 변경)
	pass

# ===== 저장 함수 =====

func save_game() -> bool:
	# GameManager에서 현재 상태 수집
	_collect_game_state()

	# 플레이타임 업데이트
	var current_time = Time.get_unix_time_from_system()
	save_data.playtime_seconds += int(current_time - _session_start_time)
	_session_start_time = current_time

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Failed to open save file for writing")
		emit_signal("save_completed", false)
		return false

	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	print("[SaveManager] Game saved successfully")
	emit_signal("save_completed", true)
	return true

func _collect_game_state() -> void:
	save_data.version = SAVE_VERSION
	save_data.current_day = GameManager.current_day
	save_data.reputation = GameManager.reputation.duplicate()
	save_data.completed_customers = GameManager.completed_customers.duplicate()
	save_data.customer_results = GameManager.customer_results.duplicate()

# ===== 불러오기 함수 =====

func load_game() -> bool:
	if not has_save_file():
		print("[SaveManager] No save file found")
		emit_signal("load_completed", false)
		return false

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open save file for reading")
		emit_signal("load_completed", false)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Failed to parse save file: " + json.get_error_message())
		emit_signal("load_completed", false)
		return false

	save_data = json.data

	# 버전 호환성 체크 및 마이그레이션
	_migrate_save_data()

	# GameManager에 상태 적용
	_apply_game_state()

	# 세션 시작 시간 리셋
	_session_start_time = Time.get_unix_time_from_system()

	print("[SaveManager] Game loaded successfully")
	emit_signal("load_completed", true)
	return true

func _migrate_save_data() -> void:
	# 버전별 마이그레이션 로직
	var version = save_data.get("version", "0.0")

	# 누락된 필드 기본값 설정
	if not save_data.has("unlocked_flags"):
		save_data.unlocked_flags = []
	if not save_data.has("news_history"):
		save_data.news_history = []
	if not save_data.has("protagonist_memories"):
		save_data.protagonist_memories = []
	if not save_data.has("total_earnings"):
		save_data.total_earnings = 0
	if not save_data.has("playtime_seconds"):
		save_data.playtime_seconds = 0

func _apply_game_state() -> void:
	GameManager.current_day = save_data.get("current_day", 1)
	GameManager.reputation = save_data.get("reputation", {"mercy": 50, "justice": 50, "profit": 50})
	GameManager.completed_customers = save_data.get("completed_customers", [])
	GameManager.customer_results = save_data.get("customer_results", {})

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func delete_save() -> void:
	if has_save_file():
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("[SaveManager] Save file deleted")

func get_save_info() -> Dictionary:
	if not has_save_file():
		return {}

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}

	var data = json.data
	return {
		"day": data.get("current_day", 1),
		"playtime": _format_playtime(data.get("playtime_seconds", 0)),
		"customers_completed": data.get("completed_customers", []).size()
	}

func _format_playtime(seconds: int) -> String:
	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	if hours > 0:
		return "%d시간 %d분" % [hours, minutes]
	else:
		return "%d분" % minutes

# ===== 설정 함수 =====

func save_settings() -> bool:
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Failed to save settings")
		return false

	var json_string = JSON.stringify(settings, "\t")
	file.store_string(json_string)
	file.close()

	print("[SaveManager] Settings saved")
	return true

func load_settings() -> bool:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		# 기본 설정 사용
		return false

	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if not file:
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return false

	# 로드된 설정과 기본 설정 병합 (새 설정 키 추가 대응)
	var loaded = json.data
	for key in loaded:
		settings[key] = loaded[key]

	_apply_settings()
	print("[SaveManager] Settings loaded")
	return true

func _apply_settings() -> void:
	# 오디오 설정 적용
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		if audio_manager.has_method("set_bgm_volume"):
			audio_manager.set_bgm_volume(settings.bgm_volume)
		if audio_manager.has_method("set_sfx_volume"):
			audio_manager.set_sfx_volume(settings.sfx_volume)

	# 전체화면 설정
	if settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	emit_signal("settings_changed")

func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	_apply_settings()

	# 자동 저장
	if settings.get("auto_save", true):
		save_settings()

func get_setting(key: String, default_value: Variant = null) -> Variant:
	return settings.get(key, default_value)

# ===== 플래그 관리 =====

func unlock_flag(flag: String) -> void:
	if not save_data.unlocked_flags.has(flag):
		save_data.unlocked_flags.append(flag)

func has_flag(flag: String) -> bool:
	return save_data.unlocked_flags.has(flag)

# ===== 뉴스 히스토리 =====

func add_news(day: int, text: String) -> void:
	save_data.news_history.append({"day": day, "text": text})

func get_news_for_day(day: int) -> Array:
	var result = []
	for news in save_data.news_history:
		if news.day == day:
			result.append(news.text)
	return result

# ===== 주인공 기억 =====

func add_protagonist_memory(memory: String) -> void:
	if not save_data.protagonist_memories.has(memory):
		save_data.protagonist_memories.append(memory)

func get_protagonist_memories() -> Array:
	return save_data.protagonist_memories

# ===== 자동 저장 =====

func auto_save() -> void:
	if settings.get("auto_save", true):
		save_game()
