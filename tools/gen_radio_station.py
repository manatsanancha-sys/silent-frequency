"""Generate levels/radio_station.tscn (greybox, CSG).

ใช้สร้างฉากครั้งแรกเท่านั้น — ถ้าแก้ฉากใน Godot editor แล้วอย่ารันซ้ำ (จะเขียนทับ)
"""
T = 0.2      # wall thickness
H = 3.0      # room height

# name, label, (x0, x1, z0, z1)
rooms = [
    ("Lobby",      "Lobby\nห้องโถงทางเข้า",            (12.2, 18.0, -4.0, 4.0)),
    ("Corridor",   "Corridor\nทางเดิน",                  (-12.0, 12.0, -1.5, 1.5)),
    ("SignalRoom", "Signal Room\nห้องรับสัญญาณ",         (-12.0, -4.0, -9.7, -1.7)),
    ("ChiefOffice", "Chief's Office\nห้องหัวหน้าสถานี",  (4.0, 12.0, -9.7, -1.7)),
    ("Storage",    "Storage\nห้องเก็บของ",               (-4.0, 2.0, 1.7, 7.7)),
]
# name, center (x, z), size (sx, sz)  — door 1.2 wide x 2.2 high
doors = [
    ("Door_Lobby",   (12.1, 0.0), (0.6, 1.2)),
    ("Door_Signal",  (-8.0, -1.6), (1.2, 0.6)),
    ("Door_Chief",   (8.0, -1.6), (1.2, 0.6)),
    ("Door_Storage", (-1.0, 1.6), (1.2, 0.6)),
]
# furniture (union after carving): name, center (x, y, z), size
props = [
    ("RadioConsole", (-8.0, 0.5, -9.0), (5.0, 1.0, 1.0)),
    ("RadioRack",    (-11.4, 1.0, -6.0), (1.0, 2.0, 3.0)),
    ("ChiefDesk",    (8.0, 0.4, -7.0), (2.4, 0.8, 1.2)),
    ("ChiefShelf",   (11.5, 1.0, -4.0), (0.8, 2.0, 2.5)),
    ("Shelf_A",      (-3.4, 1.0, 5.0), (1.0, 2.0, 4.0)),
    ("Shelf_B",      (0.0, 1.0, 7.1), (3.0, 2.0, 1.0)),
    ("Crate_1",      (1.2, 0.4, 3.0), (0.8, 0.8, 0.8)),
    ("LobbyBench",   (17.3, 0.25, 2.5), (1.0, 0.5, 2.5)),
]
lights = [
    ("Light_Lobby",   (15.0, 2.7, 0.0),  1.0),
    ("Light_Corridor", (0.0, 2.7, 0.0),  0.4),
    ("Light_Signal",  (-8.0, 2.7, -5.7), 0.6),
    ("Light_Chief",   (8.0, 2.7, -5.7),  0.3),
    ("Light_Storage", (-1.0, 2.7, 4.7),  0.2),
]


def tr(x, y, z):
    return f"Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})"


def vec(a, b, c):
    return f"Vector3({a:g}, {b:g}, {c:g})"


out = []
ext = [
    ('PackedScene', 'res://DemoPlayer/demo_player.tscn', '1_player'),
    ('PackedScene', 'res://Game/Enemy/enemy.tscn', '2_enemy'),
    ('Script', 'res://Game/Systems/FrequencyFinder/frequency_finder.gd', '3_finder'),
    ('Script', 'res://Game/Systems/FrequencyFinder/frequency_source.gd', '4_source'),
    ('Script', 'res://Game/Systems/Hiding/hiding_spot.gd', '5_hide'),
    ('PackedScene', 'res://Interaction/Items/CollectibleItem.tscn', '6_collect'),
    ('Script', 'res://Interaction/Items/PowerCell/power_cell.gd', '7_cell'),
    ('Script', 'res://Inventory/ItemResource.gd', '8_itemres'),
    ('Texture2D', 'res://Interaction/Items/PowerCell/power_cell.png', '9_celltex'),
]
subs = """[sub_resource type="Environment" id="Env"]
background_mode = 1
background_color = Color(0, 0, 0, 1)
ambient_light_source = 2
ambient_light_color = Color(0.35, 0.4, 0.5, 1)
ambient_light_energy = 0.08
tonemap_mode = 2
fog_enabled = true
fog_light_color = Color(0.05, 0.06, 0.08, 1)
fog_density = 0.03

[sub_resource type="StandardMaterial3D" id="Mat_Wall"]
albedo_color = Color(0.55, 0.55, 0.55, 1)

[sub_resource type="StandardMaterial3D" id="Mat_Prop"]
albedo_color = Color(0.3, 0.32, 0.35, 1)

[sub_resource type="StandardMaterial3D" id="Mat_Locker"]
albedo_color = Color(0.2, 0.35, 0.3, 1)

[sub_resource type="BoxMesh" id="Mesh_Locker"]
material = SubResource("Mat_Locker")
size = Vector3(1, 2.1, 0.7)

[sub_resource type="BoxShape3D" id="Shape_Locker"]
size = Vector3(1, 2.1, 0.7)

[sub_resource type="StandardMaterial3D" id="Mat_Battery"]
albedo_color = Color(0.9, 0.75, 0.1, 1)
emission_enabled = true
emission = Color(0.4, 0.3, 0, 1)

[sub_resource type="BoxMesh" id="Mesh_Battery"]
material = SubResource("Mat_Battery")
size = Vector3(0.15, 0.3, 0.15)

[sub_resource type="BoxShape3D" id="Shape_Battery"]
size = Vector3(0.3, 0.4, 0.3)

[sub_resource type="Resource" id="Item_PowerCell"]
script = ExtResource("8_itemres")
item_name = "Power Cell"
texture = ExtResource("9_celltex")
quantity = 1
description = "แบตเตอรี่สำรองสำหรับไฟฉาย กด Use เพื่อชาร์จ"

[sub_resource type="SphereMesh" id="Mesh_Source"]
radius = 0.15
height = 0.3
"""
nsubs = subs.count("[sub_resource")
out.append(f'[gd_scene load_steps={len(ext) + nsubs + 1} format=3]\n')
for t, p, i in ext:
    out.append(f'[ext_resource type="{t}" path="{p}" id="{i}"]')
out.append("")
out.append(subs)


def node(name, typ=None, parent=".", extra="", props_=()):
    head = f'[node name="{name}"'
    if typ:
        head += f' type="{typ}"'
    if parent is not None:
        head += f' parent="{parent}"'
    head += extra + "]"
    out.append(head)
    out.extend(props_)
    out.append("")


node("RadioStation", "Node3D", parent=None)
node("WorldEnvironment", "WorldEnvironment", props_=['environment = SubResource("Env")'])
node("Building", "CSGCombiner3D", props_=["use_collision = true"])

for name, _, (x0, x1, z0, z1) in rooms:
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    node(f"{name}_Shell", "CSGBox3D", "Building", props_=[
        f"transform = {tr(cx, H / 2, cz)}",
        f"size = {vec(x1 - x0 + 2 * T, H + 2 * T, z1 - z0 + 2 * T)}",
        'material = SubResource("Mat_Wall")'])
for name, _, (x0, x1, z0, z1) in rooms:
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    node(f"{name}_Interior", "CSGBox3D", "Building", props_=[
        f"transform = {tr(cx, H / 2, cz)}",
        "operation = 2",
        f"size = {vec(x1 - x0, H, z1 - z0)}"])
for name, (x, z), (sx, sz) in doors:
    node(name, "CSGBox3D", "Building", props_=[
        f"transform = {tr(x, 1.1, z)}",
        "operation = 2",
        f"size = {vec(sx, 2.2, sz)}"])
for name, (x, y, z), (sx, sy, sz) in props:
    node(name, "CSGBox3D", "Building", props_=[
        f"transform = {tr(x, y, z)}",
        f"size = {vec(sx, sy, sz)}",
        'material = SubResource("Mat_Prop")'])

node("Lights", "Node3D")
for name, (x, y, z), e in lights:
    node(name, "OmniLight3D", "Lights", props_=[
        f"transform = {tr(x, y, z)}",
        "light_color = Color(1, 0.8, 0.55, 1)",
        f"light_energy = {e:g}",
        "shadow_enabled = true",
        "omni_range = 6.0"])

node("RoomLabels", "Node3D")
for name, label, (x0, x1, z0, z1) in rooms:
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    node(f"Label_{name}", "Label3D", "RoomLabels", props_=[
        f"transform = {tr(cx, 2.4, cz)}",
        "billboard = 1",
        "modulate = Color(1, 1, 1, 0.35)",
        "font_size = 48",
        f'text = "{label}"'])

# Player — spawn in lobby, facing -X (toward the corridor)
node("DemoPlayer", None, extra=' groups=["player"] instance=ExtResource("1_player")', props_=[
    "transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 16, 1.1, 0)"])
node("FrequencyFinder", "Node", "DemoPlayer", props_=['script = ExtResource("3_finder")'])

# Gameplay placeholders
node("Gameplay", "Node3D")
node("FrequencySource_01", "Marker3D", "Gameplay", props_=[
    f"transform = {tr(-8, 1.2, -8.8)}",
    'script = ExtResource("4_source")',
    "frequency_mhz = 98.6",
    'message = "...สถานีนี้... ยังมีใครอยู่ไหม..."'])
node("DebugMesh", "MeshInstance3D", "Gameplay/FrequencySource_01", props_=['mesh = SubResource("Mesh_Source")'])

for i, (x, z) in enumerate([(1.4, 5.0), (5.0, -9.2)], 1):
    node(f"HidingSpot_{i:02d}", "StaticBody3D", "Gameplay", props_=[
        f"transform = {tr(x, 1.05, z)}",
        "collision_layer = 9",
        'script = ExtResource("5_hide")'])
    node("CollisionShape3D", "CollisionShape3D", f"Gameplay/HidingSpot_{i:02d}", props_=['shape = SubResource("Shape_Locker")'])
    node("Mesh", "MeshInstance3D", f"Gameplay/HidingSpot_{i:02d}", props_=['mesh = SubResource("Mesh_Locker")'])

for i, (x, y, z) in enumerate([(14.0, 0.15, -3.0), (1.2, 0.95, 3.0), (-6.0, 1.15, -9.0)], 1):
    n = f"Battery_{i:02d}"
    node(n, None, "Gameplay", extra=' instance=ExtResource("6_collect")', props_=[
        f"transform = {tr(x, y, z)}",
        'script = ExtResource("7_cell")',
        'item = SubResource("Item_PowerCell")'])
    node("CollisionShape3D", None, f"Gameplay/{n}", props_=['shape = SubResource("Shape_Battery")'])
    node("Mesh", "MeshInstance3D", f"Gameplay/{n}", props_=['mesh = SubResource("Mesh_Battery")'])

# Enemy + patrol route (straight lines that pass through the doorways)
node("PatrolPoints", "Node3D", "Gameplay")
route = [(-8, 0), (-8, -6), (-8, 0), (8, 0), (8, -6), (8, 0)]
for i, (x, z) in enumerate(route, 1):
    node(f"P{i}", "Marker3D", "Gameplay/PatrolPoints", props_=[f"transform = {tr(x, 0, z)}"])
paths = ", ".join(f'NodePath("../PatrolPoints/P{i}")' for i in range(1, len(route) + 1))
node("Enemy", None, "Gameplay", extra=' node_paths=PackedStringArray("patrol_points") instance=ExtResource("2_enemy")', props_=[
    f"transform = {tr(-2, 0.05, 0)}",
    f"patrol_points = [{paths}]"])

import os
open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "levels", "radio_station.tscn"), "w", encoding="utf-8", newline="\n").write("\n".join(out))
print("ok", len(out))
