extends Interactable
## เครื่องเล่นเทปในห้องหัวหน้าสถานี (ปริศนาที่ 3) — เปิดเทปที่เก็บมาทีละม้วน
## เสียงเทปดังพอให้ศัตรูได้ยิน (NoiseBus)

@export var playback_noise_radius := 9.0

var _playing_index := -1
var _timer := 0.0
var _noise_timer := 0.0
var _hiss: AudioStreamPlayer3D


func _setup():
	_hiss = AudioStreamPlayer3D.new()
	_hiss.stream = Audio.get_stream("static_loop")
	_hiss.bus = "SFX"
	_hiss.volume_db = -14.0
	add_child(_hiss)


func _next_tape() -> int:
	for i in GameState.data["docs_found"]:
		if Story.DOCUMENTS[i]["kind"] == "tape" and not (i in GameState.data["tapes_played"]):
			return i
	return -1


func get_prompt(_player) -> String:
	if _playing_index >= 0:
		return "เครื่องเล่นเทป — กำลังเล่น..."
	if not GameState.data["power_on"]:
		return "เครื่องเล่นเทป — ไม่มีไฟ"
	if _next_tape() >= 0:
		return "กด E เพื่อเปิดเทป"
	return "เครื่องเล่นเทป — ไม่มีเทปที่ยังไม่ได้ฟัง"


func can_interact(_player) -> bool:
	return _playing_index < 0 and GameState.data["power_on"] and _next_tape() >= 0


func interact(_player = null):
	_playing_index = _next_tape()
	var lines: Array = Story.DOCUMENTS[_playing_index]["lines"]
	_timer = 0.0
	for l in lines:
		_timer += float(l[1])
	Audio.play_sfx_3d("tape_click", global_position)
	_hiss.play()
	GameState.toast(Story.DOCUMENTS[_playing_index]["title"])
	GameState.show_subtitles(lines)


func _process(delta):
	if _playing_index < 0:
		return
	_timer -= delta
	_noise_timer -= delta
	if _noise_timer <= 0.0:
		_noise_timer = 2.0
		NoiseBus.emit_noise(global_position, playback_noise_radius, self)
	if _timer <= 0.0:
		_finish()


func _finish():
	if not (_playing_index in GameState.data["tapes_played"]):
		GameState.data["tapes_played"].append(_playing_index)
	if _playing_index == 3:
		GameState.toast("ได้รหัสหลักที่ 4")
	_playing_index = -1
	_hiss.stop()
	Audio.play_sfx_3d("tape_click", global_position)
	GameState.notify_progress()
	GameState.save_checkpoint(get_tree().get_first_node_in_group("player"))
