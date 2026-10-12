extends InteractionBase
class_name Interactable
## ฐานของทุกอย่างที่กด E ได้ในเกม (ต่อยอดจาก InteractionBase ของ template)
## - get_prompt() คืนข้อความบอกปุ่มบน HUD เช่น "กด E เพื่อเก็บฟิวส์"
## - ถ้าตั้ง box_size และยังไม่มี CollisionShape3D ลูก จะสร้างกล่อง greybox ให้อัตโนมัติ

@export var prompt := "โต้ตอบ"
## id สำหรับจำว่าเก็บ/ใช้ไปแล้ว (ต้องไม่ซ้ำในฉาก) — ว่างได้ถ้าไม่ต้องจำ
@export var item_id := ""
@export_group("Greybox")
@export var box_size := Vector3.ZERO
@export var box_color := Color(0.4, 0.4, 0.4)
@export var glow := 0.0
## true = ชนได้ (เฟอร์นิเจอร์), false = เดินทะลุได้ (ของชิ้นเล็ก)
@export var solid := true


func _ready():
	collision_layer = (1 | 8) if solid else 8
	collision_mask = 0
	if box_size != Vector3.ZERO and get_node_or_null("CollisionShape3D") == null:
		_build_box()
	_setup()


## ให้คลาสลูก override แทน _ready
func _setup():
	pass


func _build_box():
	var shape := BoxShape3D.new()
	# ของชิ้นเล็กขยายกล่องชนให้เล็งง่ายขึ้น
	shape.size = box_size if solid else box_size.max(Vector3(0.35, 0.35, 0.35))
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	cs.shape = shape
	add_child(cs)
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = box_color
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = box_color
		mat.emission_energy_multiplier = glow
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	add_child(mi)


func get_prompt(_player) -> String:
	return "กด E เพื่อ" + prompt


func can_interact(_player) -> bool:
	return true


func interact(_player = null):
	pass


func get_hud() -> Node:
	return get_tree().get_first_node_in_group("hud")


func get_station() -> Node:
	return get_tree().get_first_node_in_group("station")
