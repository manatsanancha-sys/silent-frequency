extends Node3D
## สคริปต์หลักของด่านสถานีวิทยุ
## - เริ่มเกมใหม่/โหลดเซฟ วางผู้เล่น, ตั้งค่าไฟตามสถานะ
## - นาฬิกา 02:00 → 06:00 (night_duration_sec วินาทีจริง) หมดเวลา = Game Over
## - เปิดไฟ (ปริศนา 1) → ไฟห้องรับสัญญาณติด + ศัตรูตื่น
## - เสียงหัวใจเต้น / ไฟกะพริบ / ภาพ VHS เพี้ยน ตามระยะศัตรู
## - navmesh ครอบคลุมทุกห้อง bake ไว้แล้วใน levels/radio_station_navmesh.tres (tools/bake_navmesh.tscn)
## - debug key (เฉพาะ debug build): F9 วาร์ปไปห้องทางออก · F10 ปิด/เปิดศัตรู · F11 ปลดล็อกรหัสทั้งหมด

## เวลาทั้งคืน (วินาทีจริง) = 02:00 → 06:00
@export var night_duration_sec := 900.0
@export var heartbeat_range := 16.0
@export var flicker_range := 11.0

@export_group("VHS effect (เฉพาะภาพ 3D — ไม่ทับ UI)")
@export var vhs_enabled := true
@export_range(0.0, 2.0, 0.05) var vhs_strength := 0.6
@export_range(0.0, 0.01, 0.0005) var vhs_chroma := 0.001
@export_range(0.0, 0.3, 0.01) var vhs_grain := 0.045
@export_range(0.0, 1.0, 0.05) var vhs_vignette := 0.5
## ความบิดเบี้ยวสูงสุดตอนศัตรูไล่ล่า/อยู่ใกล้
@export_range(0.0, 1.0, 0.05) var vhs_max_distortion := 0.7

@onready var player: Player3D = $Player
@onready var enemy: EnemyAI = $Enemy
@onready var hud = $HUD
@onready var nav_region: NavigationRegion3D = $NavigationRegion3D

var _heartbeat: AudioStreamPlayer
var _hum: AudioStreamPlayer
var _flicker_lights: Array[Light3D] = []
var _light_base_energy := {}
var _vhs_mat: ShaderMaterial


func _ready():
	add_to_group("station")
	if GameState.data.is_empty() or not GameState.loading_from_save:
		if GameState.data.is_empty():
			GameState.data = GameState.new_run_data(night_duration_sec)
		else:
			GameState.data["night_duration"] = night_duration_sec
			GameState.data["time_left"] = night_duration_sec
	GameState.state = GameState.State.PLAYING
	GameState.modal_open = false
	get_tree().paused = false

	# ปกติใช้ navmesh ที่ bake ไว้แล้ว (levels/radio_station_navmesh.tres) — ถ้าว่างค่อย bake ตอนนี้
	if nav_region.navigation_mesh == null or nav_region.navigation_mesh.get_polygon_count() == 0:
		nav_region.bake_navigation_mesh(false)
	hud.bind_player(player)
	_setup_vhs()
	var points: Array[Node3D] = []
	for c in $Waypoints.get_children():
		points.append(c)
	enemy.setup(player, points)
	enemy.deactivate()

	for l in get_tree().get_nodes_in_group("flicker_lights"):
		_flicker_lights.append(l)
		_light_base_energy[l] = l.light_energy

	_heartbeat = Audio.make_loop_player(self, "heartbeat")
	_heartbeat.volume_db = -60.0
	_hum = Audio.make_loop_player(self, "power_hum_loop")
	_hum.volume_db = -18.0

	if GameState.loading_from_save and GameState.data["has_player_transform"]:
		player.teleport(GameState.data["player_pos"], GameState.data["player_yaw"])
	else:
		var spawn: Node3D = $PlayerSpawn
		player.teleport(spawn.global_position, spawn.rotation.y)
	apply_power(GameState.data["power_on"], false)
	Audio.play_music("ambient_drone", -4.0)

	if not GameState.data["intro_shown"]:
		GameState.data["intro_shown"] = true
		GameState.show_subtitles(Story.INTRO)
		# checkpoint แรก — ให้ Retry ได้แม้ยังไม่แก้ปริศนา
		GameState.save_checkpoint(player)
	GameState.loading_from_save = false
	hud.refresh_progress()


## เอฟเฟกต์ VHS อยู่ใน CanvasLayer layer 5 (ต่ำกว่า HUD = 10, Pause = 100) จึงลงแค่ภาพ 3D
func _setup_vhs():
	if not vhs_enabled:
		return
	var layer := UiKit.vhs_layer(vhs_strength)
	add_child(layer)
	_vhs_mat = layer.get_node("Overlay").material
	_vhs_mat.set_shader_parameter("chroma", vhs_chroma)
	_vhs_mat.set_shader_parameter("grain", vhs_grain)
	_vhs_mat.set_shader_parameter("vignette", vhs_vignette)


## เปิด/ปิดไฟสถานี — announce = เพิ่งกดสวิตช์ (เล่นเอฟเฟกต์ + ปลุกศัตรู)
func apply_power(on: bool, announce: bool):
	for l in get_tree().get_nodes_in_group("power_lights"):
		l.visible = on
	for m in get_tree().get_nodes_in_group("power_screens"):
		m.visible = on
	if on:
		_hum.play()
		if not enemy.active:
			_spawn_enemy(announce)
	else:
		_hum.stop()


func _spawn_enemy(announce: bool):
	var spawn: Node3D = $EnemySpawn
	var pos := spawn.global_position
	if not announce:
		# โหลดเซฟ: เกิดที่ waypoint ที่ไกลผู้เล่นที่สุด กันโดนจับทันที
		var best := -1.0
		for w in $Waypoints.get_children():
			var d: float = w.global_position.distance_to(player.global_position)
			if d > best:
				best = d
				pos = w.global_position
	enemy.activate(pos, announce)
	if announce:
		Audio.play_sfx_3d("door_open", spawn.global_position, 0.0, 0.7)


func _process(delta):
	if not GameState.is_playing():
		return
	GameState.data["time_left"] = float(GameState.data["time_left"]) - delta
	if float(GameState.data["time_left"]) <= 0.0:
		GameState.data["time_left"] = 0.0
		GameState.game_over("dawn")
		return
	_update_threat(delta)


func _update_threat(_delta: float):
	var closeness := 0.0
	var chasing := false
	if enemy.active and not GameState.debug_enemy_disabled:
		closeness = clampf(1.0 - enemy.distance_to_player() / heartbeat_range, 0.0, 1.0)
		chasing = enemy.state == EnemyAI.State.CHASE
	if chasing:
		closeness = maxf(closeness, 0.55)
	# เสียงหัวใจ
	if closeness > 0.01:
		if not _heartbeat.playing:
			_heartbeat.play()
		_heartbeat.volume_db = lerpf(-30.0, 2.0, closeness)
		_heartbeat.pitch_scale = 1.0 + closeness * 0.6 + (0.25 if chasing else 0.0)
	elif _heartbeat.playing:
		_heartbeat.stop()
	# ไฟกะพริบตอนมันไล่ล่า / อยู่ใกล้
	for l in _flicker_lights:
		if not l.is_visible_in_tree():
			continue
		var near := enemy.active and l.global_position.distance_to(enemy.global_position) < flicker_range
		if (chasing or closeness > 0.6) and near:
			l.light_energy = _light_base_energy[l] * (0.0 if randf() < 0.35 else randf_range(0.3, 1.2))
		else:
			l.light_energy = _light_base_energy[l]
	player.flicker_amount = closeness * 0.8 if (chasing or closeness > 0.5) else 0.0
	if _vhs_mat:
		_vhs_mat.set_shader_parameter("distortion", closeness * (1.0 if chasing else 0.5) * vhs_max_distortion)


func _unhandled_input(event):
	if not OS.is_debug_build() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F9:
			var p: Node3D = $DebugExitPoint
			player.teleport(p.global_position, p.rotation.y)
			GameState.toast("[DEBUG] วาร์ปไปห้องทางออก")
		KEY_F10:
			GameState.debug_enemy_disabled = not GameState.debug_enemy_disabled
			GameState.toast("[DEBUG] ศัตรู: %s" % ("ปิด" if GameState.debug_enemy_disabled else "เปิด"))
		KEY_F11:
			_debug_solve_all()


func _debug_solve_all():
	GameState.data["fuse_inserted"] = true
	if not GameState.data["power_on"]:
		GameState.data["power_on"] = true
		apply_power(true, true)
	GameState.data["freqs_found"] = [0, 1, 2]
	GameState.data["docs_found"] = [0, 1, 2, 3]
	GameState.data["tapes_played"] = [2, 3]
	GameState.notify_progress()
	GameState.toast("[DEBUG] ปลดล็อกทุกปริศนา รหัสคือ %s" % GameState.code_string())
