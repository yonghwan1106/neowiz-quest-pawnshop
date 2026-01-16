extends Node

## 기억의 전당포 - 통합 테스트 러너
## Godot 에디터에서 실행: 이 스크립트를 씬에 연결하고 실행

class_name TestRunner

signal all_tests_completed(results: Dictionary)

var test_results: Dictionary = {
	"passed": 0,
	"failed": 0,
	"errors": [],
	"details": []
}

func _ready() -> void:
	print("========================================")
	print("기억의 전당포 - 통합 테스트 시작")
	print("========================================\n")

	await run_all_tests()

	print("\n========================================")
	print("테스트 결과 요약")
	print("========================================")
	print("통과: %d" % test_results.passed)
	print("실패: %d" % test_results.failed)
	print("성공률: %.1f%%" % (100.0 * test_results.passed / max(1, test_results.passed + test_results.failed)))

	if test_results.errors.size() > 0:
		print("\n실패한 테스트:")
		for error in test_results.errors:
			print("  - %s" % error)

	emit_signal("all_tests_completed", test_results)

func run_all_tests() -> void:
	# 1. GameManager 테스트
	await test_game_manager()

	# 2. SaveManager 테스트
	await test_save_manager()

	# 3. DialogueManager 테스트
	await test_dialogue_manager()

	# 4. 리소스 로드 테스트
	await test_resource_loading()

	# 5. 씬 전환 테스트
	await test_scene_existence()

# ===== GameManager 테스트 =====

func test_game_manager() -> void:
	print("[테스트] GameManager...")

	# GameManager 존재 확인
	var gm = get_node_or_null("/root/GameManager")
	assert_not_null(gm, "GameManager Autoload 존재")

	if not gm:
		return

	# 초기화 테스트
	gm.reset_game()
	assert_equals(gm.current_day, 1, "reset_game 후 current_day = 1")
	assert_equals(gm.reputation.mercy, 50, "reset_game 후 mercy = 50")
	assert_equals(gm.reputation.justice, 50, "reset_game 후 justice = 50")
	assert_equals(gm.reputation.profit, 50, "reset_game 후 profit = 50")

	# 평판 변경 테스트
	gm.change_reputation("mercy", 10)
	assert_equals(gm.reputation.mercy, 60, "mercy +10 → 60")

	gm.change_reputation("mercy", 50)
	assert_equals(gm.reputation.mercy, 100, "mercy 최대값 100 제한")

	gm.change_reputation("mercy", -150)
	assert_equals(gm.reputation.mercy, 0, "mercy 최소값 0 제한")

	# 손님 스케줄 테스트
	gm.reset_game()
	gm.start_new_day()
	assert_true(gm.today_customers.size() > 0, "Day 1에 손님 존재")

	# 다음 날 테스트
	gm.end_day()
	gm.start_new_day()
	assert_equals(gm.current_day, 2, "end_day + start_new_day 후 Day 2")

	print("  GameManager 테스트 완료\n")

# ===== SaveManager 테스트 =====

func test_save_manager() -> void:
	print("[테스트] SaveManager...")

	var sm = get_node_or_null("/root/SaveManager")
	assert_not_null(sm, "SaveManager Autoload 존재")

	if not sm:
		return

	# 설정 저장/로드 테스트
	sm.set_setting("test_key", "test_value")
	var loaded = sm.get_setting("test_key", "default")
	assert_equals(loaded, "test_value", "설정 저장/로드")

	# 기본값 테스트
	var default_val = sm.get_setting("nonexistent_key", "default_value")
	assert_equals(default_val, "default_value", "존재하지 않는 키 기본값 반환")

	# 게임 상태 저장/로드 테스트 (GameManager 필요)
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.reset_game()
		gm.current_day = 3
		gm.reputation.mercy = 75
		gm.completed_customers.append("test_customer")

		sm.save_game()

		# 상태 변경
		gm.current_day = 1
		gm.reputation.mercy = 50
		gm.completed_customers.clear()

		sm.load_game()

		assert_equals(gm.current_day, 3, "저장/로드 후 current_day 복원")
		assert_equals(gm.reputation.mercy, 75, "저장/로드 후 mercy 복원")
		assert_true(gm.completed_customers.has("test_customer"), "저장/로드 후 completed_customers 복원")

		# 정리
		gm.reset_game()

	print("  SaveManager 테스트 완료\n")

# ===== DialogueManager 테스트 =====

func test_dialogue_manager() -> void:
	print("[테스트] DialogueManager...")

	var dm = get_node_or_null("/root/DialogueManager")
	assert_not_null(dm, "DialogueManager Autoload 존재")

	if not dm:
		return

	# 대화 데이터 로드 테스트
	var minji_data = dm.get_dialogue_data("minji")
	assert_not_null(minji_data, "minji 대화 데이터 로드")

	if minji_data:
		assert_true(minji_data.has("name"), "대화 데이터에 name 필드 존재")
		assert_true(minji_data.has("dialogue"), "대화 데이터에 dialogue 필드 존재")

	# 존재하지 않는 손님 테스트
	var nonexistent = dm.get_dialogue_data("nonexistent_customer")
	# 빈 딕셔너리 또는 null 반환 확인
	assert_true(nonexistent == null or nonexistent.is_empty(), "존재하지 않는 손님 데이터 null/empty")

	print("  DialogueManager 테스트 완료\n")

# ===== 리소스 로드 테스트 =====

func test_resource_loading() -> void:
	print("[테스트] 리소스 로드...")

	# 포트레잇 이미지 테스트
	var portrait_paths = [
		"res://assets/portraits/portrait_minji.png",
		"res://assets/portraits/portrait_soldier_kim.png",
		"res://assets/portraits/portrait_haneul.png",
		"res://assets/portraits/portrait_professor_lee.png",
		"res://assets/portraits/portrait_gang.png",
		"res://assets/portraits/portrait_minji_mother.png",
		"res://assets/portraits/portrait_suyeon.png"
	]

	for path in portrait_paths:
		var exists = ResourceLoader.exists(path)
		var filename = path.get_file()
		assert_true(exists, "포트레잇 존재: %s" % filename)

	# 엔딩 일러스트 테스트
	var ending_paths = [
		"res://assets/illustrations/ending_merciful.png",
		"res://assets/illustrations/ending_just.png",
		"res://assets/illustrations/ending_pragmatic.png",
		"res://assets/illustrations/ending_liberator.png",
		"res://assets/illustrations/ending_forgotten.png",
		"res://assets/illustrations/ending_return.png",
		"res://assets/illustrations/ending_perfect.png",
		"res://assets/illustrations/ending_new_start.png"
	]

	for path in ending_paths:
		var exists = ResourceLoader.exists(path)
		var filename = path.get_file()
		# 일부 엔딩 일러스트는 아직 없을 수 있음 - 경고만 출력
		if not exists:
			print("    [경고] 엔딩 일러스트 없음: %s" % filename)
		else:
			record_pass("엔딩 일러스트 존재: %s" % filename)

	# JSON 대화 파일 테스트
	var dialogue_paths = [
		"res://resources/dialogues/minji.json",
		"res://resources/dialogues/park_elder.json",
		"res://resources/dialogues/jung_seokhyun.json",
		"res://resources/dialogues/soldier_kim.json",
		"res://resources/dialogues/idol_trainee.json",
		"res://resources/dialogues/professor_lee.json",
		"res://resources/dialogues/debt_collector.json",
		"res://resources/dialogues/minji_mother.json",
		"res://resources/dialogues/jinwoo_sister.json"
	]

	for path in dialogue_paths:
		var exists = FileAccess.file_exists(path)
		var filename = path.get_file()
		assert_true(exists, "대화 JSON 존재: %s" % filename)

	print("  리소스 로드 테스트 완료\n")

# ===== 씬 존재 테스트 =====

func test_scene_existence() -> void:
	print("[테스트] 씬 파일...")

	var scene_paths = [
		"res://scenes/main.tscn",
		"res://scenes/title_screen.tscn",
		"res://scenes/pawnshop.tscn",
		"res://scenes/dialogue.tscn",
		"res://scenes/memory_puzzle.tscn",
		"res://scenes/ending.tscn",
		"res://scenes/settings_menu.tscn"
	]

	for path in scene_paths:
		var exists = ResourceLoader.exists(path)
		var filename = path.get_file()
		assert_true(exists, "씬 존재: %s" % filename)

	print("  씬 파일 테스트 완료\n")

# ===== 어서션 헬퍼 =====

func assert_true(condition: bool, message: String) -> void:
	if condition:
		record_pass(message)
	else:
		record_fail(message)

func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)

func assert_equals(actual, expected, message: String) -> void:
	if actual == expected:
		record_pass(message)
	else:
		record_fail("%s (예상: %s, 실제: %s)" % [message, str(expected), str(actual)])

func assert_not_null(value, message: String) -> void:
	if value != null:
		record_pass(message)
	else:
		record_fail("%s (null 반환됨)" % message)

func record_pass(message: String) -> void:
	test_results.passed += 1
	test_results.details.append({"status": "PASS", "message": message})
	print("    ✓ %s" % message)

func record_fail(message: String) -> void:
	test_results.failed += 1
	test_results.errors.append(message)
	test_results.details.append({"status": "FAIL", "message": message})
	print("    ✗ %s" % message)
