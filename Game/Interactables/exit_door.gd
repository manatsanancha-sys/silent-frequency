extends StaticBody3D
## ประตูเหล็กทางออกด้านหน้า — เปิดด้วยแป้นรหัส (keypad.gd) แล้วหมุนเปิด
## พ้นประตูไปเข้า ExitTrigger (Area3D ลูก) = You Win

@export var size := Vector3(0.15, 2.2, 1.4)
@export var color := Color(0.25, 0.27, 0.3)

var _hinge: Node3D


func _ready():
	collision_layer = 1
	# บานประตูหมุนรอบขอบด้านหนึ่ง
	_hinge = Node3D.new()
	_hinge.position = Vector3(0, 0, -size.z * 0.5)
	add_child(_hinge)
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.6
	mat.roughness = 0.5
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3(0, size.y * 0.5, size.z * 0.5)
	_hinge.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = Vector3(0, size.y * 0.5, 0)
	cs.name = "CollisionShape3D"
	add_child(cs)
	var trigger := get_node_or_null("ExitTrigger") as Area3D
	if trigger:
		trigger.collision_mask = 2
		trigger.body_entered.connect(_on_exit_entered)
	if GameState.data.get("door_open", false):
		open(true)


func open(instant := false):
	($CollisionShape3D as CollisionShape3D).set_deferred("disabled", true)
	if instant:
		_hinge.rotation.y = deg_to_rad(-100)
		return
	Audio.play_sfx_3d("door_open", global_position, 2.0)
	create_tween().tween_property(_hinge, "rotation:y", deg_to_rad(-100), 1.6).set_trans(Tween.TRANS_SINE)


func _on_exit_entered(body):
	if body.is_in_group("player") and GameState.data.get("door_open", false):
		GameState.win()
