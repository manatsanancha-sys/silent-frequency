class_name UiKit
## ตัวช่วยสร้าง UI ด้วยโค้ดให้หน้าตาเหมือนกันทุกหน้าจอ (ใช้ธีม main_theme.tres)

const THEME_PATH := "res://Game/UI/Theme/main_theme.tres"
const VHS_SHADER := "res://Game/UI/vhs.gdshader"


static func full_rect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


static func black_bg(alpha := 1.0) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, alpha)
	full_rect(bg)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	return bg


static func center() -> CenterContainer:
	var c := CenterContainer.new()
	full_rect(c)
	return c


static func vbox(separation := 14) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	return v


static func label(text: String, variation := "", align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	if variation != "":
		l.theme_type_variation = variation
	return l


static func button(text: String, callback: Callable, min_width := 320) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 48)
	b.pressed.connect(func(): Audio.play_sfx("ui_click", -6.0))
	b.pressed.connect(callback)
	return b


static func rich(bbcode: String, size := Vector2(760, 440)) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.text = bbcode
	r.custom_minimum_size = size
	r.scroll_active = true
	r.fit_content = false
	return r


static func panel(child: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_child(child)
	return p


## แถบปรับเสียงของ bus ("Music" / "SFX")
static func volume_row(title: String, bus: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := label(title, "", HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size = Vector2(140, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = Audio.get_bus_volume(bus)
	s.custom_minimum_size = Vector2(260, 32)
	s.value_changed.connect(func(v):
		Audio.set_bus_volume(bus, v)
		Audio.save_settings())
	row.add_child(s)
	return row


## เลเยอร์เอฟเฟกต์เทป VHS (scanline + grain + vignette + RGB split) — ใช้ได้ใน Compatibility renderer
## เป็น CanvasLayer แยก ให้ layer ต่ำกว่า UI เสมอ: shader อ่าน screen texture ตอนวาดเลเยอร์นี้
## ซึ่งตอนนั้นบนจอมีแค่ภาพ 3D → UI ที่วาดทีหลัง (layer สูงกว่า) จะคมชัด ไม่โดนเอฟเฟกต์
const VHS_LAYER := 5

static func vhs_layer(strength := 0.6) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "VhsLayer"
	layer.layer = VHS_LAYER
	var r := ColorRect.new()
	r.name = "Overlay"
	full_rect(r)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load(VHS_SHADER)
	m.set_shader_parameter("strength", strength)
	r.material = m
	layer.add_child(r)
	return layer


## ทำให้ปุ่มแรกที่ใช้ได้ได้ focus (เล่นด้วยคีย์บอร์ดได้)
static func focus_first(container: Node):
	for c in container.get_children():
		if c is Button and c.visible and not c.disabled:
			c.grab_focus()
			return
