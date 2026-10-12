extends Control
## หน้าจบ — ใช้ร่วมกันระหว่าง Game Over และ You Win (เลือกด้วย is_win)

@export var is_win := false


func _ready():
	theme = load(UiKit.THEME_PATH)
	UiKit.full_rect(self)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.stop_music()
	add_child(UiKit.black_bg())
	var c := UiKit.center()
	var v := UiKit.vbox(18)
	c.add_child(v)

	var title_text: String
	var body: String
	if is_win:
		title_text = "รอดแล้ว"
		body = Story.ENDING_WIN
		Audio.play_sfx("win_sting")
	else:
		title_text = "จบเกม"
		body = Story.ENDING_DAWN if GameState.game_over_reason == "dawn" else Story.ENDING_CAUGHT
		Audio.play_sfx("gameover_sting")
	var title := UiKit.label(title_text, "TitleLabel")
	if is_win:
		title.add_theme_color_override("font_color", Color(0.85, 0.78, 0.6))
	v.add_child(title)
	var text := UiKit.label(body)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(720, 0)
	v.add_child(text)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	v.add_child(spacer)
	var buttons := UiKit.vbox(10)
	if is_win:
		buttons.add_child(UiKit.button("เล่นอีกครั้ง", GameState.start_new_game))
	else:
		var retry_text := "ลองใหม่จากจุดบันทึกล่าสุด" if GameState.has_save() else "ลองใหม่"
		buttons.add_child(UiKit.button(retry_text, GameState.retry_from_checkpoint))
	buttons.add_child(UiKit.button("กลับเมนูหลัก", GameState.go_to_main_menu))
	v.add_child(buttons)
	add_child(c)
	add_child(UiKit.vhs_overlay(1.4))
	# เฟดเข้า
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 1.2)
	UiKit.focus_first(buttons)
