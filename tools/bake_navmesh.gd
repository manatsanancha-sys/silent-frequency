extends Node
## Bake navmesh ของ levels/radio_station.tscn แล้วเซฟเป็น levels/radio_station_navmesh.tres
## รัน: godot --headless --path . res://tools/bake_navmesh.tscn
## (ต้องรันใหม่ทุกครั้งที่แก้ผนัง/เฟอร์นิเจอร์ — ถ้าไม่รัน เกมจะ bake ตอนเริ่มด่านให้เองแต่ช้ากว่า)

const OUT := "res://levels/radio_station_navmesh.tres"


func _ready():
	var level: Node = load("res://levels/radio_station.tscn").instantiate()
	add_child(level)
	for i in 5:
		await get_tree().process_frame
	var region: NavigationRegion3D = level.get_node("NavigationRegion3D")
	var nm := NavigationMesh.new()
	var src: NavigationMesh = region.navigation_mesh
	for p in ["geometry_parsed_geometry_type", "geometry_collision_mask", "agent_height", "agent_radius", "agent_max_climb", "cell_size", "cell_height"]:
		nm.set(p, src.get(p))
	region.navigation_mesh = nm
	region.bake_navigation_mesh(false)
	print("polygons: ", nm.get_polygon_count())
	var err := ResourceSaver.save(nm, OUT)
	print("saved ", OUT, " err=", err)
	get_tree().quit()
