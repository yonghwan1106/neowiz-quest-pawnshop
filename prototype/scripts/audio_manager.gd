extends Node

## 오디오 매니저 싱글톤
## BGM과 SFX를 관리하고 크로스페이드 기능 제공

# BGM 플레이어
var bgm_player: AudioStreamPlayer
var bgm_player_secondary: AudioStreamPlayer  # 크로스페이드용

# SFX 플레이어 풀
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 8

# 현재 재생 중인 BGM
var current_bgm: String = ""

# 볼륨 설정
var bgm_volume: float = 0.7
var sfx_volume: float = 0.8
var master_volume: float = 1.0

# BGM 리소스 경로
var bgm_paths = {
	"pawnshop": "res://assets/audio/bgm_pawnshop.ogg",
	"ending_mercy": "res://assets/audio/bgm_ending_mercy.ogg",
	"ending_justice": "res://assets/audio/bgm_ending_justice.ogg",
	"ending_profit": "res://assets/audio/bgm_ending_profit.ogg",
	"title": "res://assets/audio/bgm_title.ogg",
	"memory_puzzle": "res://assets/audio/bgm_memory_puzzle.ogg"
}

# SFX 리소스 경로
var sfx_paths = {
	"button_click": "res://assets/audio/sfx_button_click.ogg",
	"button_hover": "res://assets/audio/sfx_button_hover.ogg",
	"memory_complete": "res://assets/audio/sfx_memory_complete.ogg",
	"choice_select": "res://assets/audio/sfx_choice_select.ogg",
	"typing": "res://assets/audio/sfx_typing.ogg",
	"customer_enter": "res://assets/audio/sfx_customer_enter.ogg",
	"memory_fragment": "res://assets/audio/sfx_memory_fragment.ogg"
}

# 캐시된 오디오 스트림
var bgm_cache: Dictionary = {}
var sfx_cache: Dictionary = {}

func _ready() -> void:
	_setup_audio_players()
	_preload_audio()

func _setup_audio_players() -> void:
	# BGM 플레이어 생성
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	add_child(bgm_player)

	bgm_player_secondary = AudioStreamPlayer.new()
	bgm_player_secondary.bus = "Music"
	bgm_player_secondary.volume_db = linear_to_db(0)
	add_child(bgm_player_secondary)

	# SFX 플레이어 풀 생성
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.volume_db = linear_to_db(sfx_volume * master_volume)
		add_child(player)
		sfx_players.append(player)

func _preload_audio() -> void:
	# BGM 프리로드
	for key in bgm_paths:
		var path = bgm_paths[key]
		if ResourceLoader.exists(path):
			bgm_cache[key] = load(path)

	# SFX 프리로드
	for key in sfx_paths:
		var path = sfx_paths[key]
		if ResourceLoader.exists(path):
			sfx_cache[key] = load(path)

## BGM 재생 (크로스페이드 포함)
func play_bgm(bgm_name: String, crossfade_time: float = 1.0) -> void:
	if current_bgm == bgm_name:
		return  # 같은 BGM이면 무시

	var stream = _get_bgm_stream(bgm_name)
	if stream == null:
		push_warning("AudioManager: BGM '%s' not found" % bgm_name)
		return

	if current_bgm.is_empty() or crossfade_time <= 0:
		# 즉시 재생
		bgm_player.stream = stream
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
		bgm_player.play()
	else:
		# 크로스페이드
		_crossfade_bgm(stream, crossfade_time)

	current_bgm = bgm_name

func _crossfade_bgm(new_stream: AudioStream, duration: float) -> void:
	# 새 BGM을 secondary에서 시작
	bgm_player_secondary.stream = new_stream
	bgm_player_secondary.volume_db = linear_to_db(0)
	bgm_player_secondary.play()

	# 크로스페이드 트윈
	var tween = create_tween()
	tween.set_parallel(true)

	# 기존 BGM 페이드 아웃
	tween.tween_property(bgm_player, "volume_db", linear_to_db(0.001), duration)

	# 새 BGM 페이드 인
	tween.tween_property(bgm_player_secondary, "volume_db",
		linear_to_db(bgm_volume * master_volume), duration)

	# 완료 후 플레이어 교체
	tween.chain().tween_callback(_swap_bgm_players)

func _swap_bgm_players() -> void:
	bgm_player.stop()
	var temp = bgm_player
	bgm_player = bgm_player_secondary
	bgm_player_secondary = temp

func _get_bgm_stream(bgm_name: String) -> AudioStream:
	if bgm_cache.has(bgm_name):
		return bgm_cache[bgm_name]

	if bgm_paths.has(bgm_name):
		var path = bgm_paths[bgm_name]
		if ResourceLoader.exists(path):
			var stream = load(path)
			bgm_cache[bgm_name] = stream
			return stream

	return null

## BGM 정지
func stop_bgm(fade_time: float = 0.5) -> void:
	if fade_time <= 0:
		bgm_player.stop()
		bgm_player_secondary.stop()
	else:
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", linear_to_db(0.001), fade_time)
		tween.tween_callback(bgm_player.stop)

	current_bgm = ""

## BGM 일시정지
func pause_bgm() -> void:
	bgm_player.stream_paused = true

## BGM 재개
func resume_bgm() -> void:
	bgm_player.stream_paused = false

## SFX 재생
func play_sfx(sfx_name: String, pitch_variation: float = 0.0) -> void:
	var stream = _get_sfx_stream(sfx_name)
	if stream == null:
		# 파일이 없으면 조용히 무시 (프로토타입에서는 정상)
		return

	var player = _get_available_sfx_player()
	if player == null:
		return

	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * master_volume)

	if pitch_variation > 0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	else:
		player.pitch_scale = 1.0

	player.play()

func _get_sfx_stream(sfx_name: String) -> AudioStream:
	if sfx_cache.has(sfx_name):
		return sfx_cache[sfx_name]

	if sfx_paths.has(sfx_name):
		var path = sfx_paths[sfx_name]
		if ResourceLoader.exists(path):
			var stream = load(path)
			sfx_cache[sfx_name] = stream
			return stream

	return null

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player

	# 모두 사용 중이면 가장 오래된 것 반환
	return sfx_players[0]

## 볼륨 설정
func set_bgm_volume(volume: float) -> void:
	bgm_volume = clamp(volume, 0.0, 1.0)
	bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume * master_volume)

func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	set_bgm_volume(bgm_volume)
	set_sfx_volume(sfx_volume)

## 볼륨 가져오기
func get_bgm_volume() -> float:
	return bgm_volume

func get_sfx_volume() -> float:
	return sfx_volume

func get_master_volume() -> float:
	return master_volume

## 타이핑 효과음 (연속 재생용)
var typing_timer: Timer = null
var typing_active: bool = false

func start_typing_sfx(interval: float = 0.05) -> void:
	if typing_active:
		return

	typing_active = true

	if typing_timer == null:
		typing_timer = Timer.new()
		typing_timer.timeout.connect(_on_typing_timer)
		add_child(typing_timer)

	typing_timer.wait_time = interval
	typing_timer.start()

func stop_typing_sfx() -> void:
	typing_active = false
	if typing_timer:
		typing_timer.stop()

func _on_typing_timer() -> void:
	if typing_active:
		play_sfx("typing", 0.1)  # 약간의 피치 변화
