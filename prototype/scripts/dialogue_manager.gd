extends Node

## 대화 시스템을 관리하는 오토로드 싱글톤

signal dialogue_started(customer_id: String)
signal dialogue_line_displayed(speaker: String, text: String)
signal dialogue_choice_requested(choices: Array)
signal dialogue_ended(customer_id: String)

var current_dialogue: Dictionary = {}
var current_line_index: int = 0
var current_customer_id: String = ""
var is_dialogue_active: bool = false

# 대화 데이터 저장
var dialogues: Dictionary = {}

func _ready() -> void:
	_load_all_dialogues()

func _load_all_dialogues() -> void:
	# 프로토타입용 하드코딩된 대화 데이터
	dialogues = {
		"minji": _get_minji_dialogue(),
		"park_elder": _get_park_elder_dialogue(),
		"jung_seokhyun": _get_jung_seokhyun_dialogue()
	}

func _get_minji_dialogue() -> Dictionary:
	return {
		"intro": [
			{"speaker": "민지", "text": "저... 여기가 기억 전당포 맞죠?"},
			{"speaker": "진우", "text": "그렇습니다. 무엇을 도와드릴까요?"},
			{"speaker": "민지", "text": "저... 기억을 팔러 왔어요. 돈이 필요해서요."},
			{"speaker": "진우", "text": "어떤 기억을 팔고 싶으신가요?"},
			{"speaker": "민지", "text": "할머니랑... 어릴 때 같이 보낸 기억이요."},
			{"speaker": "민지", "text": "사이버네틱 팔 수술비가 필요해요. 사고로 왼팔을 잃었거든요."},
			{"speaker": "진우", "text": "(기억 구슬을 건네받으며) 감정을 해보겠습니다."}
		],
		"after_puzzle": [
			{"speaker": "진우", "text": "이 기억은... 할머니와 함께한 여름날의 추억이군요."},
			{"speaker": "진우", "text": "바닷가에서 조개를 줍고, 할머니가 해주신 칼국수를 먹던..."},
			{"speaker": "민지", "text": "네... 할머니는 3년 전에 돌아가셨어요."},
			{"speaker": "민지", "text": "이 기억 말고는... 팔 수 있는 게 없어요."},
			{"speaker": "진우", "text": "이 기억을 팔면, 할머니와의 그 여름날을 영영 잊게 됩니다."},
			{"speaker": "진우", "text": "그래도 괜찮으시겠습니까?"},
			{"speaker": "민지", "text": "...괜찮아요. 팔이 없으면 일도 못 하니까요."}
		],
		"choices": [
			{"id": "accept", "text": "[매입] 기억을 사들인다 (500만원)", "result": "accept"},
			{"id": "reject", "text": "[거절] 이 기억은 팔지 마세요", "result": "reject"},
			{"id": "modify", "text": "[수정] 일부만 추출하고 핵심은 남긴다", "result": "modify"}
		],
		"endings": {
			"accept": [
				{"speaker": "진우", "text": "...알겠습니다. 500만원에 매입하겠습니다."},
				{"speaker": "민지", "text": "감사합니다... 정말 감사합니다!"},
				{"speaker": "내레이션", "text": "민지는 수술비를 마련했지만, 할머니와의 그 여름날을 영영 잃었다."},
				{"speaker": "내레이션", "text": "1년 후, 그녀는 왜 자신이 바다를 보면 눈물이 나는지 알 수 없었다."}
			],
			"reject": [
				{"speaker": "진우", "text": "...이 기억은 팔지 마세요."},
				{"speaker": "민지", "text": "네? 하지만 저 정말 돈이..."},
				{"speaker": "진우", "text": "사이버네틱 팔 보조금 제도가 있습니다. 제가 신청서를 도와드리죠."},
				{"speaker": "민지", "text": "그런 게... 있었어요?"},
				{"speaker": "내레이션", "text": "민지는 기억을 지켰고, 보조금으로 수술을 받았다."},
				{"speaker": "내레이션", "text": "그녀는 지금도 할머니의 칼국수 레시피를 간직하고 있다."}
			],
			"modify": [
				{"speaker": "진우", "text": "다른 방법이 있습니다. 기억의 '감정'만 추출하는 거예요."},
				{"speaker": "민지", "text": "감정만요?"},
				{"speaker": "진우", "text": "할머니와의 추억은 남지만, 그때 느꼈던 '행복감'만 분리합니다."},
				{"speaker": "진우", "text": "200만원밖에 못 드리지만... 기억 자체는 지킬 수 있어요."},
				{"speaker": "민지", "text": "...그렇게 해주세요."},
				{"speaker": "내레이션", "text": "민지는 할머니와의 기억을 지켰지만, 그 기억을 떠올릴 때 더 이상 행복하지 않았다."},
				{"speaker": "내레이션", "text": "하지만 그녀는 후회하지 않았다. 기억이라도 남았으니까."}
			]
		}
	}

func _get_park_elder_dialogue() -> Dictionary:
	return {
		"intro": [
			{"speaker": "박 노인", "text": "기억을... 이식할 수 있다고 들었소."},
			{"speaker": "진우", "text": "네, 가능합니다. 누구에게 이식하시려고요?"},
			{"speaker": "박 노인", "text": "내 아내... 50년을 함께한 사람이오."},
			{"speaker": "박 노인", "text": "치매가 와서... 나를 못 알아보기 시작했어."},
			{"speaker": "진우", "text": "그래서 당신의 기억을 아내분께 이식하시려는..."},
			{"speaker": "박 노인", "text": "내 첫사랑 기억이오. 아내를 처음 만났던 그날."},
			{"speaker": "박 노인", "text": "이 기억만 있으면... 날 다시 알아볼 수 있을 거요."}
		],
		"after_puzzle": [
			{"speaker": "진우", "text": "1974년 봄... 대학교 도서관에서의 만남이군요."},
			{"speaker": "진우", "text": "창가에서 책을 읽던 그녀에게 말을 걸었던..."},
			{"speaker": "박 노인", "text": "그렇소. 그날 이후로 50년을 함께했어."},
			{"speaker": "진우", "text": "하지만... 기억 이식에는 위험이 있습니다."},
			{"speaker": "진우", "text": "본인 기억이 아닌 것을 받아들이면, 혼란이 생길 수 있어요."},
			{"speaker": "박 노인", "text": "상관없소. 날 잊어버린 채로 사는 것보다는..."}
		],
		"choices": [
			{"id": "accept", "text": "[매입 후 이식] 기억을 이식해 드린다", "result": "accept"},
			{"id": "reject", "text": "[거절] 위험을 설명하고 거절한다", "result": "reject"},
			{"id": "modify", "text": "[수정] 기억 대신 '감정의 흔적'만 이식한다", "result": "modify"}
		],
		"endings": {
			"accept": [
				{"speaker": "진우", "text": "...알겠습니다. 이식을 진행하죠."},
				{"speaker": "내레이션", "text": "기억 이식은 성공했다. 아내는 남편을 다시 알아봤다."},
				{"speaker": "내레이션", "text": "하지만 3개월 후, 그녀는 자신의 기억과 남편의 기억 사이에서 혼란에 빠졌다."},
				{"speaker": "내레이션", "text": "그녀는 '내가 누구인지 모르겠다'고 말하며 울었다."}
			],
			"reject": [
				{"speaker": "진우", "text": "죄송합니다. 이 이식은 해드릴 수 없습니다."},
				{"speaker": "박 노인", "text": "왜... 왜 안 되는 거요?"},
				{"speaker": "진우", "text": "아내분은 당신을 '기억'으로 사랑한 게 아닙니다."},
				{"speaker": "진우", "text": "50년간의 '함께함'으로 사랑한 거예요. 그건 여전히 남아있습니다."},
				{"speaker": "내레이션", "text": "박 노인은 한동안 침묵했다. 그리고 천천히 일어났다."},
				{"speaker": "내레이션", "text": "\"옳은 말이오.\" 그는 아내에게 돌아갔다. 매일, 처음 만나는 것처럼 인사하며."}
			],
			"modify": [
				{"speaker": "진우", "text": "다른 방법이 있습니다. '감정의 흔적'이라는 기술이에요."},
				{"speaker": "진우", "text": "기억 자체가 아니라, 그 사람에 대한 '느낌'만 이식합니다."},
				{"speaker": "박 노인", "text": "느낌이라..."},
				{"speaker": "진우", "text": "아내분이 당신을 보면, '안심되는 사람'이라고 느끼게 됩니다."},
				{"speaker": "내레이션", "text": "이식 후, 아내는 남편을 알아보지 못했지만,"},
				{"speaker": "내레이션", "text": "그가 곁에 있으면 이상하게 마음이 편해진다고 말했다."}
			]
		}
	}

func _get_jung_seokhyun_dialogue() -> Dictionary:
	return {
		"intro": [
			{"speaker": "정석현", "text": "기억을 지울 수 있다면서요."},
			{"speaker": "진우", "text": "정확히는 '매입'입니다. 지우는 게 아니라 가져가는 거죠."},
			{"speaker": "정석현", "text": "상관없어요. 이 기억만 없으면 돼요."},
			{"speaker": "진우", "text": "어떤 기억인지 여쭤봐도 될까요?"},
			{"speaker": "정석현", "text": "...3년 전에 저지른 일이에요."},
			{"speaker": "정석현", "text": "사람을 다치게 했어요. 일부러는 아니었지만..."},
			{"speaker": "정석현", "text": "매일 밤 그 장면이 떠올라요. 더 이상 못 견디겠어요."}
		],
		"after_puzzle": [
			{"speaker": "진우", "text": "음주운전... 사고였군요."},
			{"speaker": "정석현", "text": "...네. 피해자는 지금도 병원에 있어요."},
			{"speaker": "진우", "text": "이 기억을 팔면, 죄책감에서 벗어나실 수 있습니다."},
			{"speaker": "진우", "text": "하지만 피해자는 여전히 고통받고 있을 겁니다."},
			{"speaker": "정석현", "text": "알아요... 하지만 저도 사람이에요."},
			{"speaker": "정석현", "text": "이렇게 괴로운 건... 참을 수가 없어요."},
			{"speaker": "진우", "text": "..."}
		],
		"choices": [
			{"id": "accept", "text": "[매입] 기억을 사들인다 (1000만원)", "result": "accept"},
			{"id": "reject", "text": "[거절] 이 기억은 당신이 지고 가야 합니다", "result": "reject"},
			{"id": "modify", "text": "[수정] 기억에 단서를 남겨 피해자에게 보상하게 한다", "result": "modify"}
		],
		"endings": {
			"accept": [
				{"speaker": "진우", "text": "...알겠습니다. 1000만원에 매입하겠습니다."},
				{"speaker": "정석현", "text": "감사합니다... 정말 감사합니다."},
				{"speaker": "내레이션", "text": "정석현은 죄책감에서 벗어났다. 하지만 피해자는 여전히 병원에 있었다."},
				{"speaker": "내레이션", "text": "1년 후, 그는 같은 도로에서 다시 사고를 냈다. 기억이 없으니, 교훈도 없었다."}
			],
			"reject": [
				{"speaker": "진우", "text": "이 기억은 팔 수 없습니다."},
				{"speaker": "정석현", "text": "왜요? 돈이 더 필요해요?"},
				{"speaker": "진우", "text": "아닙니다. 이건 당신이 져야 할 짐이에요."},
				{"speaker": "진우", "text": "죄책감은 당신을 더 나은 사람으로 만들 수 있습니다."},
				{"speaker": "정석현", "text": "..."},
				{"speaker": "내레이션", "text": "정석현은 분노하며 떠났다. 하지만 6개월 후, 그는 피해자를 찾아갔다."},
				{"speaker": "내레이션", "text": "평생 책임지겠다고, 그는 말했다."}
			],
			"modify": [
				{"speaker": "진우", "text": "다른 방법이 있습니다."},
				{"speaker": "진우", "text": "기억을 팔되, 그 안에 '단서'를 남기는 거예요."},
				{"speaker": "정석현", "text": "단서요?"},
				{"speaker": "진우", "text": "피해자에 대한 정보와, 당신이 해야 할 일에 대한 메모."},
				{"speaker": "진우", "text": "기억은 사라지지만, 그 종이를 볼 때마다 해야 할 일을 떠올리게 됩니다."},
				{"speaker": "내레이션", "text": "정석현은 동의했다. 그는 매달 피해자에게 보상금을 보냈다."},
				{"speaker": "내레이션", "text": "왜 보내는지 모르지만, 그렇게 해야 할 것 같았다고 그는 말했다."}
			]
		}
	}

func start_dialogue(customer_id: String) -> void:
	if not dialogues.has(customer_id):
		push_error("Dialogue not found for customer: " + customer_id)
		return

	current_customer_id = customer_id
	current_dialogue = dialogues[customer_id]
	current_line_index = 0
	is_dialogue_active = true
	emit_signal("dialogue_started", customer_id)

func get_intro_lines() -> Array:
	return current_dialogue.get("intro", [])

func get_after_puzzle_lines() -> Array:
	return current_dialogue.get("after_puzzle", [])

func get_choices() -> Array:
	return current_dialogue.get("choices", [])

func get_ending_lines(result: String) -> Array:
	var endings = current_dialogue.get("endings", {})
	return endings.get(result, [])

func end_dialogue() -> void:
	emit_signal("dialogue_ended", current_customer_id)
	current_customer_id = ""
	current_dialogue = {}
	current_line_index = 0
	is_dialogue_active = false
