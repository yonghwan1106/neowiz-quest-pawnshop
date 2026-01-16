extends Control

## 엔딩 화면 컨트롤러
## 다중 엔딩 시스템 (Tier 1: 평판, Tier 2: 스토리, Tier 3: 히든)

var main_controller: Node = null

# UI 노드 참조
@onready var ending_illustration: TextureRect = $EndingIllustration
@onready var ending_title: Label = $ContentContainer/TopSection/EndingTitle
@onready var ending_subtitle: Label = $ContentContainer/TopSection/EndingSubtitle
@onready var ending_description: RichTextLabel = $ContentContainer/MiddleSection/DescriptionPanel/MarginContainer/Description
@onready var summary_panel: PanelContainer = $ContentContainer/MiddleSection/SummaryPanel
@onready var customer_summary: RichTextLabel = $ContentContainer/MiddleSection/SummaryPanel/MarginContainer/VBox/CustomerSummary
@onready var reputation_container: HBoxContainer = $ContentContainer/BottomSection/ReputationContainer
@onready var mercy_value: Label = $ContentContainer/BottomSection/ReputationContainer/MercyBox/Value
@onready var justice_value: Label = $ContentContainer/BottomSection/ReputationContainer/JusticeBox/Value
@onready var profit_value: Label = $ContentContainer/BottomSection/ReputationContainer/ProfitBox/Value
@onready var button_container: HBoxContainer = $ContentContainer/BottomSection/ButtonContainer
@onready var restart_button: Button = $ContentContainer/BottomSection/ButtonContainer/RestartButton
@onready var quit_button: Button = $ContentContainer/BottomSection/ButtonContainer/QuitButton
@onready var epilogue_label: RichTextLabel = $ContentContainer/BottomSection/EpilogueLabel

# 엔딩 일러스트 리소스
var ending_illustrations = {
	"mercy": "res://assets/illustrations/ending_mercy.png",
	"justice": "res://assets/illustrations/ending_justice.png",
	"profit": "res://assets/illustrations/ending_profit.png",
	"liberator": "res://assets/illustrations/ending_liberator.png",
	"forgotten": "res://assets/illustrations/ending_forgotten.png",
	"returner": "res://assets/illustrations/ending_return.png",
	"perfect": "res://assets/illustrations/ending_perfect.png",
	"new_start": "res://assets/illustrations/ending_new_start.png"
}

# 엔딩별 색상 테마
var ending_colors = {
	"mercy": Color(0, 0.96, 0.83, 1),      # 시안
	"justice": Color(0.96, 0.72, 0, 1),    # 황금
	"profit": Color(0.4, 1, 0.4, 1),       # 녹색
	"liberator": Color(0.9, 0.3, 0.3, 1),  # 빨강
	"forgotten": Color(0.6, 0.6, 0.8, 1),  # 연보라
	"returner": Color(1, 0.85, 0.5, 1),    # 따뜻한 금
	"perfect": Color(1, 1, 0.8, 1),        # 밝은 금
	"new_start": Color(0.8, 0.9, 1, 1)     # 하늘색
}

# 엔딩 데이터
var ending_data = {
	# Tier 1: 평판 기반 엔딩
	"mercy": {
		"title": "자비로운 전당포지기",
		"subtitle": "당신은 손님들의 아픔을 이해하려 했습니다",
		"description": "7일간의 여정 동안, 당신은 기억보다 사람을 우선했습니다.\n\n손님들은 당신의 전당포를 '따뜻한 곳'이라 불렀습니다. 어떤 이는 기억을 지켰고, 어떤 이는 새로운 시작을 찾았습니다.\n\n기억의 전당포는 이제 '마음의 전당포'로 알려지게 되었습니다.",
		"epilogue": "\"기억은 팔 수 있어도, 따뜻함은 팔 수 없다.\"\n- 진우의 마지막 일지에서"
	},
	"justice": {
		"title": "정의로운 전당포지기",
		"subtitle": "당신은 옳고 그름의 경계를 지켰습니다",
		"description": "7일간의 여정 동안, 당신은 쉬운 길 대신 옳은 길을 선택했습니다.\n\n일부는 당신을 냉정하다 했지만, 결국 모두가 그 선택의 의미를 이해했습니다.\n\n기억의 전당포는 '진실의 전당포'로 이름을 바꿨습니다.",
		"epilogue": "\"기억을 거래하는 것이 아니라, 진실을 지키는 일이었다.\"\n- 진우의 마지막 일지에서"
	},
	"profit": {
		"title": "냉철한 전당포지기",
		"subtitle": "당신은 거래의 본질을 잊지 않았습니다",
		"description": "7일간의 여정 동안, 당신은 감정에 흔들리지 않았습니다.\n\n전당포의 수익은 네오시티에서 가장 높았지만, 밤마다 손님들의 얼굴이 떠올랐습니다.\n\n부는 쌓였지만, 마음은 점점 무거워졌습니다.",
		"epilogue": "\"기억의 가격은 매겼지만, 양심의 가격은 매기지 못했다.\"\n- 진우의 마지막 일지에서"
	},

	# Tier 2: 스토리 기반 엔딩
	"liberator": {
		"title": "기억 해방자",
		"subtitle": "당신은 네오코프의 진실을 세상에 알렸습니다",
		"description": "수연과 함께 네오코프의 비밀을 파헤친 당신은 세상을 바꿨습니다.\n\n강제 기억 추출 실험의 진실이 밝혀지고, 네오코프 임원들은 법정에 섰습니다.\n\n기억 거래법이 개정되었고, 피해자들은 마침내 정의를 찾았습니다.\n\n하지만 대가도 컸습니다. 전당포는 문을 닫아야 했고, 당신은 새로운 싸움을 시작했습니다.",
		"epilogue": "\"어둠 속에서 빛을 찾는 것이 아니라, 어둠을 밝히는 것.\"\n- 김수연, 기억 해방 운동 연설에서"
	},
	"forgotten": {
		"title": "잊혀진 자",
		"subtitle": "당신은 자신의 기억을 지워 타인을 보호했습니다",
		"description": "네오코프의 추적을 피하기 위해, 당신은 스스로 기억을 지웠습니다.\n\n수연에 대한 기억, 전당포에서의 7일, 모든 것을.\n\n당신은 다른 도시에서 새 삶을 시작했습니다. 행복한지는 알 수 없지만, 수연은 안전했습니다.\n\n가끔 이유 모를 눈물이 흐르지만, 왜인지는 모릅니다.",
		"epilogue": "\"기억이 없어도 사랑은 남는다. 그것이 기억의 본질이다.\"\n- 익명의 편지, 수연의 책상에서 발견됨"
	},
	"returner": {
		"title": "귀환자",
		"subtitle": "당신은 자신의 기억을 되찾고 가족과 재회했습니다",
		"description": "5년 만에 되찾은 기억은 고통스러웠지만, 당신은 도망치지 않았습니다.\n\n수연과 함께 과거를 마주하고, 네오코프에 맞서 싸웠습니다.\n\n전당포는 여전히 운영됩니다. 하지만 이제 당신 곁에는 가족이 있습니다.\n\n기억은 때로 아프지만, 그것이 우리를 우리로 만듭니다.",
		"epilogue": "\"돌아온다는 건, 떠났던 곳이 있다는 것.\n그리고 기다리는 사람이 있다는 것.\"\n- 진우, 수연에게"
	},

	# Tier 3: 히든 엔딩
	"perfect": {
		"title": "완벽한 기억",
		"subtitle": "모든 선택이 최선을 향했습니다",
		"description": "7일간 모든 손님에게 최적의 결과를 이끌어낸 당신.\n\n민지는 보조금으로 수술을 받았고, 박 노인은 아내와 평화롭게 지냅니다.\n정석현은 피해자에게 보상하며 살고, 김 상병은 스스로 증언대에 섰습니다.\n\n완벽한 선택은 없지만, 최선의 선택은 있었습니다.\n당신은 그것을 증명했습니다.",
		"epilogue": "\"전당포지기의 일은 기억을 사고파는 게 아니라,\n사람들이 자신의 기억과 화해하도록 돕는 것이었다.\"\n- 진우, 은퇴 기념 인터뷰에서"
	},
	"new_start": {
		"title": "새로운 시작",
		"subtitle": "모든 기억을 리셋하고 새 삶을 시작했습니다",
		"description": "어느 날, 당신은 모든 것을 내려놓기로 했습니다.\n\n전당포, 손님들, 심지어 자신의 이름까지.\n\n완전한 리셋. 새로운 시작.\n\n이것이 도피인지, 해방인지는 알 수 없습니다.\n하지만 텅 빈 마음으로, 당신은 처음으로 미래를 향해 걷기 시작했습니다.",
		"epilogue": "\"기억 없이 사는 것은 불가능하다.\n하지만 새로운 기억을 만드는 것은 가능하다.\"\n- 이름 모를 남자, 해변에서"
	}
}

# 평판 목표값
var target_mercy: int = 0
var target_justice: int = 0
var target_profit: int = 0

var current_ending_type: String = ""

func _ready() -> void:
	_connect_buttons()
	_setup_ending()

func _connect_buttons() -> void:
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
		restart_button.mouse_entered.connect(_on_button_hover.bind(restart_button))

	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		quit_button.mouse_entered.connect(_on_button_hover.bind(quit_button))

func set_main_controller(controller: Node) -> void:
	main_controller = controller

func setup(_data: Dictionary) -> void:
	_setup_ending()

func _setup_ending() -> void:
	# 엔딩 타입 결정
	current_ending_type = GameManager.get_detailed_ending_type()

	# 평판값 저장
	target_mercy = GameManager.reputation.mercy
	target_justice = GameManager.reputation.justice
	target_profit = GameManager.reputation.profit

	# 초기값 설정
	if mercy_value:
		mercy_value.text = "0"
	if justice_value:
		justice_value.text = "0"
	if profit_value:
		profit_value.text = "0"

	# 손님 결과 요약
	_setup_customer_summary()

	# 엔딩 콘텐츠 설정
	_set_ending_content(current_ending_type)

	# 엔딩 BGM 재생
	_play_ending_bgm(current_ending_type)

	# 애니메이션 시작
	_play_entrance_animation()

func _setup_customer_summary() -> void:
	if not customer_summary:
		return

	var summary_text = ""
	for customer_id in GameManager.customer_results:
		var result = GameManager.customer_results[customer_id]
		var customer_name = _get_customer_name(customer_id)
		var result_text = _get_result_text(customer_id, result)
		var result_color = _get_result_color(result)
		summary_text += "[color=#a855f7]%s[/color]: [color=%s]%s[/color]\n" % [customer_name, result_color, result_text]

	if summary_text.is_empty():
		summary_text = "[color=#888888]아직 만난 손님이 없습니다.[/color]"

	customer_summary.text = summary_text

func _get_customer_name(customer_id: String) -> String:
	var names = {
		"minji": "민지",
		"park_elder": "박 노인",
		"jung_seokhyun": "정석현",
		"soldier_kim": "김 상병",
		"idol_trainee": "하늘",
		"professor_lee": "이 교수",
		"debt_collector": "강 회장",
		"minji_mother": "민지 어머니",
		"jinwoo_sister": "김수연"
	}
	return names.get(customer_id, "손님")

func _get_result_text(_customer_id: String, result: String) -> String:
	match result:
		"accept":
			return "기억을 매입했습니다"
		"reject":
			return "거래를 거절했습니다"
		"modify":
			return "기억을 수정했습니다"
		_:
			return "알 수 없음"

func _get_result_color(result: String) -> String:
	match result:
		"accept":
			return "#00f5d4"
		"reject":
			return "#ff6b6b"
		"modify":
			return "#f5b700"
		_:
			return "#888888"

func _set_ending_content(ending_type: String) -> void:
	var data = ending_data.get(ending_type, ending_data["mercy"])
	var color = ending_colors.get(ending_type, Color.WHITE)

	# 타이틀
	if ending_title:
		ending_title.text = data.get("title", "엔딩")
		ending_title.add_theme_color_override("font_shadow_color", Color(color.r, color.g, color.b, 0.5))
		ending_title.modulate = Color(color.r, color.g, color.b, 0)

	# 서브타이틀
	if ending_subtitle:
		ending_subtitle.text = data.get("subtitle", "")

	# 설명
	if ending_description:
		ending_description.text = data.get("description", "")

	# 에필로그
	if epilogue_label:
		epilogue_label.text = "[i]%s[/i]" % data.get("epilogue", "")

	# 일러스트
	if ending_illustration:
		var illustration_path = ending_illustrations.get(ending_type, "")
		if illustration_path and ResourceLoader.exists(illustration_path):
			ending_illustration.texture = load(illustration_path)

func _play_ending_bgm(ending_type: String) -> void:
	var audio_manager = get_node_or_null("/root/AudioManager")
	if not audio_manager or not audio_manager.has_method("play_bgm"):
		return

	# 엔딩 타입에 따른 BGM
	var bgm_map = {
		"mercy": "ending_mercy",
		"justice": "ending_justice",
		"profit": "ending_profit",
		"liberator": "ending_justice",
		"forgotten": "ending_mercy",
		"returner": "ending_mercy",
		"perfect": "ending_justice",
		"new_start": "ending_mercy"
	}

	var bgm_name = bgm_map.get(ending_type, "ending_mercy")
	audio_manager.play_bgm(bgm_name)

func _play_entrance_animation() -> void:
	var tween = create_tween()
	tween.set_parallel(false)

	# 일러스트 페이드 인
	if ending_illustration:
		ending_illustration.modulate.a = 0
		tween.tween_property(ending_illustration, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_OUT)

	# 타이틀 슬라이드 업 + 페이드 인
	if ending_title:
		var title_start_y = ending_title.position.y + 30
		ending_title.position.y = title_start_y
		tween.tween_property(ending_title, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(ending_title, "position:y", title_start_y - 30, 0.8).set_ease(Tween.EASE_OUT)

	# 서브타이틀 페이드 인
	if ending_subtitle:
		ending_subtitle.modulate.a = 0
		tween.tween_property(ending_subtitle, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT).set_delay(0.2)

	# 설명 페이드 인
	if ending_description:
		ending_description.modulate.a = 0
		tween.tween_property(ending_description, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT).set_delay(0.3)

	# 요약 패널 페이드 인
	if summary_panel:
		summary_panel.modulate.a = 0
		tween.tween_property(summary_panel, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT).set_delay(0.3)

	# 평판 컨테이너 + 카운트업
	if reputation_container:
		reputation_container.modulate.a = 0
		tween.tween_property(reputation_container, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_delay(0.2)
		tween.tween_callback(_start_reputation_countup)

	# 에필로그
	if epilogue_label:
		epilogue_label.modulate.a = 0
		tween.tween_property(epilogue_label, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT).set_delay(0.5)

	# 버튼
	if button_container:
		button_container.modulate.a = 0
		tween.tween_property(button_container, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_delay(0.3)

func _start_reputation_countup() -> void:
	var count_tween = create_tween()
	count_tween.set_parallel(true)

	count_tween.tween_method(_update_mercy_label, 0, target_mercy, 1.0).set_ease(Tween.EASE_OUT)
	count_tween.tween_method(_update_justice_label, 0, target_justice, 1.0).set_ease(Tween.EASE_OUT)
	count_tween.tween_method(_update_profit_label, 0, target_profit, 1.0).set_ease(Tween.EASE_OUT)

func _update_mercy_label(value: int) -> void:
	if mercy_value:
		mercy_value.text = str(value)

func _update_justice_label(value: int) -> void:
	if justice_value:
		justice_value.text = str(value)

func _update_profit_label(value: int) -> void:
	if profit_value:
		profit_value.text = str(value)

func _on_button_hover(button: Button) -> void:
	var hover_tween = create_tween()
	hover_tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	hover_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	_play_sfx("button_hover")

func _play_sfx(sfx_name: String) -> void:
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(sfx_name)

func _on_restart_pressed() -> void:
	_play_sfx("button_click")
	GameManager.reset_game()
	if main_controller:
		main_controller.change_scene("title")

func _on_quit_pressed() -> void:
	_play_sfx("button_click")
	get_tree().quit()
