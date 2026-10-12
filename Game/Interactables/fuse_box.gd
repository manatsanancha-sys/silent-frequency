extends Interactable
## ตู้ฟิวส์ในห้องเก็บของ (ปริศนาที่ 1 ขั้นที่ 2)


func get_prompt(_player) -> String:
	if GameState.data["fuse_inserted"]:
		return "ตู้ฟิวส์ — ใส่ฟิวส์แล้ว ไปเปิดสวิตช์ไฟหลักที่ห้องรับสัญญาณ"
	if GameState.has_item("fuse"):
		return "กด E เพื่อใส่ฟิวส์"
	return "ตู้ฟิวส์ — ช่องฟิวส์ว่างอยู่ (ต้องหาฟิวส์)"


func can_interact(_player) -> bool:
	return GameState.has_item("fuse") and not GameState.data["fuse_inserted"]


func interact(player = null):
	GameState.remove_item("fuse")
	GameState.data["fuse_inserted"] = true
	Audio.play_sfx_3d("fuse_insert", global_position)
	GameState.toast("ใส่ฟิวส์แล้ว")
	GameState.notify_progress()
	GameState.save_checkpoint(player)
	var mi := get_node_or_null("Mesh") as MeshInstance3D
	if mi:
		var mat := (mi.mesh.material as StandardMaterial3D).duplicate()
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.8, 0.3)
		mat.emission_energy_multiplier = 0.6
		mi.material_override = mat
