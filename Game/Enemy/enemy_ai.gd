extends CharacterBody3D
class_name EnemyAI
## "มัน" — ศัตรู 3 state ใช้ NavigationAgent3D เดินบน navmesh ของ NavigationRegion3D ในฉาก
##
##   PATROL ──ได้ยินเสียง (noise ผู้เล่น / NoiseBus)──▶ INVESTIGATE ──ค้น 3-5 วิ ไม่เจอ──▶ PATROL
##     │                                                   │
##     └────────────────เห็นผู้เล่น──────────────▶ CHASE ◀──┘
##                                                 │ คลาดสายตาเกิน lose_sight_time
##                                                 └──▶ INVESTIGATE (จุดสุดท้ายที่เห็น)
## เข้าระยะ catch_distance = Game Over · ถ้าเห็นผู้เล่นตอนเข้าตู้ มันจะไปลากออกมา

signal state_changed(new_state: int)

enum State { PATROL, INVESTIGATE, CHASE }

## ค่าเดิมก่อนปรับ balance (2026-10) อยู่ในคอมเมนต์ "เดิม" — ดูตารางใน README
@export_group("Speed (ผู้เล่น: เดิน 3.0 / วิ่ง 5.6)")
@export var patrol_speed := 1.3       # เดิม 1.5
@export var investigate_speed := 2.3  # เดิม 2.6
## เร็วกว่าเดิน (จับได้ถ้าเดินหนี) แต่ช้ากว่าวิ่งชัดเจน → วิ่งหนีพ้นได้จริง
@export var chase_speed := 4.3        # เดิม 4.9
@export var turn_speed := 8.0

@export_group("Hearing")
## รัศมีได้ยิน = noise_level ของผู้เล่น x hearing_range (เมตร)
@export var hearing_range := 10.0     # เดิม 16 → เดินได้ยินในระยะ 4 ม., วิ่ง 10 ม.
## noise ต่ำกว่านี้ไม่สนใจ (ย่อเดิน = 0.12 → ไม่ถูกได้ยินเลย)
@export var noise_threshold := 0.25   # เดิม 0.2
## ความคลาดเคลื่อนของตำแหน่งที่ได้ยิน (เมตร)
@export var hearing_inaccuracy := 1.2

@export_group("Vision")
## มันมองเห็นในความมืดได้แค่ระยะใกล้ — ถ้าผู้เล่นเปิดไฟฉายจะเห็นได้ไกลขึ้น
@export var sight_range_dark := 4.0   # เดิม 6
@export var sight_range_lit := 9.5    # เดิม 15
@export_range(10, 180) var sight_fov_deg := 95.0  # เดิม 110
## ต้องเห็นผู้เล่นต่อเนื่องนานเท่านี้ก่อนไล่ล่า (ระหว่างนั้นจะหยุดหันมอง)
@export var sight_confirm_time := 0.7  # เดิม 0 (เห็นแล้วไล่ทันที)
@export var crouch_sight_multiplier := 0.7
## เห็นผู้เล่นตอนเข้าตู้ภายในกี่วินาทีถึงจะรู้ว่าซ่อนอยู่ไหน
@export var saw_hiding_window := 0.8

@export_group("Timing")
@export var search_time_min := 3.0
@export var search_time_max := 5.0
@export var lose_sight_time := 3.0    # เดิม 5
@export var waypoint_pause := 3.0     # เดิม 1.5
@export var catch_distance := 1.2
## หลังเปิดไฟ (ศัตรูเพิ่งตื่น) กี่วินาทีที่จะยังไม่ลาดตระเวนเข้าห้องรับสัญญาณ และไม่สนเสียง
@export var grace_period_sec := 25.0

@export_group("Stuck detection")
## ตั้งใจเดินแต่ความเร็วจริงต่ำกว่า (ratio x ความเร็วที่ต้องการ) ต่อเนื่องนานเท่านี้ = ติด
@export var stuck_time := 1.5
@export var stuck_speed_ratio := 0.25
## ผู้เล่นอยู่ไกลกว่านี้ถือว่ามองไม่เห็นจุดวาร์ป (ใช้คู่กับ raycast)
@export var teleport_min_player_distance := 10.0

var state: int = State.PATROL
var active := false
var player: Player3D = null
var waypoints: Array[Node3D] = []
var last_seen_position := Vector3.ZERO
var known_hiding_spot: Node3D = null
var time_since_seen := 999.0
## สถิติสำหรับเทส/ดีบัก
var stuck_repaths := 0
var stuck_teleports := 0

var _target := Vector3.ZERO
var _timer := 0.0
var _search_time := 4.0
var _wp_index := -1
var _step_timer := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _sight_timer := 0.0
var _grace_left := 0.0
var _wants_move := false
var _intended_speed := 0.0
var _stuck_timer := 0.0
var _stuck_strikes := 0
var _good_move_time := 0.0

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var eyes: Node3D = $Eyes


func _ready():
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	NoiseBus.noise_emitted.connect(_on_noise_emitted)
	agent.path_desired_distance = 0.6
	agent.target_desired_distance = 0.8
	agent.radius = 0.35
	agent.height = 1.9


func setup(p: Player3D, points: Array[Node3D]):
	player = p
	waypoints = points


## with_grace = เพิ่งเปิดไฟ → ผ่อนผัน grace_period_sec วินาที
func activate(at: Vector3, with_grace := false):
	global_position = at
	active = true
	visible = true
	velocity = Vector3.ZERO
	_grace_left = grace_period_sec if with_grace else 0.0
	_sight_timer = 0.0
	_stuck_timer = 0.0
	_stuck_strikes = 0
	enter_state(State.PATROL)


func in_grace() -> bool:
	return _grace_left > 0.0


func deactivate():
	active = false
	visible = false
	velocity = Vector3.ZERO


func _physics_process(delta):
	if not active or GameState.debug_enemy_disabled:
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	time_since_seen += delta
	_grace_left = maxf(_grace_left - delta, 0.0)
	_wants_move = false
	var sees := can_see_player()
	if sees:
		time_since_seen = 0.0
		last_seen_position = player.global_position
		_sight_timer += delta
	else:
		_sight_timer = maxf(_sight_timer - delta * 2.0, 0.0)
	match state:
		State.PATROL:
			_process_patrol(delta, sees)
		State.INVESTIGATE:
			_process_investigate(delta, sees)
		State.CHASE:
			_process_chase(delta, sees)
	if state != State.CHASE:
		_check_hearing()
	move_and_slide()
	_check_stuck(delta)
	_check_catch()
	_footsteps(delta)


# ------------------------------------------------------------------ states

func enter_state(s: int):
	var prev := state
	state = s
	_timer = 0.0
	match s:
		State.PATROL:
			known_hiding_spot = null
			_next_waypoint()
		State.INVESTIGATE:
			_search_time = randf_range(search_time_min, search_time_max)
			agent.target_position = _target
		State.CHASE:
			if prev != State.CHASE:
				Audio.play_sfx_3d("enemy_scream", global_position, 4.0)
	state_changed.emit(s)


## เห็นผู้เล่น: หยุดหันมองจนครบ sight_confirm_time แล้วค่อยไล่ — คืน true ถ้ากำลังจ้องอยู่
func _notice_player(delta: float, sees: bool) -> bool:
	if not sees:
		return false
	if _sight_timer >= sight_confirm_time:
		enter_state(State.CHASE)
		return true
	velocity.x = 0.0
	velocity.z = 0.0
	_face(player.global_position - global_position, delta)
	return true


func _process_patrol(delta: float, sees: bool):
	if _notice_player(delta, sees):
		return
	if _move_along_path(patrol_speed, delta):
		_timer += delta
		if _timer >= waypoint_pause:
			_timer = 0.0
			_next_waypoint()


func _process_investigate(delta: float, sees: bool):
	if _notice_player(delta, sees):
		return
	if _move_along_path(investigate_speed, delta):
		# ถ้ามันเห็นผู้เล่นเข้าตู้ → มาถึงแล้วลากออก
		if known_hiding_spot and player and player.is_hidden and player.hiding_spot == known_hiding_spot:
			_catch()
			return
		_timer += delta
		rotate_y(delta * 1.2)  # หันมองรอบๆ
		if _timer >= _search_time:
			enter_state(State.PATROL)


func _process_chase(delta: float, sees: bool):
	if sees:
		agent.target_position = player.global_position
	elif time_since_seen >= lose_sight_time:
		_target = last_seen_position
		enter_state(State.INVESTIGATE)
		return
	else:
		agent.target_position = last_seen_position
	_move_along_path(chase_speed, delta)


func _next_waypoint():
	var choices: Array[int] = []
	for i in waypoints.size():
		if i == _wp_index and waypoints.size() > 1:
			continue
		# ช่วงผ่อนผันหลังเปิดไฟ: ยังไม่เดินเข้าห้องรับสัญญาณ
		if in_grace() and waypoints[i].is_in_group("wp_signal_room"):
			continue
		choices.append(i)
	if choices.is_empty():
		_target = global_position
	else:
		_wp_index = choices[randi() % choices.size()]
		_target = waypoints[_wp_index].global_position
	agent.target_position = _target


## เดินตาม navmesh — คืน true เมื่อถึงเป้าหมายแล้ว
func _move_along_path(speed: float, delta: float) -> bool:
	if agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
		return true
	var next := agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	if dir.length() < 0.05:
		velocity.x = 0.0
		velocity.z = 0.0
		return agent.is_navigation_finished()
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	_wants_move = true
	_intended_speed = speed
	_face(dir, delta)
	return false


func _face(dir: Vector3, delta: float):
	if Vector2(dir.x, dir.z).length() < 0.01:
		return
	var target_yaw := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))


# ------------------------------------------------------------------ stuck detection

## ติดครั้งแรก → ขอ path ใหม่ · ติดซ้ำ → วาร์ปไป waypoint ที่ใกล้ที่สุดซึ่งผู้เล่นมองไม่เห็น
func _check_stuck(delta: float):
	var real := get_real_velocity()
	var real_speed := Vector2(real.x, real.z).length()
	if not _wants_move or real_speed >= _intended_speed * stuck_speed_ratio:
		_stuck_timer = 0.0
		if _wants_move:
			_good_move_time += delta
			if _good_move_time > 2.0:
				_stuck_strikes = 0
		return
	_good_move_time = 0.0
	_stuck_timer += delta
	if _stuck_timer < stuck_time:
		return
	_stuck_timer = 0.0
	_stuck_strikes += 1
	if _stuck_strikes == 1:
		stuck_repaths += 1
		var goal := agent.target_position
		agent.target_position = global_position  # ล้าง path เดิม
		agent.target_position = goal
		# ถอยออกจากขอบประตู/มุมผนังเล็กน้อย
		var back := global_transform.basis.z * 0.3
		global_position += Vector3(back.x, 0, back.z)
	else:
		_stuck_strikes = 0
		var wp := _hidden_waypoint_near()
		if wp:
			stuck_teleports += 1
			global_position = wp.global_position
			velocity = Vector3.ZERO
			agent.target_position = _target


func _hidden_waypoint_near() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for w in waypoints:
		if w.global_position.distance_to(global_position) < 1.0:
			continue
		if not _player_can_see_point(w.global_position + Vector3.UP * 1.5):
			var d := w.global_position.distance_to(global_position)
			if d < best_d:
				best = w
				best_d = d
	return best


func _player_can_see_point(pos: Vector3) -> bool:
	if player == null:
		return false
	var eye := player.get_eye_position()
	if eye.distance_to(pos) > teleport_min_player_distance:
		return false
	var query := PhysicsRayQueryParameters3D.create(eye, pos, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


# ------------------------------------------------------------------ senses

func can_see_player() -> bool:
	if player == null or player.is_hidden:
		return false
	var eye := eyes.global_position
	var target := player.get_eye_position()
	var to_player := target - eye
	var range_m := sight_range_lit if player.flashlight_on else sight_range_dark
	if player.is_crouching:
		range_m *= crouch_sight_multiplier
	if to_player.length() > range_m:
		return false
	var forward := -global_transform.basis.z
	var flat := Vector3(to_player.x, 0, to_player.z).normalized()
	if rad_to_deg(forward.angle_to(flat)) > sight_fov_deg * 0.5:
		return false
	var query := PhysicsRayQueryParameters3D.create(eye, target, 1)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty()


func _check_hearing():
	if player == null or player.is_hidden or in_grace():
		return
	var noise := player.noise_level
	if noise < noise_threshold:
		return
	if global_position.distance_to(player.global_position) <= noise * hearing_range:
		_investigate(player.global_position)


func _on_noise_emitted(pos: Vector3, loudness: float, _source: Node):
	if not active or state == State.CHASE or in_grace():
		return
	if global_position.distance_to(pos) <= loudness:
		_investigate(pos)


func _investigate(pos: Vector3):
	var jitter := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * hearing_inaccuracy
	_target = pos + jitter
	if state == State.INVESTIGATE:
		agent.target_position = _target
		_timer = 0.0
	else:
		enter_state(State.INVESTIGATE)


## เรียกผ่าน call_group จาก HidingSpot ตอนผู้เล่นเข้าซ่อน
func _on_player_hidden(spot: Node3D):
	if active and time_since_seen <= saw_hiding_window:
		known_hiding_spot = spot
		_target = spot.global_position
		enter_state(State.INVESTIGATE)


func _check_catch():
	if player == null or player.is_hidden:
		return
	var d := Vector2(global_position.x - player.global_position.x, global_position.z - player.global_position.z).length()
	if d <= catch_distance:
		_catch()


func _catch():
	active = false
	Audio.play_sfx("jumpscare", 2.0)
	GameState.game_over("caught")


func _footsteps(delta: float):
	var speed := Vector2(velocity.x, velocity.z).length()
	if speed < 0.2:
		return
	_step_timer -= delta * speed
	if _step_timer <= 0.0:
		_step_timer = 2.2
		Audio.play_sfx_3d("footstep_enemy", global_position, 0.0 if state == State.CHASE else -4.0, randf_range(0.8, 0.95))


func distance_to_player() -> float:
	if player == null:
		return INF
	return global_position.distance_to(player.global_position)
