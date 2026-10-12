extends Marker3D
class_name FrequencySource
## จุดปล่อยคลื่นที่ซ่อนอยู่ — ความถี่และบทอยู่ใน Story.FREQUENCIES[freq_index]

## index ใน Story.FREQUENCIES = รหัสหลักที่ (freq_index + 1)
@export var freq_index := 0
## ระยะที่เริ่มรับสัญญาณได้ (เมตร)
@export var range_m := 7.0


func _ready():
	add_to_group("frequency_sources")


func get_mhz() -> float:
	return float(Story.FREQUENCIES[freq_index]["mhz"])
