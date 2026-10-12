extends CharacterBody3D
class_name Player3D
## ผู้เล่น "ภานุ" — เดิน/วิ่ง/ย่อ, ค่าเสียง (noise level), ไฟฉายแบตจำกัด, ซ่อนตัว, โต้ตอบ
## ไฟฉายดัดแปลงแนวคิดจาก Game/Player/Flashlight/flashlight.gd (ซึ่งดัดแปลงจาก camcorder ของ template อีกที)

signal noise_changed(level: float)
signal battery_changed(percent: float, spares: int)
signal interactable_changed(prompt: String)
signal hidden_changed(is_hidden: bool)

@export_group("Movement")
@export var walk_speed := 3.0
@export var run_speed := 5.6
@export var crouch_speed := 1.6
@export var acceleration := 12.0
@export var mouse_sensitivity := 0.0025
@export var stand_eye_height := 1.6
@export var crouch_eye_height := 0.95

@export_group("Noise (0..1)")
## ค่าเสียงแต่ละท่า — ศัตรูได้ยินในรัศมี noise_level x hearing_range ของศัตรู
@export var noise_idle := 0.0
@export var noise_crouch := 0.12
@export var noise_walk := 0.4
@export var noise_run := 1.0
@export var noise_smoothing := 6.0

@export_group("Flashlight")
## วินาทีที่แบต 1 ก้อนใช้ได้
@export var flashlight_duration_sec := 150.0
@export var flashlight_energy := 2.6
@export var low_battery_percent := 20.0
@export var max_spare_batteries := 4

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var finder: FrequencyFinder = $FrequencyFinder

var noise_level := 0.0
var is_running := false
var is_crouching := false
var is_hidden := false
var hiding_spot: Node = null
var flashlight_on := true
## เพิ่มเมื่อศัตรูอยู่ใกล้ (0..1) ไฟฉายจะกะพริบ — ตั้งค่าจาก station.gd
var flicker_amount := 0.0
var current_interactable: Node = null
var input_locked := false

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _step_timer := 0.0
var _had_capture := false
var _last_prompt := ""


func _ready():
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	ray.collision_mask = 8
	ray.target_position = Vector3(0, 0, -2.4)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_flashlight()


# ------------------------------------------------------------------ input

func _unhandled_input(event):
	if not GameState.is_playing():
		return
	# บนเว็บ เบราว์เซอร์ต้องการคลิกก่อนล็อกเมาส์
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not GameState.modal_open:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if GameState.modal_open or input_locked:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(event.relative)
	elif event.is_action_pressed("Interact"):
		_interact()
	elif event.is_action_pressed("ToggleFlashlight") and not is_hidden:
		toggle_flashlight()
	elif event.is_action_pressed("Crouch") and not is_hidden:
		is_crouching = not is_crouching


func _look(relative: Vector2):
	if is_hidden and hiding_spot:
		hiding_spot.look(relative * mouse_sensitivity)
		return
	rotate_y(-relative.x * mouse_sensitivity)
	head.rotation.x = clampf(head.rotation.x - relative.y * mouse_sensitivity, deg_to_rad(-85), deg_to_rad(85))


# ------------------------------------------------------------------ physics

func _physics_process(delta):
	_check_pointer_lock()
	if not is_on_floor():
		velocity.y -= _gravity * delta
	var target_noise := noise_idle
	var move := Vector2.ZERO
	if not is_hidden and not GameState.modal_open and not input_locked:
		move = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
		# ตอนเปิดเครื่องรับสัญญาณ A/D ใช้จูนคลื่นแทนการเดินด้านข้าง
		if finder.is_on:
			move.x = 0.0
	is_running = Input.is_action_pressed("Sprint") and move.y < 0.0 and not is_crouching and not is_hidden
	var speed := crouch_speed if is_crouching else (run_speed if is_running else walk_speed)
	var dir := (transform.basis * Vector3(move.x, 0, move.y)).normalized()
	velocity.x = move_toward(velocity.x, dir.x * speed, acceleration * delta * speed)
	velocity.z = move_toward(velocity.z, dir.z * speed, acceleration * delta * speed)
	move_and_slide()

	var horizontal := Vector2(velocity.x, velocity.z).length()
	if horizontal > 0.3:
		target_noise = noise_crouch if is_crouching else (noise_run if is_running else noise_walk)
		_footsteps(delta, horizontal)
	target_noise += finder.get_noise_contribution()
	if is_hidden:
		target_noise = 0.0
	noise_level = lerpf(noise_level, clampf(target_noise, 0.0, 1.0), clampf(noise_smoothing * delta, 0.0, 1.0))
	noise_changed.emit(noise_level)

	_update_crouch(delta)
	_update_flashlight(delta)
	_update_interactable()


func _footsteps(delta: float, horizontal: float):
	_step_timer -= delta * horizontal
	if _step_timer <= 0.0:
		_step_timer = 1.9
		var vol := -18.0 if is_crouching else (-4.0 if is_running else -10.0)
		Audio.play_sfx("footstep", vol, randf_range(0.9, 1.1))


func _update_crouch(delta: float):
	var target := crouch_eye_height if is_crouching else stand_eye_height
	head.position.y = lerpf(head.position.y, target, clampf(10.0 * delta, 0.0, 1.0))


## บนเว็บ กด Esc เบราว์เซอร์จะปลดล็อกเมาส์เอง → เปิดเมนู pause ให้อัตโนมัติ
func _check_pointer_lock():
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if OS.has_feature("web") and _had_capture and not captured and GameState.is_playing() and not GameState.modal_open:
		PauseMenu.pause()
	_had_capture = captured


# ------------------------------------------------------------------ flashlight

func toggle_flashlight():
	if not flashlight_on and float(GameState.data["battery"]) <= 0.0 and not _swap_battery():
		GameState.toast("แบตเตอรี่หมด — หาแบตสำรองตามห้องต่างๆ")
		return
	flashlight_on = not flashlight_on
	Audio.play_sfx("flashlight_click", -8.0)
	_apply_flashlight()


func _apply_flashlight():
	flashlight.visible = flashlight_on and not is_hidden


func _update_flashlight(delta: float):
	var battery: float = GameState.data["battery"]
	if flashlight_on and not is_hidden:
		battery = maxf(battery - 100.0 / flashlight_duration_sec * delta, 0.0)
		GameState.data["battery"] = battery
		if battery <= 0.0 and not _swap_battery():
			flashlight_on = false
			GameState.toast("แบตเตอรี่หมด")
	var ratio := battery / 100.0
	flashlight.light_energy = flashlight_energy * clampf(ratio * 2.0, 0.35, 1.0)
	var flicker := flicker_amount
	if battery < low_battery_percent:
		flicker = maxf(flicker, 0.15 + (1.0 - battery / low_battery_percent) * 0.3)
	flashlight.visible = flashlight_on and not is_hidden and randf() > flicker * 0.5
	battery_changed.emit(battery, int(GameState.data["spare_batteries"]))


func _swap_battery() -> bool:
	if int(GameState.data["spare_batteries"]) <= 0:
		return false
	GameState.data["spare_batteries"] = int(GameState.data["spare_batteries"]) - 1
	GameState.data["battery"] = 100.0
	Audio.play_sfx("battery_swap", -4.0)
	GameState.toast("เปลี่ยนแบตเตอรี่ก้อนใหม่ (เหลือสำรอง %d)" % int(GameState.data["spare_batteries"]))
	return true


func add_spare_battery() -> bool:
	if int(GameState.data["spare_batteries"]) >= max_spare_batteries:
		return false
	GameState.data["spare_batteries"] = int(GameState.data["spare_batteries"]) + 1
	if float(GameState.data["battery"]) <= 0.0:
		_swap_battery()
	return true


# ------------------------------------------------------------------ interaction

func _update_interactable():
	var found: Node = null
	if is_hidden:
		found = hiding_spot
	elif ray.is_colliding():
		var c := ray.get_collider()
		if c and c.has_method("get_prompt"):
			found = c
	current_interactable = found
	var prompt := ""
	if found and not GameState.modal_open:
		prompt = found.get_prompt(self)
	if prompt != _last_prompt:
		_last_prompt = prompt
		interactable_changed.emit(prompt)


func _interact():
	if current_interactable and current_interactable.has_method("interact"):
		if not current_interactable.has_method("can_interact") or current_interactable.can_interact(self):
			current_interactable.interact(self)


# ------------------------------------------------------------------ hiding

func enter_hiding(spot: Node):
	is_hidden = true
	hiding_spot = spot
	is_crouching = false
	velocity = Vector3.ZERO
	_apply_flashlight()
	hidden_changed.emit(true)


func exit_hiding():
	is_hidden = false
	hiding_spot = null
	camera.make_current()
	_apply_flashlight()
	hidden_changed.emit(false)


## ตำแหน่งที่ศัตรูใช้มอง (ระดับสายตาผู้เล่น)
func get_eye_position() -> Vector3:
	return camera.global_position


func teleport(pos: Vector3, yaw: float):
	global_position = pos
	rotation.y = yaw
	head.rotation.x = 0.0
	velocity = Vector3.ZERO
