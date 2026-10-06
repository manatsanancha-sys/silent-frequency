extends InteractionBase
class_name HidingSpot
## จุดซ่อนตัว (ตู้ล็อกเกอร์ / ใต้โต๊ะ) — PLACEHOLDER
## กด E เพื่อเข้า/ออก ระหว่างซ่อน ศัตรูมองไม่เห็น (ยกเว้นเห็นตอนกำลังเข้าไป)
##
## TODO:
## - ย้ายกล้องผู้เล่นไปที่ hide_point + ล็อกการเดิน (demo_player.gd ยังไม่มีโหมด HIDDEN)
## - แอนิเมชันเปิด/ปิดประตูตู้ + เสียง (ส่ง NoiseBus เบาๆ)
## - กลไกกลั้นหายใจตอนศัตรูอยู่ใกล้ (QTE/มิเตอร์)

signal player_entered(spot: HidingSpot)
signal player_exited(spot: HidingSpot)

## ตำแหน่งที่กล้องผู้เล่นจะไปอยู่ตอนซ่อน (ถ้าว่าง ใช้ตำแหน่งของ node นี้)
@export var hide_point: Node3D
## ถ้าศัตรูเห็นตอนกำลังเข้า ศัตรูจะรู้ว่าซ่อนอยู่ที่นี่
@export var noise_on_enter := 2.0

var occupant: Node = null


func _ready():
	add_to_group("hiding_spots")


func interact(parameters = null):
	if occupant == null:
		enter(parameters)
	else:
		exit()


func enter(player):
	occupant = player
	PlayerStealth.set_hidden(true, self)
	NoiseBus.emit_noise(global_position, noise_on_enter, self)
	player_entered.emit(self)
	Inventory.display_interaction_info("ซ่อนตัว (กด E อีกครั้งเพื่อออก)")
	# TODO: ซ่อนตัวละคร/ย้ายกล้อง/ล็อก movement


func exit():
	occupant = null
	PlayerStealth.set_hidden(false, null)
	player_exited.emit(self)
	# TODO: คืนกล้อง/ปลดล็อก movement
