extends Interactable
class_name HidingSpot
## จุดซ่อนตัว (ตู้เสื้อผ้า / ล็อกเกอร์ / ใต้โต๊ะ) — กด E เข้า/ออก
## ตอนซ่อน: กล้องย้ายไปที่ view_point มองผ่านช่อง (HUD วาดแถบดำ), ศัตรูมองไม่เห็น, เสียงเป็น 0
## ถ้าศัตรูเห็นตอนกำลังเข้า มันจะรู้ (ดู enemy.gd: _on_player_hidden)

## ตำแหน่ง/ทิศของกล้องตอนซ่อน (local) — ค่าเริ่มต้นคือหน้าตู้มองออก (+Z ของตู้)
@export var view_offset := Vector3(0, 1.45, 0.2)
@export var view_yaw_deg := 0.0
@export var look_limit_deg := 35.0
## true = ใต้โต๊ะ (มุมกล้องต่ำ) แค่ไว้แสดงข้อความ
@export var is_under_desk := false

var _camera: Camera3D
var _base_yaw := 0.0
var _yaw := 0.0
var _pitch := 0.0


func _setup():
	add_to_group("hiding_spots")
	prompt = "ซ่อนใต้โต๊ะ" if is_under_desk else "ซ่อนในตู้"
	_camera = Camera3D.new()
	_camera.fov = 60.0
	_camera.near = 0.05
	add_child(_camera)
	_camera.position = view_offset
	# กล้องของ Godot มองไปทาง -Z → หมุน 180° ให้มองออกด้านหน้าตู้ (+Z)
	_base_yaw = deg_to_rad(180.0 + view_yaw_deg)
	_camera.rotation = Vector3(0, _base_yaw, 0)


func get_prompt(player) -> String:
	if player and player.is_hidden and player.hiding_spot == self:
		return "กด E เพื่อออกจากที่ซ่อน"
	return "กด E เพื่อ" + prompt


func interact(player = null):
	if player == null:
		return
	if player.is_hidden:
		_exit(player)
	else:
		_enter(player)


func _enter(player):
	_yaw = 0.0
	_pitch = 0.0
	_camera.rotation = Vector3(0, _base_yaw, 0)
	_camera.make_current()
	player.enter_hiding(self)
	Audio.play_sfx_3d("locker", global_position, -2.0)
	NoiseBus.emit_noise(global_position, 2.0, self)
	get_tree().call_group("enemies", "_on_player_hidden", self)


func _exit(player):
	player.exit_hiding()
	Audio.play_sfx_3d("locker", global_position, -2.0)


## หมุนมองได้นิดหน่อยตอนซ่อน (เรียกจาก player._look)
func look(delta: Vector2):
	var lim := deg_to_rad(look_limit_deg)
	_yaw = clampf(_yaw - delta.x, -lim, lim)
	_pitch = clampf(_pitch - delta.y, -lim * 0.6, lim * 0.6)
	_camera.rotation = Vector3(_pitch, _base_yaw + _yaw, 0)
