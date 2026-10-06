extends Node
class_name FrequencyFinder
## Frequency Finder — เครื่องรับวิทยุพกพาของผู้เล่น (PLACEHOLDER)
##
## ไอเดียกลไก:
## 1. กด F เปิด/ปิดเครื่อง (action "ToggleFrequencyFinder")
## 2. หมุนล้อเมาส์ (ตอนเปิดเครื่อง) เพื่อจูนความถี่ 88.0–108.0 MHz
## 3. ความแรงสัญญาณ = ใกล้แหล่ง (ระยะ) x จูนตรง (ความต่างความถี่) → เสียงซ่าลดลง เสียงพูดชัดขึ้น
## 4. จูนตรง + อยู่ในระยะ ค้างไว้ lock_time วินาที → FrequencySource.on_tuned_in()
## 5. เปิดเครื่องแล้วมีเสียงซ่า → ส่งเสียงให้ศัตรูได้ยินผ่าน NoiseBus (ความเสี่ยงของผู้เล่น)
##
## ใส่เป็นลูกของผู้เล่น (ดู levels/radio_station.tscn)

signal signal_strength_changed(strength: float)
signal toggled(is_on: bool)

@export var min_mhz := 88.0
@export var max_mhz := 108.0
@export var tune_step := 0.2
## ความต่างความถี่ที่ยังนับว่า "ตรง"
@export var tolerance_mhz := 0.4
@export var lock_time := 2.0
## รัศมีเสียงซ่าที่ศัตรูได้ยินตอนเปิดเครื่อง
@export var static_noise_radius := 6.0

var is_on := false
var current_mhz := 98.0
var signal_strength := 0.0
var _lock_timer := 0.0


func _input(event):
	if event.is_action_pressed("ToggleFrequencyFinder"):
		set_on(not is_on)
	if not is_on:
		return
	# TODO: ตอนนี้ล้อเมาส์ชนกับ zoom เดิมของ camcorder ไม่ได้ (ไฟฉายไม่ใช้ zoom แล้ว)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			tune(tune_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			tune(-tune_step)


func _process(delta):
	if not is_on:
		return
	var best := find_strongest_source()
	update_signal_strength(best)
	update_lock(best, delta)
	# TODO: ส่ง NoiseBus.emit_noise(...) เป็นช่วงๆ ตามความดังของเสียงซ่า


func set_on(value: bool):
	is_on = value
	_lock_timer = 0.0
	toggled.emit(is_on)
	# TODO: แสดง/ซ่อน UI หน้าปัดวิทยุ, เล่น/หยุดเสียงซ่า (AudioStreamPlayer)


func tune(delta_mhz: float):
	current_mhz = clamp(current_mhz + delta_mhz, min_mhz, max_mhz)
	# TODO: อัปเดตตัวเลขบนหน้าปัด


## คืน FrequencySource ที่อยู่ในระยะและยังไม่ถูกเจอ ที่ใกล้ที่สุด
func find_strongest_source() -> FrequencySource:
	var listener := _get_listener_position()
	var best: FrequencySource = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("frequency_sources"):
		var source := node as FrequencySource
		if source == null or source.found:
			continue
		var d := listener.distance_to(source.global_position)
		if d < source.range_m and d < best_distance:
			best = source
			best_distance = d
	return best


## 0..1 — TODO: ปรับสูตรให้สนุก, ส่งค่าไปคุมเสียงซ่า/เสียงพูด
func update_signal_strength(source: FrequencySource):
	var strength := 0.0
	if source:
		var distance_factor := 1.0 - _get_listener_position().distance_to(source.global_position) / source.range_m
		var tune_factor := 1.0 - clampf(absf(current_mhz - source.frequency_mhz) / 3.0, 0.0, 1.0)
		strength = distance_factor * tune_factor
	if not is_equal_approx(strength, signal_strength):
		signal_strength = strength
		signal_strength_changed.emit(signal_strength)


func update_lock(source: FrequencySource, delta: float):
	if source and abs(current_mhz - source.frequency_mhz) <= tolerance_mhz:
		_lock_timer += delta
		if _lock_timer >= lock_time:
			source.on_tuned_in()
			_lock_timer = 0.0
	else:
		_lock_timer = 0.0


func _get_listener_position() -> Vector3:
	var parent = get_parent()
	if parent is Node3D:
		return parent.global_position
	return Vector3.ZERO
