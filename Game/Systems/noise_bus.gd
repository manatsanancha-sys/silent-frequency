extends Node
## Autoload "NoiseBus" — ช่องกลางสำหรับ "เสียง" ในเกม
## ใครทำเสียง (เดิน/วิ่ง/ทำของตก/วิทยุดัง) ให้เรียก NoiseBus.emit_noise(...)
## ศัตรูฟัง signal noise_emitted แล้วตัดสินใจเองว่าได้ยินไหม (ดู enemy_ai.gd: _on_noise_emitted)

signal noise_emitted(position: Vector3, loudness: float, source: Node)


## loudness = รัศมีที่ได้ยิน (เมตร) โดยประมาณ
func emit_noise(position: Vector3, loudness: float, source: Node = null):
	noise_emitted.emit(position, loudness, source)
