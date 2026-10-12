extends Interactable
## สวิตช์ไฟหลักในห้องรับสัญญาณ (ปริศนาที่ 1 ขั้นสุดท้าย) — เปิดแล้วไฟติด ศัตรูตื่น


func get_prompt(_player) -> String:
	if GameState.data["power_on"]:
		return "สวิตช์ไฟหลัก — เปิดอยู่"
	if GameState.data["fuse_inserted"]:
		return "กด E เพื่อเปิดสวิตช์ไฟหลัก"
	return "สวิตช์ไฟหลัก — ไม่มีไฟเข้า (ตู้ฟิวส์ในห้องเก็บของ)"


func can_interact(_player) -> bool:
	return GameState.data["fuse_inserted"] and not GameState.data["power_on"]


func interact(player = null):
	GameState.data["power_on"] = true
	Audio.play_sfx_3d("switch_on", global_position, 2.0)
	var station := get_station()
	if station:
		station.apply_power(true, true)
	GameState.show_subtitles([
		["ไฟติดแล้ว... เครื่องส่งสัญญาณเริ่มทำงานเอง", 3.5],
		["เปิดเครื่องรับสัญญาณ (Tab) แล้วลองจูนหาคลื่นดู", 4.0],
		["...ได้ยินเสียงอะไรบางอย่างที่ประตูหน้า", 3.5],
	])
	GameState.notify_progress()
	GameState.save_checkpoint(player)
