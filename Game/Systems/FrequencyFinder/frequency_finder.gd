extends Node
class_name FrequencyFinder
## เครื่องรับสัญญาณพกพา (Frequency Finder) — ลูกของผู้เล่น
## Tab/Q เปิด-ปิด · ล้อเมาส์ หรือ A/D (ตอนเปิดเครื่อง) จูน 88.0–108.0 MHz
## ใช้ได้จริงหลังคืนไฟให้สถานี (ปริศนาที่ 1) — ก่อนหน้านั้นมีแต่เสียงซ่า
## เข้าใกล้ FrequencySource + จูนตรง ค้างไว้ lock_time วินาที → เล่นคลื่น (subtitle) → ได้เลขรหัส 1 หลัก
## ระหว่างหมุนหาคลื่น ค่า noise ของผู้เล่นจะสูงขึ้น (get_noise_contribution)

signal toggled(is_on: bool)
## ส่งให้ HUD ทุกเฟรมตอนเปิดเครื่อง
signal display_changed(mhz: float, strength: float, status: String)

@export var min_mhz := 88.0
@export var max_mhz := 108.0
@export var wheel_step := 0.1
## MHz ต่อวินาทีตอนกด A/D ค้าง
@export var key_tune_rate := 1.6
@export var tolerance_mhz := 0.25
@export var lock_time := 1.5
## ช่วงความถี่รอบคลื่นที่เริ่มได้ยินแว่วๆ
@export var audible_band_mhz := 2.5
@export_group("Noise")
@export var noise_when_on := 0.1
@export var noise_per_tune := 0.35
@export var tuning_noise_decay := 0.8
@export var noise_while_receiving := 0.25

var is_on := false
var current_mhz := 95.0
var strength := 0.0
var receiving_index := -1
var _tuning_noise := 0.0
var _lock_timer := 0.0
var _receive_timer := 0.0
var _static: AudioStreamPlayer
var _transmission: AudioStreamPlayer


func _ready():
	_static = Audio.make_loop_player(self, "static_loop")
	_transmission = Audio.make_loop_player(self, "transmission_loop")


func _unhandled_input(event):
	if not GameState.is_playing() or GameState.modal_open:
		return
	if event.is_action_pressed("ToggleReceiver"):
		set_on(not is_on)
		get_viewport().set_input_as_handled()
		return
	if is_on and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			tune(wheel_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			tune(-wheel_step)


func _process(delta):
	_tuning_noise = maxf(_tuning_noise - tuning_noise_decay * delta, 0.0)
	if receiving_index >= 0:
		_process_receiving(delta)  # รับคลื่นต่อแม้ปิดเครื่องกลางทาง
		return
	if not is_on:
		return
	if not GameState.modal_open:
		var axis := Input.get_axis("moveLeft", "moveRight")
		if absf(axis) > 0.1:
			tune(axis * key_tune_rate * delta, false)
	_process_scanning(delta)


func set_on(value: bool):
	is_on = value
	_lock_timer = 0.0
	Audio.play_sfx("radio_click", -6.0)
	if is_on:
		_static.play()
	else:
		_static.stop()
		if receiving_index < 0:
			_transmission.stop()
	toggled.emit(is_on)


func tune(delta_mhz: float, from_wheel := true):
	if receiving_index >= 0:
		return  # กำลังรับคลื่น ล็อกหน้าปัดไว้
	var before := current_mhz
	current_mhz = clampf(snappedf(current_mhz + delta_mhz, 0.01), min_mhz, max_mhz)
	if not is_equal_approx(before, current_mhz):
		_tuning_noise = minf(_tuning_noise + (noise_per_tune if from_wheel else noise_per_tune * absf(delta_mhz) * 6.0), 0.6)


## ค่าเสียงที่เครื่องรับเพิ่มให้ผู้เล่น (0..1)
func get_noise_contribution() -> float:
	if receiving_index >= 0:
		return noise_while_receiving
	if not is_on:
		return 0.0
	return noise_when_on + _tuning_noise


func _process_scanning(delta: float):
	var status := ""
	strength = 0.0
	if not GameState.data.get("power_on", false):
		status = Story.NO_SIGNAL_HINT
	elif GameState.puzzle2_done():
		status = Story.ALL_FREQUENCIES_DONE
	else:
		var src := _nearest_source()
		if src == null:
			status = "ไม่มีสัญญาณในบริเวณนี้ — ลองไปห้องอื่น"
			_lock_timer = 0.0
		else:
			var d := _listener_pos().distance_to(src.global_position)
			var dist_factor := clampf(1.0 - d / src.range_m, 0.0, 1.0)
			var diff := absf(current_mhz - src.get_mhz())
			var tune_factor := clampf(1.0 - diff / audible_band_mhz, 0.0, 1.0)
			strength = clampf(0.25 * dist_factor + 0.75 * dist_factor * tune_factor, 0.0, 1.0)
			if diff <= tolerance_mhz:
				_lock_timer += delta
				status = "จับคลื่นได้แล้ว... ค้างไว้"
				if _lock_timer >= lock_time:
					_start_receiving(src)
					return
			else:
				_lock_timer = 0.0
				status = "ใกล้แล้ว... หมุนช้าๆ" if tune_factor > 0.6 else "มีสัญญาณบางอย่างอยู่ใกล้ๆ — หมุนหาคลื่น"
	_static.volume_db = linear_to_db(clampf(1.0 - strength * 0.85, 0.05, 1.0)) - 8.0
	display_changed.emit(current_mhz, strength, status)


func _start_receiving(src: FrequencySource):
	receiving_index = src.freq_index
	var lines: Array = Story.FREQUENCIES[receiving_index]["lines"]
	_receive_timer = 0.0
	for l in lines:
		_receive_timer += float(l[1])
	strength = 1.0
	Audio.play_sfx("radio_lock", -4.0)
	_transmission.play()
	_static.volume_db = -22.0
	GameState.toast(Story.FREQUENCIES[receiving_index]["title"])
	GameState.show_subtitles(lines)


func _process_receiving(delta: float):
	_receive_timer -= delta
	display_changed.emit(current_mhz, 1.0, "กำลังรับสัญญาณ...")
	if _receive_timer <= 0.0:
		_finish_receiving()


func _finish_receiving():
	var idx := receiving_index
	receiving_index = -1
	_transmission.stop()
	if not (idx in GameState.data["freqs_found"]):
		GameState.data["freqs_found"].append(idx)
	GameState.toast("ได้รหัสหลักที่ %d" % (idx + 1))
	GameState.notify_progress()
	GameState.save_checkpoint(get_parent() as Node3D)
	if not is_on:
		_static.stop()


## FrequencySource ที่ยังไม่ถูกจับ และผู้เล่นอยู่ในระยะ (ใกล้ที่สุด)
func _nearest_source() -> FrequencySource:
	var best: FrequencySource = null
	var best_d := INF
	var pos := _listener_pos()
	for node in get_tree().get_nodes_in_group("frequency_sources"):
		var s := node as FrequencySource
		if s == null or (s.freq_index in GameState.data["freqs_found"]):
			continue
		var d := pos.distance_to(s.global_position)
		if d < s.range_m and d < best_d:
			best = s
			best_d = d
	return best


func _listener_pos() -> Vector3:
	var p = get_parent()
	return p.global_position if p is Node3D else Vector3.ZERO
