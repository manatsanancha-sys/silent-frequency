extends Node
## ทดสอบ pause menu แบบอัตโนมัติ (รันได้ทั้งใน editor และ headless)
##   godot --headless --path . res://tests/pause_test.tscn
## จำลองการกด Esc, ขยับเมาส์ และกดเดิน แล้วเช็กว่าตอน pause กล้อง/ตัวละครไม่ขยับ

const LEVEL := preload("res://levels/radio_station.tscn")

var failures := 0


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# ต้องแปะฉากไว้ใต้ root (ไม่ใช่ลูกของ node เทสนี้) ไม่งั้นจะสืบทอด PROCESS_MODE_ALWAYS ไปด้วย
	get_tree().root.add_child.call_deferred(LEVEL.instantiate())
	await _frames(60)  # ให้ผู้เล่นตกถึงพื้นก่อน

	var player: CharacterBody3D = get_tree().get_first_node_in_group("player")
	var camera: Camera3D = player.get_node("PlayerController").camera

	# --- เปิดเมนู
	_press_action("ui_cancel")
	await _frames(2)
	check(get_tree().paused, "Esc -> tree paused")
	check(PauseMenu.visible, "Esc -> menu visible")
	check(PauseMenu.resume_button.has_focus(), "Resume button focused")

	# --- ระหว่าง pause: ขยับเมาส์ + กดเดิน ต้องไม่มีผล
	var yaw := player.rotation.y
	var pitch := camera.rotation.x
	var pos := player.global_position
	_mouse_move(Vector2(300, 150))
	Input.action_press("moveUp")
	await _frames(30)
	Input.action_release("moveUp")
	check(is_equal_approx(player.rotation.y, yaw), "paused: player yaw unchanged")
	check(is_equal_approx(camera.rotation.x, pitch), "paused: camera pitch unchanged")
	check(player.global_position.distance_to(pos) < 0.001, "paused: player did not move")

	# --- ปิดเมนูด้วย Esc
	_press_action("ui_cancel")
	await _frames(2)
	check(not get_tree().paused, "Esc again -> unpaused")
	check(not PauseMenu.visible, "Esc again -> menu hidden")

	# --- หลัง resume: การควบคุมต้องกลับมาทำงาน (พิสูจน์ว่าเทสจับการเปลี่ยนแปลงได้จริง)
	yaw = player.rotation.y
	pos = player.global_position
	_mouse_move(Vector2(300, 0))
	Input.action_press("moveUp")
	await _frames(30)
	Input.action_release("moveUp")
	check(not is_equal_approx(player.rotation.y, yaw), "resumed: mouse look works")
	check(player.global_position.distance_to(pos) > 0.1, "resumed: movement works")

	# --- ปุ่ม Resume บนเมนูก็ปิดได้
	PauseMenu.pause()
	PauseMenu.resume_button.pressed.emit()
	check(not get_tree().paused and not PauseMenu.visible, "Resume button unpauses")

	print("PAUSE TEST: %s (%d failure(s))" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures else 0)


func check(cond: bool, label: String):
	print(("  ok   " if cond else "  FAIL ") + label)
	if not cond:
		failures += 1


func _press_action(action: String):
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func _mouse_move(relative: Vector2):
	var ev := InputEventMouseMotion.new()
	ev.relative = relative
	Input.parse_input_event(ev)


func _frames(n: int):
	for i in n:
		await get_tree().physics_frame
