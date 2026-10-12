extends Interactable
## แป้นรหัสข้างประตูทางออก — ใส่รหัส 4 หลักถูก → ประตูเปิด
## ใส่ผิด → เสียงเตือนดัง ศัตรูได้ยิน (NoiseBus)

@export var door_path: NodePath
@export var wrong_code_noise_radius := 12.0  # เดิม 16


func get_prompt(_player) -> String:
	if GameState.data["door_open"]:
		return "ประตูเปิดแล้ว — ออกไปเลย!"
	return "กด E เพื่อใส่รหัสประตู"


func can_interact(_player) -> bool:
	return not GameState.data["door_open"]


func interact(_player = null):
	var hud := get_hud()
	if hud:
		hud.open_keypad(self)


## เรียกจาก HUD เมื่อกด "ตกลง"
func submit_code(code: String) -> bool:
	if code == GameState.code_string():
		Audio.play_sfx_3d("keypad_ok", global_position)
		open_door()
		return true
	Audio.play_sfx_3d("keypad_error", global_position, 4.0)
	NoiseBus.emit_noise(global_position, wrong_code_noise_radius, self)
	GameState.toast("รหัสผิด! เสียงเตือนดังไปทั้งตึก")
	return false


func open_door():
	GameState.data["door_open"] = true
	GameState.notify_progress()
	var door := get_node_or_null(door_path)
	if door and door.has_method("open"):
		door.open()
	GameState.show_subtitles([["กลอนประตูดีดออก... ลมหนาวพัดเข้ามา ออกไปเดี๋ยวนี้!", 4.0]])
