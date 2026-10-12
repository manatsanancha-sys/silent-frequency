"""สร้าง levels/radio_station.tscn (greybox ด้วย CSG + interactables ทั้งหมดของเกม)

รัน:  python tools/gen_radio_station.py
ถ้าแก้ฉากใน Godot editor แล้ว อย่ารันซ้ำ (จะเขียนทับ) — หรือแก้ตัวเลขในไฟล์นี้แล้วรันใหม่
ผัง (มองจากบน, -Z = เหนือ):
    [ห้องรับสัญญาณ]        [ห้องหัวหน้าสถานี]
    [============ ทางเดิน ============][โถงทางออก]=ประตู=> ลานหน้าสถานี
              [ห้องเก็บของ]
"""
import math
import os

T = 0.2   # ความหนาผนัง
H = 3.0   # ความสูงห้อง

ROOMS = [  # name, label, (x0, x1, z0, z1)
    ("SignalRoom", "ห้องรับสัญญาณ", (-12.0, -4.0, -9.7, -1.7)),
    ("Corridor", "ทางเดิน", (-12.0, 12.0, -1.5, 1.5)),
    ("Storage", "ห้องเก็บของ", (-4.0, 2.0, 1.7, 7.7)),
    ("ChiefOffice", "ห้องหัวหน้าสถานี", (4.0, 12.0, -9.7, -1.7)),
    ("Lobby", "โถงประตูทางออก", (12.2, 18.0, -4.0, 4.0)),
]
DOORS = [  # name, (x, z), (sx, sz)
    ("Door_Lobby", (12.1, 0.0), (0.6, 1.6)),
    ("Door_Signal", (-8.0, -1.6), (1.6, 0.6)),
    ("Door_Chief", (8.0, -1.6), (1.6, 0.6)),
    ("Door_Storage", (-1.0, 1.6), (1.6, 0.6)),
    ("Door_Exit", (18.1, 0.0), (0.6, 1.6)),
]
PROPS = [  # name, (x, y, z), size
    ("RadioConsole", (-8.0, 0.5, -9.0), (5.0, 1.0, 1.0)),
    ("RadioRack", (-11.4, 1.0, -6.0), (1.0, 2.0, 3.0)),
    ("ChiefDesk", (8.0, 0.4, -7.0), (2.4, 0.8, 1.2)),
    ("ChiefShelf", (11.5, 1.0, -4.5), (0.8, 2.0, 2.5)),
    ("Shelf_A", (-3.4, 1.0, 4.6), (1.0, 2.0, 3.6)),
    ("Shelf_B", (-0.2, 1.0, 7.1), (2.6, 2.0, 1.0)),
    ("Crate", (1.2, 0.4, 3.0), (0.8, 0.8, 0.8)),
    ("LobbyBench", (17.3, 0.25, 2.8), (1.0, 0.5, 2.0)),
    ("LobbyCounter", (14.5, 0.55, -3.3), (3.0, 1.1, 0.8)),
    ("Porch", (21.0, -0.1, 0.0), (5.6, 0.2, 6.0)),
]
EMERGENCY_LIGHTS = [  # (x, y, z), energy
    ((-8.0, 2.7, -5.7), 0.3), ((-6.0, 2.7, 0.0), 0.22), ((6.0, 2.7, 0.0), 0.22),
    ((-1.0, 2.7, 4.7), 0.18), ((8.0, 2.7, -5.7), 0.18), ((15.0, 2.7, 0.0), 0.3),
]
POWER_LIGHTS = [((-9.5, 2.8, -5.0), 1.3), ((-6.5, 2.8, -7.5), 1.1), ((-8.0, 2.8, 0.0), 0.6)]

Y90 = "0, 0, 1, 0, 1, 0, -1, 0, 0"     # หมุน +90° รอบแกน Y (หน้า +Z → +X)
YM90 = "0, 0, -1, 0, 1, 0, 1, 0, 0"    # หมุน -90° (หน้า +Z → -X)
I3 = "1, 0, 0, 0, 1, 0, 0, 0, 1"


def tr(x, y, z, basis=I3):
    return f"Transform3D({basis}, {x:g}, {y:g}, {z:g})"


def vec(a, b, c):
    return f"Vector3({a:g}, {b:g}, {c:g})"


def col(r, g, b, a=1.0):
    return f"Color({r:g}, {g:g}, {b:g}, {a:g})"


ext = [
    ("PackedScene", "res://Game/Player/player.tscn", "player"),
    ("PackedScene", "res://Game/Enemy/enemy.tscn", "enemy"),
    ("Script", "res://Game/Level/station.gd", "station"),
    ("Script", "res://Game/UI/HUD/hud.gd", "hud"),
    ("Script", "res://Game/Interactables/pickup.gd", "pickup"),
    ("Script", "res://Game/Interactables/fuse_box.gd", "fusebox"),
    ("Script", "res://Game/Interactables/power_switch.gd", "switch"),
    ("Script", "res://Game/Interactables/tape_player.gd", "tape"),
    ("Script", "res://Game/Interactables/keypad.gd", "keypad"),
    ("Script", "res://Game/Interactables/exit_door.gd", "door"),
    ("Script", "res://Game/Interactables/hiding_spot.gd", "hide"),
    ("Script", "res://Game/Systems/FrequencyFinder/frequency_source.gd", "source"),
    ("FontFile", "res://assets/fonts/Sarabun-Regular.ttf", "font"),
    # navmesh ที่ bake ไว้แล้ว (tools/bake_navmesh.tscn) — ตั้งค่า agent อยู่ในไฟล์นั้น
    ("NavigationMesh", "res://levels/radio_station_navmesh.tres", "navmesh"),
]
SUBS = """[sub_resource type="Environment" id="Env"]
background_mode = 1
background_color = Color(0, 0, 0, 1)
ambient_light_source = 2
ambient_light_color = Color(0.3, 0.33, 0.42, 1)
ambient_light_energy = 0.06
tonemap_mode = 2
fog_enabled = true
fog_light_color = Color(0.03, 0.035, 0.05, 1)
fog_density = 0.045

[sub_resource type="StandardMaterial3D" id="Mat_Wall"]
albedo_color = Color(0.42, 0.42, 0.4, 1)
roughness = 0.95

[sub_resource type="StandardMaterial3D" id="Mat_Floor"]
albedo_color = Color(0.22, 0.21, 0.2, 1)

[sub_resource type="StandardMaterial3D" id="Mat_Prop"]
albedo_color = Color(0.28, 0.25, 0.22, 1)

[sub_resource type="StandardMaterial3D" id="Mat_Screen"]
albedo_color = Color(0.1, 0.4, 0.2, 1)
emission_enabled = true
emission = Color(0.2, 0.9, 0.4, 1)
emission_energy_multiplier = 1.4

[sub_resource type="BoxMesh" id="Mesh_Screen"]
material = SubResource("Mat_Screen")
size = Vector3(2.2, 0.45, 0.04)

[sub_resource type="BoxShape3D" id="Shape_Exit"]
size = Vector3(1.2, 2.4, 3.0)
"""

out = []
nsubs = SUBS.count("[sub_resource")
out.append(f"[gd_scene load_steps={len(ext) + nsubs + 1} format=3]\n")
for t, p, i in ext:
    out.append(f'[ext_resource type="{t}" path="{p}" id="{i}"]')
out.append("")
out.append(SUBS)


def node(name, typ=None, parent=".", extra="", props=()):
    head = f'[node name="{name}"'
    if typ:
        head += f' type="{typ}"'
    if parent is not None:
        head += f' parent="{parent}"'
    out.append(head + extra + "]")
    out.extend(props)
    out.append("")


def interactable(name, script, pos, size, color, parent="Interactables", basis=I3, glow=0.0, solid=True, extra=()):
    node(name, "StaticBody3D", parent, props=[
        f"transform = {tr(*pos, basis=basis)}",
        f'script = ExtResource("{script}")',
        f"box_size = {vec(*size)}",
        f"box_color = {col(*color)}",
        f"glow = {glow:g}",
        f"solid = {'true' if solid else 'false'}",
        *extra])


# ---------------------------------------------------------------- root
node("RadioStation", "Node3D", parent=None, props=['script = ExtResource("station")'])
node("WorldEnvironment", "WorldEnvironment", props=['environment = SubResource("Env")'])

# ---------------------------------------------------------------- geometry (อยู่ใต้ NavigationRegion3D เพื่อใช้ bake navmesh)
node("NavigationRegion3D", "NavigationRegion3D", props=['navigation_mesh = ExtResource("navmesh")'])
node("Building", "CSGCombiner3D", "NavigationRegion3D", props=["use_collision = true"])
B = "NavigationRegion3D/Building"
for name, _, (x0, x1, z0, z1) in ROOMS:
    node(f"{name}_Shell", "CSGBox3D", B, props=[
        f"transform = {tr((x0 + x1) / 2, H / 2, (z0 + z1) / 2)}",
        f"size = {vec(x1 - x0 + 2 * T, H + 2 * T, z1 - z0 + 2 * T)}",
        'material = SubResource("Mat_Wall")'])
for name, _, (x0, x1, z0, z1) in ROOMS:
    node(f"{name}_Interior", "CSGBox3D", B, props=[
        f"transform = {tr((x0 + x1) / 2, H / 2, (z0 + z1) / 2)}",
        "operation = 2",
        f"size = {vec(x1 - x0, H, z1 - z0)}"])
for name, (x, z), (sx, sz) in DOORS:
    node(name, "CSGBox3D", B, props=[
        f"transform = {tr(x, 1.15, z)}", "operation = 2", f"size = {vec(sx, 2.3, sz)}"])
# พื้นสีเข้มทับพื้นห้อง (บาง) ให้แยกพื้น/ผนังออก
for name, _, (x0, x1, z0, z1) in ROOMS:
    node(f"{name}_Floor", "CSGBox3D", B, props=[
        f"transform = {tr((x0 + x1) / 2, 0.005, (z0 + z1) / 2)}",
        f"size = {vec(x1 - x0, 0.01, z1 - z0)}",
        'material = SubResource("Mat_Floor")'])
for name, (x, y, z), (sx, sy, sz) in PROPS:
    node(name, "CSGBox3D", B, props=[
        f"transform = {tr(x, y, z)}", f"size = {vec(sx, sy, sz)}", 'material = SubResource("Mat_Prop")'])

# ---------------------------------------------------------------- lights
node("Lights", "Node3D")
for i, ((x, y, z), e) in enumerate(EMERGENCY_LIGHTS):
    node(f"Emergency_{i}", "OmniLight3D", "Lights", extra=' groups=["flicker_lights"]', props=[
        f"transform = {tr(x, y, z)}", "light_color = Color(0.85, 0.18, 0.1, 1)",
        f"light_energy = {e:g}", "omni_range = 6.5"])
for i, ((x, y, z), e) in enumerate(POWER_LIGHTS):
    node(f"Power_{i}", "OmniLight3D", "Lights", extra=' groups=["power_lights", "flicker_lights"]', props=[
        f"transform = {tr(x, y, z)}", "visible = false", "light_color = Color(1, 0.85, 0.6, 1)",
        f"light_energy = {e:g}", "shadow_enabled = true", "omni_range = 7.5"])
node("Moonlight", "OmniLight3D", "Lights", props=[
    f"transform = {tr(21.5, 3.0, 0.0)}", "light_color = Color(0.45, 0.55, 0.85, 1)",
    "light_energy = 0.7", "omni_range = 9.0"])
node("ConsoleScreen", "MeshInstance3D", "Lights", extra=' groups=["power_screens"]', props=[
    f"transform = {tr(-8.0, 1.3, -9.45)}", "visible = false", 'mesh = SubResource("Mesh_Screen")'])

# ป้ายชื่อห้อง (จางๆ ใกล้เพดาน)
node("RoomLabels", "Node3D")
for name, label, (x0, x1, z0, z1) in ROOMS:
    node(f"Label_{name}", "Label3D", "RoomLabels", props=[
        f"transform = {tr((x0 + x1) / 2, 2.55, (z0 + z1) / 2)}",
        "billboard = 1", "modulate = Color(0.85, 0.8, 0.7, 0.3)",
        'font = ExtResource("font")', "font_size = 40", f'text = "{label}"'])

# ---------------------------------------------------------------- markers
node("PlayerSpawn", "Marker3D", props=[f"transform = {tr(-8.0, 0.05, -4.5)}"])
node("EnemySpawn", "Marker3D", props=[f"transform = {tr(15.5, 0.05, 2.0)}"])
node("DebugExitPoint", "Marker3D", props=[f"transform = {tr(16.3, 0.05, 0.0, basis=YM90)}"])
node("Waypoints", "Node3D")
for i, (x, z) in enumerate([(-8, -5.5), (-9, 0), (-1, 4.5), (0, 0), (8, -5.5), (8, 0), (15, 0), (15, -1.5)]):
    node(f"WP{i}", "Marker3D", "Waypoints", props=[f"transform = {tr(x, 0.05, z)}"])

# ---------------------------------------------------------------- actors
node("Player", None, extra=' instance=ExtResource("player")', props=[f"transform = {tr(-8.0, 0.05, -4.5)}"])
node("Enemy", None, extra=' instance=ExtResource("enemy")', props=[f"transform = {tr(15.5, 0.05, 2.0)}"])
node("HUD", "CanvasLayer", props=['script = ExtResource("hud")'])

# ---------------------------------------------------------------- interactables
node("Interactables", "Node3D")
PAPER = (0.85, 0.8, 0.65)
TAPE = (0.15, 0.13, 0.12)
BATT = (0.95, 0.75, 0.15)
# ปริศนา 1
interactable("Fuse", "pickup", (7.3, 0.86, -7.0), (0.12, 0.12, 0.32), (0.95, 0.6, 0.15), glow=0.6, solid=False,
             extra=["kind = 1", 'item_id = "fuse"'])
interactable("FuseBox", "fusebox", (1.88, 1.4, 4.4), (0.2, 0.8, 0.6), (0.35, 0.37, 0.4))
interactable("PowerSwitch", "switch", (-11.88, 1.4, -3.0), (0.2, 0.5, 0.35), (0.6, 0.12, 0.08), glow=0.3)
# ปริศนา 3 — บันทึก/เทป
interactable("Doc0_EkLogbook", "pickup", (-9.6, 1.03, -9.0), (0.32, 0.04, 0.24), PAPER, glow=0.25, solid=False,
             extra=["kind = 2", "doc_index = 0", 'item_id = "doc0"'])
interactable("Doc1_NiphonLog", "pickup", (-2.2, 0.03, 6.6), (0.3, 0.03, 0.22), PAPER, glow=0.25, solid=False,
             extra=["kind = 2", "doc_index = 1", 'item_id = "doc1"'])
interactable("Doc2_EkTape", "pickup", (17.3, 0.53, 2.6), (0.12, 0.03, 0.08), TAPE, glow=0.5, solid=False,
             extra=["kind = 2", "doc_index = 2", 'item_id = "doc2"'])
interactable("Doc3_ChiefTape", "pickup", (10.8, 0.03, -2.4), (0.12, 0.03, 0.08), TAPE, glow=0.5, solid=False,
             extra=["kind = 2", "doc_index = 3", 'item_id = "doc3"'])
interactable("TapePlayer", "tape", (8.7, 0.92, -7.1), (0.45, 0.24, 0.3), (0.12, 0.12, 0.13), glow=0.1)
# ประตูทางออก
interactable("Keypad", "keypad", (17.88, 1.35, 1.3), (0.2, 0.35, 0.25), (0.15, 0.5, 0.2), glow=0.6,
             extra=['door_path = NodePath("../../ExitDoor")'])
# แบตเตอรี่ 4 จุด
for i, pos in enumerate([(14.5, 1.18, -3.3), (1.2, 0.88, 3.0), (6.0, 0.08, 1.1), (6.6, 0.08, -9.3)]):
    interactable(f"Battery_{i}", "pickup", pos, (0.1, 0.15, 0.1), BATT, glow=0.8, solid=False,
                 extra=["kind = 0", f'item_id = "battery{i}"'])
# จุดซ่อนตัว 4 จุด (ด้านหน้าตู้ = +Z ของตู้)
interactable("Hide_CorridorLocker", "hide", (-11.6, 1.05, 0.7), (1.0, 2.1, 0.7), (0.2, 0.3, 0.27), basis=Y90)
interactable("Hide_SignalDesk", "hide", (-4.6, 0.4, -4.6), (1.6, 0.8, 0.9), (0.3, 0.22, 0.15), basis=YM90,
             extra=["view_offset = Vector3(0, 0.45, 0.1)", "is_under_desk = true"])
interactable("Hide_StorageLocker", "hide", (1.6, 1.05, 6.0), (1.0, 2.1, 0.7), (0.2, 0.3, 0.27), basis=YM90)
interactable("Hide_ChiefWardrobe", "hide", (5.2, 1.1, -9.25), (1.2, 2.2, 0.8), (0.25, 0.17, 0.1),
             extra=["view_offset = Vector3(0, 1.5, 0.25)"])

# คลื่นที่ซ่อนอยู่ 3 คลื่น (ปริศนา 2)
node("FrequencySources", "Node3D")
for i, (pos, rng) in enumerate([((-8.0, 1.2, -8.5), 7.0), ((5.0, 1.5, 0.0), 6.0), ((-1.0, 1.2, 6.5), 6.0)]):
    node(f"Source_{i}", "Marker3D", "FrequencySources", props=[
        f"transform = {tr(*pos)}", 'script = ExtResource("source")', f"freq_index = {i}", f"range_m = {rng:g}"])

# ประตูทางออก + จุดชนะ
node("ExitDoor", "StaticBody3D", props=[f"transform = {tr(18.1, 0.0, 0.0)}", 'script = ExtResource("door")',
                                     "size = Vector3(0.15, 2.3, 1.6)"])
node("ExitTrigger", "Area3D", "ExitDoor", props=[f"transform = {tr(2.4, 1.2, 0.0)}"])
node("CollisionShape3D", "CollisionShape3D", "ExitDoor/ExitTrigger", props=['shape = SubResource("Shape_Exit")'])

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "levels", "radio_station.tscn")
with open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(out))
print("wrote", os.path.normpath(path), len(out), "lines")
