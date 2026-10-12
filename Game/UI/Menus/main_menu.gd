extends Control
## เมนูหลัก (ฉากแรกของเกม) — Play / Continue / How to Play / ตั้งค่าเสียง / Credits / Quit
## บนเว็บ: แสดงหน้า "คลิกเพื่อเริ่ม" ก่อน เพราะเบราว์เซอร์ต้องการ user gesture ก่อนเล่นเสียง

const CREDITS := """[center][b]สัญญาณจากความเงียบ (The Silent Frequency)[/b]
งานวิชา Computer Game Development

[b]พัฒนาบนพื้นฐานของ[/b]
horror-fps-template โดย Thiago Santana (ThiDiamondDev)
MIT License — github.com/ThiDiamondDev/horror-fps-template

[b]ฟอนต์ (SIL Open Font License 1.1)[/b]
Sarabun — The Sarabun Project Authors / Cadson Demak
Trirong — Cadson Demak
Mali — The Mali Project Authors / Cadson Demak (หน้าบันทึกลายมือ)

[b]เสียง[/b]
เสียงทั้งหมดสร้างแบบ procedural ด้วยสคริปต์ Python (tools/gen_audio.py)
ไม่มีเสียงพากย์ — เป็นเสียง static / ambient + คำบรรยาย

[b]เอนจิน[/b]
Godot Engine — MIT License — godotengine.org

[b]โมเดล 3D[/b]
ฉากทั้งหมดเป็นรูปทรงพื้นฐาน (greybox) สร้างในเกม[/center]"""

var _pages := {}
var _main_buttons: VBoxContainer
var _continue_button: Button


func _ready():
	GameState.state = GameState.State.MENU
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = load(UiKit.THEME_PATH)
	UiKit.full_rect(self)
	add_child(UiKit.black_bg())
	_build_main()
	_build_text_page("how", "วิธีเล่น", Story.HOW_TO_PLAY)
	_build_text_page("credits", "เครดิต", CREDITS)
	_build_settings()
	add_child(UiKit.vhs_overlay(1.2))
	show_page("main")
	if OS.has_feature("web"):
		_build_click_to_start()
	else:
		Audio.play_music("ambient_drone", -6.0)


func _build_main():
	var page := UiKit.center()
	var v := UiKit.vbox(12)
	page.add_child(v)
	var title := UiKit.label("สัญญาณจากความเงียบ", "TitleLabel")
	v.add_child(title)
	var sub := UiKit.label("T H E   S I L E N T   F R E Q U E N C Y")
	sub.add_theme_color_override("font_color", Color(0.55, 0.5, 0.42))
	v.add_child(sub)
	v.add_child(UiKit.label("สถานีวิทยุเขาเงียบ · ตุลาคม 2541"))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	v.add_child(spacer)
	_main_buttons = UiKit.vbox(10)
	v.add_child(_main_buttons)
	_main_buttons.add_child(UiKit.button("เล่นใหม่", GameState.start_new_game))
	_continue_button = UiKit.button("เล่นต่อ", _on_continue)
	_continue_button.disabled = not GameState.has_save()
	_main_buttons.add_child(_continue_button)
	_main_buttons.add_child(UiKit.button("วิธีเล่น", show_page.bind("how")))
	_main_buttons.add_child(UiKit.button("ตั้งค่าเสียง", show_page.bind("settings")))
	_main_buttons.add_child(UiKit.button("เครดิต", show_page.bind("credits")))
	var quit := UiKit.button("ออกจากเกม", get_tree().quit)
	quit.visible = not OS.has_feature("web")
	_main_buttons.add_child(quit)
	add_child(page)
	_pages["main"] = page
	# ไตเติลกะพริบเป็นระยะ
	var tw := create_tween().set_loops()
	tw.tween_interval(3.0)
	tw.tween_property(title, "modulate:a", 0.3, 0.05)
	tw.tween_property(title, "modulate:a", 1.0, 0.08)
	tw.tween_property(title, "modulate:a", 0.5, 0.04)
	tw.tween_property(title, "modulate:a", 1.0, 0.1)


func _build_text_page(page_name: String, title: String, bbcode: String):
	var page := UiKit.center()
	var v := UiKit.vbox(16)
	v.add_child(UiKit.label(title, "HeaderLabel"))
	v.add_child(UiKit.panel(UiKit.rich(bbcode, Vector2(820, 470))))
	var back := UiKit.button("กลับ", show_page.bind("main"), 220)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(back)
	page.add_child(v)
	add_child(page)
	_pages[page_name] = page


func _build_settings():
	var page := UiKit.center()
	var v := UiKit.vbox(18)
	v.add_child(UiKit.label("ตั้งค่าเสียง", "HeaderLabel"))
	var inner := UiKit.vbox(14)
	inner.add_child(UiKit.volume_row("เพลง/บรรยากาศ", "Music"))
	inner.add_child(UiKit.volume_row("เอฟเฟกต์", "SFX"))
	v.add_child(UiKit.panel(inner))
	var back := UiKit.button("กลับ", show_page.bind("main"), 220)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(back)
	page.add_child(v)
	add_child(page)
	_pages["settings"] = page


func _build_click_to_start():
	var overlay := Button.new()
	overlay.flat = true
	UiKit.full_rect(overlay)
	var bg := UiKit.black_bg()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)
	var c := UiKit.center()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := UiKit.vbox(10)
	v.add_child(UiKit.label("สัญญาณจากความเงียบ", "TitleLabel"))
	v.add_child(UiKit.label("คลิกเพื่อเริ่ม", "HeaderLabel"))
	v.add_child(UiKit.label("แนะนำให้ใส่หูฟัง"))
	c.add_child(v)
	overlay.add_child(c)
	overlay.pressed.connect(func():
		Audio.play_music("ambient_drone", -6.0)
		overlay.queue_free()
		UiKit.focus_first(_main_buttons))
	add_child(overlay)


func show_page(page_name: String):
	for k in _pages:
		_pages[k].visible = (k == page_name)
	if page_name == "main":
		UiKit.focus_first(_main_buttons)


func _on_continue():
	if not GameState.continue_game():
		_continue_button.disabled = true
		GameState.toast("ไม่พบเซฟ")


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and not _pages["main"].visible:
		show_page("main")
		get_viewport().set_input_as_handled()
