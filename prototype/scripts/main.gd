extends Node2D

## 메인 씬 컨트롤러 - 씬 전환 및 페이드 효과 관리

@onready var scene_container: Control = $CanvasLayer/SceneContainer
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect

var current_scene: Node = null
var is_transitioning: bool = false

# 씬 경로
const SCENES = {
	"title": "res://scenes/title_screen.tscn",
	"pawnshop": "res://scenes/pawnshop.tscn",
	"dialogue": "res://scenes/dialogue.tscn",
	"puzzle": "res://scenes/memory_puzzle.tscn",
	"ending": "res://scenes/ending.tscn"
}

func _ready() -> void:
	# 시작 시 타이틀 화면 로드
	_load_scene("title")

func change_scene(scene_name: String, data: Dictionary = {}) -> void:
	if is_transitioning:
		return

	is_transitioning = true
	await _fade_out()
	_load_scene(scene_name, data)
	await _fade_in()
	is_transitioning = false

func _load_scene(scene_name: String, data: Dictionary = {}) -> void:
	# 현재 씬 제거
	if current_scene:
		current_scene.queue_free()
		await current_scene.tree_exited

	# 새 씬 로드
	if SCENES.has(scene_name):
		var scene_resource = load(SCENES[scene_name])
		current_scene = scene_resource.instantiate()
		scene_container.add_child(current_scene)

		# 씬에 데이터 전달
		if current_scene.has_method("setup"):
			current_scene.setup(data)

		# 메인 씬 참조 전달
		if current_scene.has_method("set_main_controller"):
			current_scene.set_main_controller(self)

func _fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.3)
	await tween.finished

func _fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.3)
	await tween.finished
