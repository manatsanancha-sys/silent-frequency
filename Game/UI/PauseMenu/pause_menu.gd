extends CanvasLayer
## เมนูหยุดเกม — autoload "PauseMenu" (ใช้ได้ทุกฉาก)
## กด Esc (action "ui_cancel") เพื่อเปิด/ปิด
## process_mode = ALWAYS เพื่อให้รับปุ่มได้ตอน get_tree().paused = true
## ตอน pause node อื่นๆ (ผู้เล่น ไฟฉาย ศัตรู inventory) ซึ่งเป็น PAUSABLE จะหยุด
## ทั้ง _process/_physics_process และ _input → กล้องไม่หมุน ตัวละครไม่เดิน

signal pause_changed(is_paused: bool)

@onready var resume_button: Button = %ResumeButton
@onready var quit_button: Button = %QuitButton

## โหมดเมาส์ก่อนเปิดเมนู (เช่น ถ้าเปิด inventory อยู่จะเป็น VISIBLE) — คืนค่านี้ตอนปิดเมนู
var _mouse_mode_before_pause := Input.MOUSE_MODE_CAPTURED


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(resume)
	quit_button.pressed.connect(quit_game)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			resume()
		else:
			pause()
		get_viewport().set_input_as_handled()


func pause():
	_mouse_mode_before_pause = Input.mouse_mode
	get_tree().paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()
	pause_changed.emit(true)


func resume():
	get_tree().paused = false
	visible = false
	# ถ้าก่อนหน้านี้เมาส์ถูกปล่อยอยู่แล้ว (เปิด inventory) ให้คงไว้ ไม่งั้นล็อกกลับ
	if _mouse_mode_before_pause == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pause_changed.emit(false)


func quit_game():
	get_tree().quit()
