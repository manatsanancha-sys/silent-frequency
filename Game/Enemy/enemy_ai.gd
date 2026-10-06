extends CharacterBody3D
class_name EnemyAI
## AI ศัตรู 3 state — PLACEHOLDER (โครง + logic ง่ายๆ ให้ขยับได้)
##
##   PATROL      สำรวจ: เดินวนตาม patrol_points
##       │ ได้ยินเสียง (NoiseBus)            │ เห็นผู้เล่น
##       ▼                                    ▼
##   INVESTIGATE ได้ยินเสียงแล้วมาดู ──เห็นผู้เล่น──▶ CHASE ไล่ล่า
##       │ ไปถึงจุดแล้วไม่เจอ (รอ investigate_wait)  │ คลาดสายตานาน lose_sight_time
##       └──────────▶ PATROL ◀──────────────────── INVESTIGATE (ไปจุดที่เห็นล่าสุด)
##
## TODO:
## - เปลี่ยนการเดินตรงไปเป้าหมาย เป็น NavigationAgent3D + NavigationRegion3D (bake navmesh ในฉาก)
## - แอนิเมชัน/เสียงของแต่ละ state, จับผู้เล่นได้ → game over
## - ไฟฉายผู้เล่นส่องโดน → ศัตรูสังเกตเห็นง่ายขึ้น?

signal state_changed(new_state: State)
signal caught_player

enum State { PATROL, INVESTIGATE, CHASE }

@export var patrol_points: Array[Node3D] = []
@export var patrol_speed := 1.5
@export var investigate_speed := 2.5
@export var chase_speed := 4.0
@export var sight_range := 12.0
@export_range(0, 180) var sight_fov_deg := 60.0
@export var hearing_multiplier := 1.0
@export var investigate_wait := 3.0
@export var lose_sight_time := 4.0
@export var catch_distance := 1.2

var state: State = State.PATROL
var target_position := Vector3.ZERO
var player: Node3D = null
var _patrol_index := 0
var _timer := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	NoiseBus.noise_emitted.connect(_on_noise_emitted)
	player = get_tree().get_first_node_in_group("player") as Node3D
	enter_state(State.PATROL)


func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= _gravity * delta
	match state:
		State.PATROL:
			process_patrol(delta)
		State.INVESTIGATE:
			process_investigate(delta)
		State.CHASE:
			process_chase(delta)
	move_and_slide()


# ---------------------------------------------------------------- state machine

func enter_state(new_state: State):
	state = new_state
	_timer = 0.0
	match state:
		State.PATROL:
			pass  # TODO: เล่นแอนิเมชันเดินช้า, เสียงหายใจ
		State.INVESTIGATE:
			pass  # TODO: เสียง "หืม?", หันไปทางเสียง
		State.CHASE:
			pass  # TODO: เสียงกรีดร้อง + เพลงไล่ล่า
	state_changed.emit(state)


## สำรวจ: เดินไปจุดถัดไปเรื่อยๆ
func process_patrol(delta):
	if can_see_player():
		enter_state(State.CHASE)
		return
	if patrol_points.is_empty():
		stop_moving()
		return
	var point := patrol_points[_patrol_index].global_position
	if move_towards(point, patrol_speed):
		_timer += delta
		if _timer > 1.0:  # หยุดมองรอบๆ แป๊บนึง
			_patrol_index = (_patrol_index + 1) % patrol_points.size()
			_timer = 0.0


## ได้ยินเสียงแล้วมาดู: เดินไปที่ target_position แล้วรอ
func process_investigate(delta):
	if can_see_player():
		enter_state(State.CHASE)
		return
	if move_towards(target_position, investigate_speed):
		_timer += delta
		# TODO: ส่องหา/ค้นจุดซ่อนตัวใกล้ๆ (group "hiding_spots")
		if _timer >= investigate_wait:
			enter_state(State.PATROL)


## ไล่ล่า: วิ่งตามผู้เล่น ถ้าคลาดสายตานาน → ไปดูจุดสุดท้ายที่เห็น
func process_chase(delta):
	if player == null:
		enter_state(State.PATROL)
		return
	if can_see_player():
		_timer = 0.0
		target_position = player.global_position
	else:
		_timer += delta
		if _timer >= lose_sight_time:
			enter_state(State.INVESTIGATE)
			return
	move_towards(target_position, chase_speed)
	if global_position.distance_to(player.global_position) <= catch_distance and not PlayerStealth.is_hidden:
		caught_player.emit()
		# TODO: game over / jumpscare
		print("[EnemyAI] caught player (placeholder)")
		enter_state(State.PATROL)


# ---------------------------------------------------------------- senses

func _on_noise_emitted(noise_position: Vector3, loudness: float, _source: Node):
	if state == State.CHASE:
		return
	var heard_radius := loudness * hearing_multiplier
	if global_position.distance_to(noise_position) <= heard_radius:
		target_position = noise_position
		enter_state(State.INVESTIGATE)


func can_see_player() -> bool:
	if player == null or PlayerStealth.is_hidden:
		return false
	var to_player := player.global_position - global_position
	var effective_range := sight_range * maxf(PlayerStealth.get_noise_multiplier(), 0.5)
	if to_player.length() > effective_range:
		return false
	var forward := -global_transform.basis.z
	if rad_to_deg(forward.angle_to(to_player.normalized())) > sight_fov_deg * 0.5:
		return false
	# line of sight
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, player.global_position + Vector3.UP * 0.5)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == player


# ---------------------------------------------------------------- movement

## เดินตรงไปหาเป้า (ยังไม่ใช้ navmesh) คืน true เมื่อถึงแล้ว
func move_towards(point: Vector3, speed: float) -> bool:
	var flat := Vector3(point.x - global_position.x, 0, point.z - global_position.z)
	if flat.length() < 0.5:
		stop_moving()
		return true
	var dir := flat.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	look_at(global_position + dir, Vector3.UP)
	return false


func stop_moving():
	velocity.x = 0
	velocity.z = 0
