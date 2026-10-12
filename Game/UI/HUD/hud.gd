extends CanvasLayer
## HUD ของด่าน — สร้างด้วยโค้ดทั้งหมด (ใช้ธีมหลัก)
## นาฬิกา · เป้าหมาย · รหัสที่รู้ · แบตไฟฉาย · ระดับเสียง · ข้อความบอกปุ่ม · subtitle · toast
## หน้าต่างเครื่องรับสัญญาณ · แถบดำตอนซ่อน · หน้าอ่านบันทึก · แป้นรหัส · VHS overlay

var player: Player3D

var _root: Control
var _clock: Label
var _objective: Label
var _code: Label
var _battery_bar: ProgressBar
var _battery_label: Label
var _noise_bar: ProgressBar
var _prompt: Label
var _subtitle: Label
var _toast: Label
var _mouse_hint: Label
var _receiver_panel: PanelContainer
var _freq_label: Label
var _strength_bar: ProgressBar
var _receiver_status: Label
var _hide_overlay: Control
var _note_panel: Control
var _note_title: Label
var _note_text: RichTextLabel
var _keypad_panel: Control
var _keypad_display: Label
var _keypad_entry := ""
var _keypad_target: Node = null
var _vhs: ColorRect

var _sub_queue: Array = []
var _sub_timer := 0.0
var _toast_tween: Tween


func _ready():
	add_to_group("hud")
	layer = 10
	_root = Control.new()
	_root.theme = load(UiKit.THEME_PATH)
	UiKit.full_rect(_root)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_hide_overlay()
	_build_top()
	_build_bottom_left()
	_build_center()
	_build_receiver()
	_build_note()
	_build_keypad()
	_vhs = UiKit.vhs_overlay(0.9)
	_root.add_child(_vhs)
	GameState.subtitle_requested.connect(queue_subtitles)
	GameState.toast_requested.connect(show_toast)
	GameState.progress_changed.connect(refresh_progress)
	GameState.item_changed.connect(refresh_progress)
	refresh_progress()


func bind_player(p: Player3D):
	player = p
	p.battery_changed.connect(_on_battery)
	p.noise_changed.connect(func(n): _noise_bar.value = n * 100.0)
	p.interactable_changed.connect(func(t): _prompt.text = t)
	p.hidden_changed.connect(func(h): _hide_overlay.visible = h)
	p.finder.toggled.connect(func(on): _receiver_panel.visible = on)
	p.finder.display_changed.connect(_on_receiver_display)


# ------------------------------------------------------------------ build

func _anchor(c: Control, preset: int, margin := Vector2(24, 20)) -> Control:
	c.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE)
	match preset:
		Control.PRESET_TOP_LEFT:
			c.position += margin
		Control.PRESET_TOP_RIGHT:
			c.position += Vector2(-margin.x, margin.y)
		Control.PRESET_BOTTOM_LEFT:
			c.position += Vector2(margin.x, -margin.y)
		Control.PRESET_BOTTOM_RIGHT:
			c.position += Vector2(-margin.x, -margin.y)
	return c


func _hud_label(text := "", size := 20) -> Label:
	var l := UiKit.label(text, "HudLabel", HORIZONTAL_ALIGNMENT_LEFT)
	l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_top():
	var tl := VBoxContainer.new()
	tl.position = Vector2(24, 18)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock = _hud_label("02:00", 34)
	tl.add_child(_clock)
	_objective = _hud_label("", 19)
	_objective.custom_minimum_size = Vector2(560, 0)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.add_child(_objective)
	_root.add_child(tl)

	_code = _hud_label("รหัสประตู  _ _ _ _", 24)
	_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_code.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_code.offset_left = -360
	_code.offset_right = -24
	_code.offset_top = 22
	_root.add_child(_code)

	_toast = _hud_label("", 22)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -400
	_toast.offset_right = 400
	_toast.offset_top = 90
	_toast.modulate.a = 0.0
	_root.add_child(_toast)


func _build_bottom_left():
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	box.offset_left = 24
	box.offset_top = -110
	box.offset_bottom = -20
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_battery_label = _hud_label("ไฟฉาย  สำรอง 0", 18)
	box.add_child(_battery_label)
	_battery_bar = ProgressBar.new()
	_battery_bar.custom_minimum_size = Vector2(220, 14)
	_battery_bar.show_percentage = false
	_battery_bar.value = 100
	box.add_child(_battery_bar)
	box.add_child(_hud_label("เสียงของคุณ", 18))
	_noise_bar = ProgressBar.new()
	_noise_bar.custom_minimum_size = Vector2(220, 10)
	_noise_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.7, 0.18, 0.12)
	_noise_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_noise_bar)
	_root.add_child(box)


func _build_center():
	var dot := ColorRect.new()
	dot.color = Color(1, 1, 1, 0.6)
	dot.size = Vector2(4, 4)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.position = -dot.size / 2
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dot)

	_prompt = _hud_label("", 22)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_prompt.offset_left = -450
	_prompt.offset_right = 450
	_prompt.offset_top = 40
	_prompt.offset_bottom = 80
	_root.add_child(_prompt)

	_subtitle = UiKit.label("", "SubtitleLabel")
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitle.offset_left = -520
	_subtitle.offset_right = 520
	_subtitle.offset_top = -170
	_subtitle.offset_bottom = -90
	_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_subtitle)

	_mouse_hint = _hud_label("คลิกเพื่อควบคุมกล้อง", 24)
	_mouse_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mouse_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_mouse_hint.offset_left = -300
	_mouse_hint.offset_right = 300
	_mouse_hint.offset_top = -80
	_mouse_hint.visible = false
	_root.add_child(_mouse_hint)


func _build_receiver():
	_receiver_panel = PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var title := _hud_label("เครื่องรับสัญญาณ", 18)
	v.add_child(title)
	_freq_label = _hud_label("95.0 MHz", 40)
	_freq_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.2))
	v.add_child(_freq_label)
	_strength_bar = ProgressBar.new()
	_strength_bar.custom_minimum_size = Vector2(300, 12)
	_strength_bar.show_percentage = false
	v.add_child(_strength_bar)
	_receiver_status = _hud_label("", 17)
	_receiver_status.custom_minimum_size = Vector2(300, 0)
	_receiver_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_receiver_status)
	v.add_child(_hud_label("ล้อเมาส์ / A D = จูน   ·   Tab / Q = ปิด", 15))
	_receiver_panel.add_child(v)
	_receiver_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE)
	_receiver_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_receiver_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_receiver_panel.offset_right = -24
	_receiver_panel.offset_bottom = -20
	_receiver_panel.visible = false
	_receiver_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_receiver_panel)


func _build_hide_overlay():
	_hide_overlay = Control.new()
	UiKit.full_rect(_hide_overlay)
	_hide_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# มองผ่านช่องแคบๆ ของตู้
	for side in [0, 1]:
		var bar := ColorRect.new()
		bar.color = Color(0, 0, 0, 0.97)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.anchor_left = 0.0
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if side == 0 else 0.58
		bar.anchor_bottom = 0.42 if side == 0 else 1.0
		_hide_overlay.add_child(bar)
	for x in [0.0, 0.88]:
		var bar := ColorRect.new()
		bar.color = Color(0, 0, 0, 0.97)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.anchor_left = x
		bar.anchor_right = x + 0.12
		bar.anchor_top = 0.0
		bar.anchor_bottom = 1.0
		_hide_overlay.add_child(bar)
	var hint := _hud_label("กำลังซ่อนตัว — อยู่นิ่งๆ", 20)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.offset_left = -300
	hint.offset_right = 300
	hint.offset_top = 150
	_hide_overlay.add_child(hint)
	_hide_overlay.visible = false
	_root.add_child(_hide_overlay)


func _build_note():
	_note_panel = UiKit.center()
	_note_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := UiKit.black_bg(0.6)
	_note_panel.add_child(dim)
	var paper := PanelContainer.new()
	paper.theme_type_variation = "NotePanel"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_note_title = Label.new()
	_note_title.add_theme_font_override("font", load("res://assets/fonts/Mali-Regular.ttf"))
	_note_title.add_theme_font_size_override("font_size", 30)
	_note_title.add_theme_color_override("font_color", Color(0.3, 0.08, 0.05))
	v.add_child(_note_title)
	_note_text = RichTextLabel.new()
	_note_text.theme_type_variation = "NoteLabel"
	_note_text.custom_minimum_size = Vector2(680, 0)
	_note_text.fit_content = true
	_note_text.scroll_active = false
	v.add_child(_note_text)
	var close := Label.new()
	close.text = "กด E หรือ Esc เพื่อปิด"
	close.add_theme_color_override("font_color", Color(0.3, 0.25, 0.18))
	close.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(close)
	paper.add_child(v)
	_note_panel.add_child(paper)
	_note_panel.visible = false
	_root.add_child(_note_panel)


func _build_keypad():
	_keypad_panel = UiKit.center()
	_keypad_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_keypad_panel.add_child(UiKit.black_bg(0.6))
	var v := UiKit.vbox(12)
	v.add_child(UiKit.label("แป้นรหัสประตูหน้า", "HeaderLabel"))
	_keypad_display = UiKit.label("_ _ _ _", "TitleLabel")
	_keypad_display.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	v.add_child(_keypad_display)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for k in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "ลบ", "0", "ตกลง"]:
		var b := UiKit.button(k, _on_keypad_key.bind(k), 96)
		b.custom_minimum_size = Vector2(96, 64)
		grid.add_child(b)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(grid)
	v.add_child(UiKit.label("พิมพ์ตัวเลขได้ · Enter = ตกลง · Esc = ปิด"))
	_keypad_panel.add_child(UiKit.panel(v))
	_keypad_panel.visible = false
	_root.add_child(_keypad_panel)


# ------------------------------------------------------------------ updates

func _process(delta):
	_clock.text = GameState.clock_text()
	var low_time := float(GameState.data.get("time_left", 999.0)) < 120.0
	_clock.add_theme_color_override("font_color", Color(0.9, 0.3, 0.2) if low_time else Color(0.9, 0.86, 0.75))
	_mouse_hint.visible = GameState.is_playing() and not GameState.modal_open and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	_update_subtitles(delta)


func refresh_progress():
	if GameState.data.is_empty():
		return
	_objective.text = GameState.objective_text()
	_code.text = "รหัสประตู  " + GameState.known_code_display()


func _on_battery(percent: float, spares: int):
	_battery_bar.value = percent
	_battery_label.text = "ไฟฉาย %d%%   สำรอง %d" % [int(percent), spares]


func _on_receiver_display(mhz: float, strength: float, status: String):
	_freq_label.text = "%.1f MHz" % mhz
	_strength_bar.value = strength * 100.0
	_receiver_status.text = status


## ความบิดเบี้ยวของภาพ VHS (0..1) — station.gd ตั้งตามระยะศัตรู
func set_distortion(amount: float):
	(_vhs.material as ShaderMaterial).set_shader_parameter("distortion", amount)


# ------------------------------------------------------------------ subtitles / toast

func queue_subtitles(lines: Array):
	# คลื่น/เทปใหม่แทนที่ของเก่าเสมอ
	_sub_queue = lines.duplicate()
	_sub_timer = 0.0
	_subtitle.text = ""


func _update_subtitles(delta: float):
	if _sub_timer > 0.0:
		_sub_timer -= delta
		if _sub_timer <= 0.0:
			_subtitle.text = ""
	if _sub_timer <= 0.0 and not _sub_queue.is_empty():
		var line: Array = _sub_queue.pop_front()
		_subtitle.text = line[0]
		_sub_timer = float(line[1])


func show_toast(text: String):
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.8)


# ------------------------------------------------------------------ modal windows

func show_note(title: String, text: String):
	_note_title.text = title
	_note_text.text = text
	_note_panel.visible = true
	_set_modal(true)


func open_keypad(target: Node):
	_keypad_target = target
	_keypad_entry = ""
	_update_keypad()
	_keypad_panel.visible = true
	_set_modal(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func is_modal_open() -> bool:
	return _note_panel.visible or _keypad_panel.visible


func close_modal():
	_note_panel.visible = false
	_keypad_panel.visible = false
	_keypad_target = null
	_set_modal(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _set_modal(on: bool):
	GameState.modal_open = on


func _on_keypad_key(k: String):
	if k == "ลบ":
		_keypad_entry = _keypad_entry.substr(0, maxi(_keypad_entry.length() - 1, 0))
		Audio.play_sfx("keypad_beep", -8.0, 0.8)
	elif k == "ตกลง":
		_submit_keypad()
		return
	elif _keypad_entry.length() < 4:
		_keypad_entry += k
		Audio.play_sfx("keypad_beep", -8.0)
	_update_keypad()


func _update_keypad():
	var shown := []
	for i in 4:
		shown.append(_keypad_entry[i] if i < _keypad_entry.length() else "_")
	_keypad_display.text = " ".join(shown)


func _submit_keypad():
	if _keypad_target == null:
		return
	if _keypad_entry.length() < 4:
		GameState.toast("ใส่ให้ครบ 4 หลัก")
		return
	var target := _keypad_target
	if target.submit_code(_keypad_entry):
		close_modal()
	else:
		_keypad_entry = ""
		_update_keypad()


func _input(event):
	if not is_modal_open():
		return
	if event.is_action_pressed("ui_cancel") or (_note_panel.visible and event.is_action_pressed("Interact")):
		close_modal()
		get_viewport().set_input_as_handled()
		return
	if _keypad_panel.visible and event is InputEventKey and event.pressed and not event.echo:
		var kc: int = event.keycode
		if kc >= KEY_0 and kc <= KEY_9:
			_on_keypad_key(str(kc - KEY_0))
		elif kc >= KEY_KP_0 and kc <= KEY_KP_9:
			_on_keypad_key(str(kc - KEY_KP_0))
		elif kc == KEY_BACKSPACE:
			_on_keypad_key("ลบ")
		elif kc == KEY_ENTER or kc == KEY_KP_ENTER:
			_submit_keypad()
		get_viewport().set_input_as_handled()
