extends Node
## เทสอัตโนมัติแบบ end-to-end (รันแบบ headless ได้)
##   godot --headless --path . res://tests/run_tests.tscn
## เล่นเกมผ่าน API จริง: เมนู → เกมใหม่ → ปริศนา 3 ข้อ → รหัส → You Win,
## โดนจับ → Game Over → Retry, Continue, หมดเวลา, Pause, AI 3 state, navmesh

const MENU := "res://Game/UI/Menus/main_menu.tscn"
const LEVEL := "res://levels/radio_station.tscn"
const GAME_OVER := "res://Game/UI/Menus/game_over.tscn"
const WIN := "res://Game/UI/Menus/you_win.tscn"

var failures := 0
var checks := 0


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.save_path = "user://test_save.cfg"
	GameState.delete_save()
	Engine.time_scale = 6.0
	await _frames(5)
	await test_menu_no_save()
	await test_full_win_path()
	await test_game_over_and_retry()
	await test_continue_from_menu()
	await test_dawn_game_over()
	await test_pause()
	await test_enemy_ai()
	Engine.time_scale = 1.0
	GameState.delete_save()
	print("\n==== RESULT: %s — %d checks, %d failure(s) ====" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	get_tree().quit(1 if failures else 0)


# ------------------------------------------------------------------ tests

func test_menu_no_save():
	print("\n[menu]")
	get_tree().change_scene_to_file(MENU)
	await _wait_scene(MENU)
	var cont := _find_button("เล่นต่อ")
	check(cont != null and cont.disabled, "Continue disabled when no save")
	var quit := _find_button("ออกจากเกม")
	check(quit != null and quit.visible == not OS.has_feature("web"), "Quit button visible on desktop")


func test_full_win_path():
	print("\n[full playthrough → win]")
	GameState.start_new_game()
	await _wait_scene(LEVEL)
	var st := get_tree().current_scene
	var player: Player3D = st.player
	var enemy: EnemyAI = st.enemy
	check(GameState.has_save(), "initial checkpoint saved on new game")
	check(not enemy.active, "enemy dormant before power")
	_check_navmesh(st)
	GameState.debug_enemy_disabled = true

	# --- ปริศนา 1
	var it := st.get_node("Interactables")
	var sw = it.get_node("PowerSwitch")
	check(not sw.can_interact(player), "switch locked before fuse")
	check(it.get_node("FuseBox").get_prompt(player).contains("ต้องหาฟิวส์"), "fuse box prompt asks for fuse")
	await _use(player, it.get_node("Fuse"))
	check(GameState.has_item("fuse"), "picked up fuse")
	await _use(player, it.get_node("FuseBox"))
	check(GameState.data["fuse_inserted"] and not GameState.has_item("fuse"), "fuse inserted")
	await _use(player, sw)
	check(GameState.data["power_on"], "power on")
	check(enemy.active, "enemy spawned after power")
	check(st.get_node("Lights/Power_0").visible, "signal room lights on")
	check(GameState.puzzle1_done(), "puzzle 1 done")

	# --- ปริศนา 2: จูน 3 คลื่น
	var finder := player.finder
	for src in get_tree().get_nodes_in_group("frequency_sources"):
		var offsets := [Vector3(0, 0, 2.0), Vector3(-1.5, 0, 0), Vector3(0.6, 0, -1.6)]
		player.teleport(Vector3(src.global_position.x, 0.05, src.global_position.z) + offsets[src.freq_index], 0.0)
		await _physics(3)
		if not finder.is_on:
			finder.set_on(true)
		finder.current_mhz = src.get_mhz() - 1.0
		await _frames(4)
		check(finder.strength > 0.0 and finder.strength < 0.9, "freq %d: weak signal when off-tune (%.2f)" % [src.freq_index, finder.strength])
		finder.current_mhz = src.get_mhz()
		await _wait_until(func(): return src.freq_index in GameState.data["freqs_found"], 60.0)
		check(src.freq_index in GameState.data["freqs_found"], "freq %d (%.1f MHz) received" % [src.freq_index, src.get_mhz()])
	finder.set_on(false)
	check(GameState.puzzle2_done(), "puzzle 2 done (3 digits)")
	for i in 3:
		check(GameState.known_digit(i), "digit %d known" % (i + 1))

	# --- ปริศนา 3: บันทึก 2 + เทป 2
	for n in ["Doc0_EkLogbook", "Doc1_NiphonLog", "Doc2_EkTape", "Doc3_ChiefTape"]:
		var doc = it.get_node_or_null(n)
		check(doc != null, "%s exists" % n)
		if doc:
			await _use(player, doc)
			var hud = st.hud
			if hud.is_modal_open():
				check(GameState.modal_open, "note reader is modal")
				hud.close_modal()
	check(GameState.data["docs_found"].size() == 4, "4 documents collected")
	var tape = it.get_node("TapePlayer")
	for i in 2:
		check(tape.can_interact(player), "tape player ready (tape %d)" % (i + 1))
		await _use(player, tape)
		await _wait_until(func(): return not tape.get_prompt(player).contains("กำลังเล่น"), 60.0)
	check(GameState.puzzle3_done(), "puzzle 3 done")
	check(GameState.all_digits_known(), "all 4 digits known")
	check(not GameState.known_code_display().contains("_"), "HUD code fully revealed")

	# --- ประตูทางออก
	var keypad = it.get_node("Keypad")
	var wrong := str((GameState.code_digit(0) + 1) % 10) + GameState.code_string().substr(1)
	check(not keypad.submit_code(wrong), "wrong code rejected")
	check(not GameState.data["door_open"], "door stays closed on wrong code")
	check(keypad.submit_code(GameState.code_string()), "correct code accepted")
	check(GameState.data["door_open"], "door open")
	await _physics(10)
	var trig: Area3D = st.get_node("ExitDoor/ExitTrigger")
	player.teleport(trig.global_position - Vector3(0, 1.2, 0), 0.0)
	await _wait_scene(WIN)
	check(get_tree().current_scene.scene_file_path == WIN, "You Win screen shown")
	check(not GameState.has_save(), "save cleared after win (Continue disabled)")
	GameState.debug_enemy_disabled = false


func test_game_over_and_retry():
	print("\n[caught → game over → retry from checkpoint]")
	GameState.start_new_game()
	await _wait_scene(LEVEL)
	var st := get_tree().current_scene
	var player: Player3D = st.player
	var it := st.get_node("Interactables")
	GameState.debug_enemy_disabled = true
	await _use(player, it.get_node("Fuse"))
	await _use(player, it.get_node("FuseBox"))
	await _use(player, it.get_node("PowerSwitch"))
	var code_before := GameState.code_string()
	GameState.debug_enemy_disabled = false
	var enemy: EnemyAI = st.enemy
	player.teleport(enemy.global_position + Vector3(0.5, 0, 0.5), 0.0)
	await _wait_scene(GAME_OVER)
	check(get_tree().current_scene.scene_file_path == GAME_OVER, "caught → Game Over screen")
	check(GameState.game_over_reason == "caught", "reason = caught")
	GameState.retry_from_checkpoint()
	await _wait_scene(LEVEL)
	st = get_tree().current_scene
	check(GameState.data["power_on"], "retry restored power_on from checkpoint")
	check(GameState.code_string() == code_before, "retry kept same door code")
	check(st.get_node_or_null("Interactables/Fuse") == null, "taken fuse not respawned")
	await _physics(3)
	check(st.enemy.active and st.enemy.distance_to_player() > 6.0, "enemy respawned far from player (%.1f m)" % st.enemy.distance_to_player())


func test_continue_from_menu():
	print("\n[continue]")
	GameState.go_to_main_menu()
	await _wait_scene(MENU)
	var cont := _find_button("เล่นต่อ")
	check(cont != null and not cont.disabled, "Continue enabled with save")
	cont.pressed.emit()
	await _wait_scene(LEVEL)
	check(get_tree().current_scene.scene_file_path == LEVEL, "Continue loads level")
	check(GameState.data["power_on"], "Continue restored progress")


func test_dawn_game_over():
	print("\n[dawn]")
	GameState.debug_enemy_disabled = true
	GameState.data["time_left"] = 0.3
	await _wait_scene(GAME_OVER)
	check(GameState.game_over_reason == "dawn", "time out → Game Over (dawn)")
	GameState.debug_enemy_disabled = false


func test_pause():
	print("\n[pause]")
	Engine.time_scale = 1.0
	GameState.start_new_game()
	await _wait_scene(LEVEL)
	var st := get_tree().current_scene
	var player: Player3D = st.player
	await _physics(20)
	_press("ui_cancel")
	await _frames(3)
	check(get_tree().paused and PauseMenu.visible, "Esc pauses + shows menu")
	check(GameState.state == GameState.State.PAUSED, "state PAUSED")
	var yaw := player.rotation.y
	var pos := player.global_position
	var t_before := float(GameState.data["time_left"])
	var mm := InputEventMouseMotion.new()
	mm.relative = Vector2(300, 100)
	Input.parse_input_event(mm)
	Input.action_press("moveUp")
	await _frames(30)
	Input.action_release("moveUp")
	check(is_equal_approx(player.rotation.y, yaw), "paused: camera does not turn")
	check(player.global_position.distance_to(pos) < 0.001, "paused: player does not move")
	check(is_equal_approx(float(GameState.data["time_left"]), t_before), "paused: clock stopped")
	await _frames(20)  # กันตัวกันกดซ้ำเร็ว
	_press("ui_cancel")
	await _frames(3)
	check(not get_tree().paused and not PauseMenu.visible, "Esc again resumes")
	Input.parse_input_event(mm)
	Input.action_press("moveUp")
	await _physics(20)
	Input.action_release("moveUp")
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		check(not is_equal_approx(player.rotation.y, yaw), "resumed: mouse look works")
	else:
		print("  skip  resumed: mouse look (headless ล็อกเมาส์ไม่ได้ — ทดสอบเองใน TESTING.md)")
	check(player.global_position.distance_to(pos) > 0.1, "resumed: movement works")
	Engine.time_scale = 6.0


func test_enemy_ai():
	print("\n[enemy AI]")
	var st := get_tree().current_scene
	var player: Player3D = st.player
	var enemy: EnemyAI = st.enemy
	GameState.data["power_on"] = true
	st.apply_power(true, false)
	await _physics(5)
	# ยืนหลังศัตรูไกลๆ ไม่ส่งเสียง → ไม่ควรเห็น
	enemy.activate(Vector3(0, 0.05, 0))
	enemy.rotation.y = 0.0  # มองไป -Z (ทางเดินแคบ) — ผู้เล่นอยู่ +X
	player.teleport(Vector3(9, 0.05, 0), 0.0)
	player.flashlight_on = false
	await _physics(3)
	check(not enemy.can_see_player(), "cannot see player behind/far in dark")
	# เสียงดัง → INVESTIGATE
	NoiseBus.emit_noise(Vector3(6, 0, 0), 12.0, null)
	await _physics(2)
	check(enemy.state == EnemyAI.State.INVESTIGATE, "loud noise → INVESTIGATE")
	# ยืนตรงหน้าเปิดไฟฉาย → CHASE
	enemy.activate(Vector3(0, 0.05, 0))
	enemy.rotation.y = deg_to_rad(-90)  # หันไป +X
	player.teleport(Vector3(6, 0.05, 0), 0.0)
	player.flashlight_on = true
	await _physics(3)
	check(enemy.can_see_player(), "sees lit player in front")
	check(enemy.state == EnemyAI.State.CHASE, "sees player → CHASE")
	var e_pos := enemy.global_position
	await _physics(2)
	check(enemy.global_position.distance_to(e_pos) > 0.05, "chasing moves along navmesh")
	# ซ่อนตัวที่ไกล → มองไม่เห็น → หลัง lose_sight_time กลับไป INVESTIGATE
	var spot = st.get_node("Interactables/Hide_StorageLocker")
	player.teleport(Vector3(-1, 0.05, 5.0), 0.0)
	enemy.time_since_seen = 99.0  # ไม่ได้เห็นตอนเข้าตู้
	spot.interact(player)
	check(player.is_hidden, "player hidden in locker")
	check(not enemy.can_see_player(), "hidden player is invisible")
	await _physics(30)
	check(player.noise_level < 0.05, "hidden → noise ~0")
	await _wait_until(func(): return enemy.state != EnemyAI.State.CHASE, 30.0)
	check(enemy.state == EnemyAI.State.INVESTIGATE, "lost player → INVESTIGATE last seen")
	await _wait_until(func(): return enemy.state == EnemyAI.State.PATROL, 40.0)
	check(enemy.state == EnemyAI.State.PATROL, "search done → PATROL")
	spot.interact(player)
	check(not player.is_hidden, "left hiding spot")
	# speed balance
	check(enemy.chase_speed > player.walk_speed and enemy.chase_speed < player.run_speed, "chase speed between walk and run")


# ------------------------------------------------------------------ helpers

func _check_navmesh(st):
	var region: NavigationRegion3D = st.nav_region
	var polys := region.navigation_mesh.get_polygon_count()
	check(polys > 0, "navmesh baked (%d polygons)" % polys)
	await _physics(3)
	var map := region.get_navigation_map()
	var from := Vector3(-8, 0, -4.5)
	for wp in st.get_node("Waypoints").get_children():
		var to: Vector3 = wp.global_position
		var path := NavigationServer3D.map_get_path(map, from, to, true)
		var ok := path.size() > 0 and Vector2(path[-1].x - to.x, path[-1].z - to.z).length() < 0.8
		check(ok, "navmesh path signal room → %s" % wp.name)


func _use(player, target):
	if target.has_method("can_interact") and not target.can_interact(player):
		check(false, "can interact with %s" % target.name)
		return
	target.interact(player)
	await _physics(2)


func check(cond: bool, label: String):
	checks += 1
	print(("  ok    " if cond else "  FAIL  ") + label)
	if not cond:
		failures += 1


func _find_button(text: String) -> Button:
	for b in get_tree().current_scene.find_children("*", "Button", true, false):
		if b.text == text:
			return b
	return null


func _press(action: String):
	for p in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = p
		Input.parse_input_event(ev)


func _wait_scene(path: String, timeout := 20.0):
	var t := 0.0
	while t < timeout:
		await get_tree().process_frame
		t += get_process_delta_time() / maxf(Engine.time_scale, 1.0)
		var cs := get_tree().current_scene
		if cs and cs.scene_file_path == path and cs.is_node_ready():
			await _frames(3)
			return
	check(false, "timeout waiting for scene " + path)


func _wait_until(cond: Callable, game_seconds: float):
	var t := 0.0
	while t < game_seconds and not cond.call():
		await get_tree().physics_frame
		t += get_physics_process_delta_time()


func _frames(n: int):
	for i in n:
		await get_tree().process_frame


func _physics(n: int):
	for i in n:
		await get_tree().physics_frame
