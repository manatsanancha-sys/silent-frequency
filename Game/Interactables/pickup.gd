extends Interactable
class_name Pickup
## ของที่เก็บได้: แบตเตอรี่, ฟิวส์, บันทึก/เทป

enum Kind { BATTERY, FUSE, DOCUMENT }

@export var kind: Kind = Kind.BATTERY
## ใช้เมื่อ kind = DOCUMENT → index ใน Story.DOCUMENTS
@export var doc_index := 0


func _setup():
	if item_id != "" and GameState.is_taken(item_id):
		queue_free()
		return
	match kind:
		Kind.BATTERY:
			prompt = "เก็บแบตเตอรี่"
		Kind.FUSE:
			prompt = "เก็บฟิวส์"
		Kind.DOCUMENT:
			var doc: Dictionary = Story.DOCUMENTS[doc_index]
			prompt = ("อ่าน: " if doc["kind"] == "note" else "เก็บ") + doc["title"]


func interact(player = null):
	match kind:
		Kind.BATTERY:
			if player and not player.add_spare_battery():
				GameState.toast("ถือแบตสำรองเต็มแล้ว")
				return
			GameState.toast("เก็บแบตเตอรี่สำรอง (มี %d ก้อน)" % int(GameState.data["spare_batteries"]))
		Kind.FUSE:
			GameState.add_item("fuse")
			GameState.toast("ได้ฟิวส์ — นำไปใส่ตู้ฟิวส์ในห้องเก็บของ")
		Kind.DOCUMENT:
			_collect_document(player)
	Audio.play_sfx("pickup", -4.0)
	if item_id != "":
		GameState.mark_taken(item_id)
	GameState.notify_progress()
	queue_free()


func _collect_document(player):
	if not (doc_index in GameState.data["docs_found"]):
		GameState.data["docs_found"].append(doc_index)
	var doc: Dictionary = Story.DOCUMENTS[doc_index]
	if item_id != "":
		GameState.mark_taken(item_id)
	GameState.save_checkpoint(player)
	if doc["kind"] == "note":
		Audio.play_sfx("paper", -2.0)
		var hud := get_hud()
		if hud:
			hud.show_note(doc["title"], GameState.format_story(doc["text"]))
	else:
		GameState.toast("ได้เทปคาสเซ็ต — เปิดฟังที่เครื่องเล่นเทปในห้องหัวหน้าสถานี")
