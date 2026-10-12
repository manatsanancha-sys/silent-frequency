extends CanvasLayer
## Autoload "PauseMenu" — กด Esc (ui_cancel) เปิด/ปิด ระหว่างเล่นเท่านั้น
## process_mode = ALWAYS เพื่อให้รับปุ่มได้ตอน get_tree().paused = true
## node อื่นในฉาก (PAUSABLE) จะหยุดทั้ง _process/_physics_process/_input → กล้องไม่หมุน ตัวละครไม่เดิน
## ถ้ามีหน้าต่างซ้อน (อ่านบันทึก/แป้นรหัส) เปิดอยู่ หน้าต่างนั้นจะใช้ Esc ปิดตัวเองก่อน

signal pause_changed(is_paused: bool)

var resume_button: Button
var _root: Control
var _buttons: VBoxContainer
## กันไม่ให้ Esc ที่ใช้ปิดเมนูไปเปิดซ้ำในเฟรมเดียวกัน
var _last_toggle_frame := -1


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_root = Control.new()
	_root.theme = load(UiKit.THEME_PATH)
	UiKit.full_rect(_root)
	add_child(_root)
	_root.add_child(UiKit.black_bg(0.75))
	var c := UiKit.center()
	var v := UiKit.vbox(14)
	c.add_child(v)
	v.add_child(UiKit.label("หยุดชั่วคราว", "TitleLabel"))
	var clock := UiKit.label("")
	clock.name = "Clock"
	v.add_child(clock)
	_buttons = UiKit.vbox(10)
	resume_button = UiKit.button("เล่นต่อ (Esc)", resume)
	_buttons.add_child(resume_button)
	_buttons.add_child(UiKit.button("กลับเมนูหลัก", _back_to_menu))
	v.add_child(_buttons)
	var vol := UiKit.vbox(8)
	vol.add_child(UiKit.volume_row("เพลง/บรรยากาศ", "Music"))
	vol.add_child(UiKit.volume_row("เอฟเฟกต์", "SFX"))
	v.add_child(UiKit.panel(vol))
	v.add_child(UiKit.label("ความคืบหน้าจะถูกบันทึกอัตโนมัติเมื่อแก้ปริศนาแต่ละขั้น"))
	_root.add_child(c)
	visible = false


func _input(event):
	if not event.is_action_pressed("ui_cancel"):
		return
	if GameState.state == GameState.State.PAUSED:
		resume()
		get_viewport().set_input_as_handled()
	elif GameState.state == GameState.State.PLAYING and not GameState.modal_open:
		pause()
		get_viewport().set_input_as_handled()


func pause():
	if GameState.state != GameState.State.PLAYING or _last_toggle_frame == Engine.get_process_frames():
		return
	_last_toggle_frame = Engine.get_process_frames()
	GameState.set_paused(true)
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var clock: Label = _root.find_child("Clock", true, false)
	clock.text = "เวลาในเกม %s" % GameState.clock_text()
	resume_button.grab_focus()
	pause_changed.emit(true)


func resume():
	if GameState.state != GameState.State.PAUSED or _last_toggle_frame == Engine.get_process_frames():
		return
	_last_toggle_frame = Engine.get_process_frames()
	GameState.set_paused(false)
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pause_changed.emit(false)


func _back_to_menu():
	visible = false
	GameState.go_to_main_menu()
