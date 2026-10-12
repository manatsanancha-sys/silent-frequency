extends Node
## ตัวเริ่มเทส: ย้าย test_runner ไปไว้ใต้ root (ไม่ถูกลบตอนเปลี่ยนฉาก)


func _ready():
	var runner := Node.new()
	runner.name = "TestRunner"
	runner.set_script(load("res://tests/test_runner.gd"))
	get_tree().root.add_child.call_deferred(runner)
