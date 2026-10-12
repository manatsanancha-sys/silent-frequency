extends Node
## Autoload "Audio" — เล่นเสียงจาก res://assets/audio/<ชื่อ>.wav ผ่าน bus Music / SFX
## เปลี่ยนเป็นไฟล์เสียงจริงได้โดยใช้ชื่อไฟล์เดิม (ดู assets/audio/SOUNDS.md)

const AUDIO_DIR := "res://assets/audio/"
const SETTINGS_PATH := "user://settings.cfg"
## ไฟล์ที่ต้องเล่นวนซ้ำ
const LOOPING := ["ambient_drone", "static_loop", "transmission_loop", "power_hum_loop", "heartbeat", "chase_loop"]

var _cache := {}
var _music: AudioStreamPlayer
var _music_name := ""
var _pool: Array[AudioStreamPlayer] = []


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	load_settings()


func get_stream(sound: String) -> AudioStream:
	if _cache.has(sound):
		return _cache[sound]
	var path := AUDIO_DIR + sound + ".wav"
	if not ResourceLoader.exists(path):
		push_warning("missing sound: " + path)
		_cache[sound] = null
		return null
	var stream: AudioStream = load(path)
	if sound in LOOPING and stream is AudioStreamWAV:
		stream = stream.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)  # จำนวน frame
	_cache[sound] = stream
	return stream


func play_sfx(sound: String, volume_db := 0.0, pitch := 1.0):
	var stream := get_stream(sound)
	if stream == null:
		return
	var player: AudioStreamPlayer = null
	for p in _pool:
		if not p.playing:
			player = p
			break
	if player == null:
		player = _pool[0]
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


## เสียงแบบมีตำแหน่งในฉาก 3D (ลบตัวเองเมื่อเล่นจบ)
func play_sfx_3d(sound: String, position: Vector3, volume_db := 0.0, pitch := 1.0):
	var stream := get_stream(sound)
	var scene := get_tree().current_scene
	if stream == null or scene == null or not (scene is Node3D):
		play_sfx(sound, volume_db, pitch)
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.bus = "SFX"
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.unit_size = 4.0
	p.max_distance = 30.0
	scene.add_child(p)
	p.global_position = position
	p.finished.connect(p.queue_free)
	p.play()


## สร้าง player เสียงวนซ้ำ ผูกไว้กับ node ที่ส่งมา (ใช้กับ static, หัวใจเต้น ฯลฯ)
func make_loop_player(owner_node: Node, sound: String, bus := "SFX") -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = get_stream(sound)
	p.bus = bus
	owner_node.add_child(p)
	return p


func play_music(sound: String, volume_db := 0.0):
	if _music_name == sound and _music.playing:
		return
	_music_name = sound
	_music.stream = get_stream(sound)
	_music.volume_db = volume_db
	_music.play()


func stop_music():
	_music_name = ""
	_music.stop()


# ------------------------------------------------------------------ volume settings

func get_bus_volume(bus: String) -> float:
	var idx := AudioServer.get_bus_index(bus)
	return db_to_linear(AudioServer.get_bus_volume_db(idx)) if idx >= 0 else 1.0


func set_bus_volume(bus: String, linear: float):
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)


func save_settings():
	var cfg := ConfigFile.new()
	for bus in ["Music", "SFX"]:
		cfg.set_value("audio", bus, get_bus_volume(bus))
	cfg.save(SETTINGS_PATH)


func load_settings():
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for bus in ["Music", "SFX"]:
		if cfg.has_section_key("audio", bus):
			set_bus_volume(bus, float(cfg.get_value("audio", bus)))
