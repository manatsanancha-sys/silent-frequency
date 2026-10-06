extends Node
## Autoload "PlayerStealth" — สถานะการซ่อนตัวของผู้เล่น (PLACEHOLDER)
## ศัตรูเช็ก PlayerStealth.is_hidden / get_noise_multiplier() ก่อนตัดสินว่าเห็น/ได้ยินผู้เล่น
##
## TODO:
## - ย่อตัว (C): ลดความสูง CollisionShape + ความเร็วใน demo_player.gd
## - เสียงฝีเท้า: เรียก NoiseBus.emit_noise ทุกก้าว ตามความเร็ว (ย่อ < เดิน < วิ่ง)
## - ความมืด: ผู้เล่นที่ปิดไฟฉายในที่มืด ถูกมองเห็นยากขึ้น

signal hidden_changed(is_hidden: bool)
signal crouch_changed(is_crouching: bool)

var is_hidden := false
var is_crouching := false
var current_spot: Node = null


func _unhandled_input(event):
	if event.is_action_pressed("Crouch"):
		set_crouching(not is_crouching)


func set_hidden(value: bool, spot: Node):
	is_hidden = value
	current_spot = spot
	hidden_changed.emit(is_hidden)


func set_crouching(value: bool):
	is_crouching = value
	crouch_changed.emit(is_crouching)


## คูณกับรัศมีเสียงฝีเท้า/ระยะมองเห็นของศัตรู
func get_noise_multiplier() -> float:
	if is_hidden:
		return 0.0
	return 0.4 if is_crouching else 1.0
