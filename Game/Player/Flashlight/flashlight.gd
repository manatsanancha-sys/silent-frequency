extends Camera3D
## ไฟฉายแบตจำกัด — ดัดแปลงจาก Interaction/Items/Camcorder/camcorder.gd
## - ตัดโหมด night vision / REC / zoom ออก เหลือแค่ เปิด-ปิดไฟ
## - แบตเป็นตัวเลข 0-100 ลดลงใน _process ตอนเปิดไฟ (แทน Animation "Decrease Energy" เดิม)
## - แบตต่ำจะกระพริบ, หมดแล้วไฟดับ ต้องใช้ Power Cell จาก inventory ชาร์จ
## ใช้ node UI เดิมของ camcorder.tscn (flashlight.tscn สืบทอดจากฉากนั้น)

signal battery_changed(percent: float)
signal battery_depleted

@onready var light: SpotLight3D = $SpotLight3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var batteries_label: Label = $UIContainer/EnergyContainer/FlowContainer/BatteriesLabel
@onready var battery_bar: ProgressBar = $UIContainer/EnergyContainer/FlowContainer/ProgressBar
@onready var recording_container: Control = $UIContainer/RecordingContainer
@onready var night_vision_mesh: MeshInstance3D = $NightVisionMesh
@onready var timer: Timer = $Timer

@export var max_battery := 100.0
## % ต่อวินาทีตอนเปิดไฟ (100 / 1.0 = ใช้ได้ ~100 วินาทีต่อแบตหนึ่งก้อน)
@export var drain_per_second := 1.0
@export var max_light_energy := 3.0
@export var low_battery_threshold := 20.0
@export var spare_battery_limit := 8

var battery := max_battery
var is_on := false


func _ready():
	battery = max_battery
	# ปิดส่วนของกล้องเดิมที่ไฟฉายไม่ใช้
	animation_player.stop()
	timer.stop()
	recording_container.visible = false
	night_vision_mesh.visible = false
	Inventory.add_new_item.connect(update_power_cells)
	Inventory.update_item.connect(update_power_cells)
	Inventory.item_removed.connect(func(): update_power_cells(null))
	update_power_cells(null)
	set_on(false)
	_update_ui()


func _process(delta):
	if not is_on:
		return
	battery = max(battery - drain_per_second * delta, 0.0)
	if battery <= 0.0:
		set_on(false)
		battery_depleted.emit()
	_update_light(delta)
	_update_ui()


func _input(event):
	if event.is_action_pressed("ToggleLight"):
		if battery <= 0.0:
			try_to_recharge()
		set_on(not is_on and battery > 0.0)


func set_on(value: bool):
	is_on = value
	light.visible = is_on
	# TODO: เล่นเสียงคลิกไฟฉาย + แจ้ง NoiseBus (เสียงเบามาก) ถ้าต้องการให้ศัตรูได้ยิน


func _update_light(delta):
	var ratio := battery / max_battery
	light.light_energy = max_light_energy * clamp(ratio * 2.0, 0.3, 1.0)
	if battery < low_battery_threshold:
		# กระพริบแบบสุ่มเมื่อแบตต่ำ
		light.visible = randf() > 0.08 + (1.0 - battery / low_battery_threshold) * 0.25
	else:
		light.visible = true


func _update_ui():
	battery_bar.value = battery / max_battery * 100.0
	battery_changed.emit(battery_bar.value)


func update_power_cells(item):
	if item and item.item_name != "Power Cell":
		return
	var power_cells = Inventory.get_item("Power Cell")
	var quantity = power_cells.quantity if power_cells else 0
	batteries_label.text = "Battery %d/%d" % [quantity, spare_battery_limit]


## เรียกจาก Power Cell (ปุ่ม Use ใน inventory) หรือกด Q ตอนแบตหมด
func try_to_recharge() -> bool:
	var power_cells = Inventory.get_item("Power Cell")
	if not power_cells or power_cells.quantity <= 0:
		return false
	Inventory.remove_item(power_cells.item_name, 1)
	battery = max_battery
	_update_ui()
	return true
