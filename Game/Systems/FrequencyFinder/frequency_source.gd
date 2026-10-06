extends Marker3D
class_name FrequencySource
## จุดปล่อยสัญญาณที่ Frequency Finder ตามหา (วางในฉาก เช่น ห้องรับสัญญาณ)
## TODO: ผูกกับเนื้อเรื่อง — เมื่อจูนเจอให้ปลดล็อกข้อความ/ประตู/เหตุการณ์

signal tuned_in(source: FrequencySource)

## ความถี่ของสัญญาณ (MHz) — ผู้เล่นต้องจูนให้ตรง
@export var frequency_mhz := 98.6
## ระยะที่เริ่มได้ยิน (เมตร)
@export var range_m := 25.0
## ข้อความ/ไฟล์เสียงที่จะเล่นเมื่อจูนเจอ (placeholder)
@export_multiline var message := "...ได้ยินฉันไหม..."
@export var found := false


func _ready():
	add_to_group("frequency_sources")


func on_tuned_in():
	if found:
		return
	found = true
	tuned_in.emit(self)
	# TODO: เล่นเสียง message, บันทึกความคืบหน้า, ทำให้ศัตรูได้ยิน (NoiseBus)
	print("[FrequencySource] tuned in: %.1f MHz — %s" % [frequency_mhz, message])
