extends Node
## Autoload "GameState" — สถานะเกม, ความคืบหน้าปริศนา, ไอเท็ม, checkpoint, เซฟ/โหลด
## ข้อมูลทั้งหมดของ "หนึ่งรอบการเล่น" อยู่ใน `data` (Dictionary) เพื่อให้เซฟ/โหลดได้ในก้อนเดียว
## เซฟด้วย ConfigFile ที่ user:// (บนเว็บ Godot เก็บใน IndexedDB ของเบราว์เซอร์ให้อัตโนมัติ)

signal state_changed(new_state: int)
signal progress_changed
signal item_changed
signal subtitle_requested(lines: Array)
signal toast_requested(text: String)

enum State { MENU, PLAYING, PAUSED, GAME_OVER, WIN }

const MAIN_MENU_SCENE := "res://Game/UI/Menus/main_menu.tscn"
const LEVEL_SCENE := "res://levels/radio_station.tscn"
const GAME_OVER_SCENE := "res://Game/UI/Menus/game_over.tscn"
const WIN_SCENE := "res://Game/UI/Menus/you_win.tscn"
const SAVE_VERSION := 1

var save_path := "user://savegame.cfg"
var state: int = State.MENU
var data: Dictionary = {}
## เหตุผลของ Game Over ล่าสุด: "caught" หรือ "dawn"
var game_over_reason := "caught"
## true = โหลดจากเซฟ/checkpoint (level จะวางผู้เล่นตามเซฟ), false = เกมใหม่
var loading_from_save := false
var debug_enemy_disabled := false
## true ระหว่างเปิดหน้าต่างซ้อน (อ่านบันทึก, แป้นรหัส) — เมนู pause จะไม่เปิดทับ
var modal_open := false
## เว็บ: ผู้เล่นคลิกหน้า "คลิกเพื่อเริ่ม" ไปแล้วในรอบนี้ (เบราว์เซอร์อนุญาตให้เล่นเสียงแล้ว)
var web_audio_unlocked := false


# ------------------------------------------------------------------ run data

func new_run_data(night_duration_sec: float = 900.0) -> Dictionary:
	var code := []
	for i in 4:
		code.append(randi_range(0, 9))
	return {
		"version": SAVE_VERSION,
		"code": code,
		"night_duration": night_duration_sec,
		"time_left": night_duration_sec,
		"items": [],            # เช่น "fuse"
		"taken": [],            # id ของไอเท็มในฉากที่เก็บไปแล้ว (แบต, ฟิวส์, บันทึก)
		"fuse_inserted": false,
		"power_on": false,
		"freqs_found": [],      # index ใน Story.FREQUENCIES
		"docs_found": [],       # index ใน Story.DOCUMENTS
		"tapes_played": [],     # index ใน Story.DOCUMENTS (เฉพาะ kind = tape)
		"door_open": false,
		"battery": 100.0,
		"spare_batteries": 0,
		"has_player_transform": false,
		"player_pos": Vector3.ZERO,
		"player_yaw": 0.0,
		"intro_shown": false,
	}


func start_new_game():
	data = new_run_data()
	loading_from_save = false
	debug_enemy_disabled = false
	_go_to_level()


func continue_game() -> bool:
	if not load_game():
		return false
	loading_from_save = true
	_go_to_level()
	return true


## Retry จากหน้า Game Over = โหลด checkpoint ล่าสุด (ถ้าไม่มีเซฟเลยจะเริ่มใหม่)
func retry_from_checkpoint():
	if not continue_game():
		start_new_game()


func go_to_main_menu():
	_set_state(State.MENU)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _go_to_level():
	get_tree().paused = false
	_set_state(State.PLAYING)
	get_tree().change_scene_to_file(LEVEL_SCENE)


func game_over(reason: String):
	if state != State.PLAYING:
		return
	game_over_reason = reason
	_set_state(State.GAME_OVER)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file.call_deferred(GAME_OVER_SCENE)


func win():
	if state != State.PLAYING:
		return
	_set_state(State.WIN)
	delete_save()  # จบเกมแล้ว ปุ่ม Continue จะถูกปิด
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file.call_deferred(WIN_SCENE)


func set_paused(value: bool):
	if value and state == State.PLAYING:
		_set_state(State.PAUSED)
		get_tree().paused = true
	elif not value and state == State.PAUSED:
		_set_state(State.PLAYING)
		get_tree().paused = false


func is_playing() -> bool:
	return state == State.PLAYING


func _set_state(s: int):
	state = s
	state_changed.emit(s)


## เวลาในเกม 02:00 → 06:00 ตามเวลาที่เหลือ
func clock_text() -> String:
	if data.is_empty():
		return "02:00"
	var duration: float = maxf(float(data["night_duration"]), 1.0)
	var progress := clampf(1.0 - float(data["time_left"]) / duration, 0.0, 1.0)
	var minutes := int(120.0 + progress * 240.0)
	return "%02d:%02d" % [minutes / 60, minutes % 60]


# ------------------------------------------------------------------ items / progress

func has_item(item: String) -> bool:
	return item in data.get("items", [])


func add_item(item: String):
	if not has_item(item):
		data["items"].append(item)
		item_changed.emit()


func remove_item(item: String):
	data["items"].erase(item)
	item_changed.emit()


func is_taken(id: String) -> bool:
	return id in data.get("taken", [])


func mark_taken(id: String):
	if not is_taken(id):
		data["taken"].append(id)


func code_digit(i: int) -> int:
	return int(data["code"][i])


func code_string() -> String:
	var s := ""
	for d in data["code"]:
		s += str(int(d))
	return s


## หลักที่ผู้เล่นรู้แล้ว — ใช้แสดงบน HUD เช่น "4 _ 7 _"
func known_digit(i: int) -> bool:
	if i < 3:
		return i in data["freqs_found"]
	return 3 in data["tapes_played"]


func known_code_display() -> String:
	var parts := []
	for i in 4:
		parts.append(str(code_digit(i)) if known_digit(i) else "_")
	return " ".join(parts)


func all_digits_known() -> bool:
	for i in 4:
		if not known_digit(i):
			return false
	return true


func puzzle1_done() -> bool:
	return data.get("power_on", false)


func puzzle2_done() -> bool:
	return data["freqs_found"].size() >= Story.FREQUENCIES.size()


func puzzle3_done() -> bool:
	if data["docs_found"].size() < Story.DOCUMENTS.size():
		return false
	for i in Story.DOCUMENTS.size():
		if Story.DOCUMENTS[i]["kind"] == "tape" and not (i in data["tapes_played"]):
			return false
	return true


## แทน {d1}..{d4} ด้วยเลขรหัสจริง
func format_story(text: String) -> String:
	for i in 4:
		text = text.replace("{d%d}" % (i + 1), str(code_digit(i)))
	return text


func format_lines(lines: Array) -> Array:
	var out := []
	for l in lines:
		out.append([format_story(l[0]), l[1]])
	return out


func show_subtitles(lines: Array):
	subtitle_requested.emit(format_lines(lines))


func toast(text: String):
	toast_requested.emit(text)


func notify_progress():
	progress_changed.emit()


## ข้อความเป้าหมายปัจจุบันบน HUD
func objective_text() -> String:
	if data.is_empty():
		return ""
	if data["door_open"]:
		return "ประตูเปิดแล้ว — ออกไปจากที่นี่!"
	if not data["fuse_inserted"]:
		if has_item("fuse"):
			return "นำฟิวส์ไปใส่ตู้ฟิวส์ในห้องเก็บของ"
		return "คืนไฟให้สถานี — หาฟิวส์ในห้องหัวหน้าสถานี"
	if not data["power_on"]:
		return "เปิดสวิตช์ไฟหลักในห้องรับสัญญาณ"
	if all_digits_known():
		return "ไปที่ประตูทางออกด้านหน้า แล้วใส่รหัส %s" % code_string()
	var parts := []
	if not puzzle2_done():
		parts.append("จูนหาคลื่นที่ซ่อนอยู่ (Tab) %d/3" % data["freqs_found"].size())
	if not puzzle3_done():
		parts.append("หาบันทึกและเทป %d/4" % data["docs_found"].size())
		if _has_unplayed_tape():
			parts.append("เปิดเทปที่เครื่องเล่นในห้องหัวหน้าสถานี")
	return "\n".join(parts)


func _has_unplayed_tape() -> bool:
	for i in data["docs_found"]:
		if Story.DOCUMENTS[i]["kind"] == "tape" and not (i in data["tapes_played"]):
			return true
	return false


# ------------------------------------------------------------------ save / load

func has_save() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var cfg := ConfigFile.new()
	return cfg.load(save_path) == OK and cfg.has_section_key("run", "data")


## เซฟ checkpoint — `player` ใช้เก็บตำแหน่ง/มุมกล้องผู้เล่น
func save_checkpoint(player: Node3D = null):
	if data.is_empty():
		return
	if player:
		data["has_player_transform"] = true
		data["player_pos"] = player.global_position
		data["player_yaw"] = player.rotation.y
	var cfg := ConfigFile.new()
	cfg.set_value("run", "data", data)
	cfg.set_value("run", "saved_at", Time.get_datetime_string_from_system())
	var err := cfg.save(save_path)
	if err != OK:
		push_warning("save failed: %s" % err)
	else:
		toast("บันทึกความคืบหน้าแล้ว")


func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK or not cfg.has_section_key("run", "data"):
		return false
	var loaded = cfg.get_value("run", "data")
	if typeof(loaded) != TYPE_DICTIONARY or int(loaded.get("version", 0)) != SAVE_VERSION:
		return false
	# เติม key ที่อาจไม่มีในเซฟเก่า
	var fresh := new_run_data()
	for k in fresh:
		if not loaded.has(k):
			loaded[k] = fresh[k]
	data = loaded
	return true


func delete_save():
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
