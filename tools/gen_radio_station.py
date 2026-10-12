"""สร้าง levels/radio_station.tscn (greybox ด้วย CSG + interactables ทั้งหมดของเกม)

รัน:  python tools/gen_radio_station.py   แล้วต่อด้วย bake navmesh:
      godot --headless --path . res://tools/bake_navmesh.tscn
ถ้าแก้ฉากใน Godot editor แล้ว อย่ารันซ้ำ (จะเขียนทับ) — หรือแก้ตัวเลขในไฟล์นี้แล้วรันใหม่
ผัง (มองจากบน, -Z = เหนือ):
    [ห้องรับสัญญาณ]        [ห้องหัวหน้าสถานี]
    [============ ทางเดิน ============][โถงทางออก]=ประตู=> ลานหน้าสถานี
              [ห้องเก็บของ]

พิกัดในไฟล์นี้เขียนเป็น "หน่วยผังเดิม" (ก่อนขยาย) แล้วแปลงด้วย M() :
- ห้องทุกห้องขยาย SCALE เท่ารอบจุดกำเนิด (ห้องยังติดกันเหมือนเดิม)
- ของที่อยู่ชิดผนัง (ไม่เกิน SNAP ม.) จะชิดผนังใหม่ในระยะเดิม (ตู้ฟิวส์ สวิตช์ แป้นรหัส ตู้ซ่อน)
- ของที่อยู่กลางห้องจะขยายตำแหน่งตามสัดส่วนห้อง
"""
import os

SCALE = 1.5   # ขยายห้อง (กว้าง x ยาว)
SNAP = 0.9    # ระยะชิดผนังที่ถือว่า "ติดผนัง"
T = 0.2       # ความหนาผนัง
H = 3.0       # ความสูงห้อง
DOOR_W = 2.2  # ความกว้างช่องประตู (ศัตรู radius 0.35, navmesh agent radius 0.5)
DOOR_H = 2.6  # ความสูงช่องประตู (ศัตรูสูง ~2.0)

ROOMS_OLD = [  # name, label, (x0, x1, z0, z1) ผังเดิม
    ("SignalRoom", "ห้องรับสัญญาณ", (-12.0, -4.0, -9.7, -1.7)),
    ("Corridor", "ทางเดิน", (-12.0, 12.0, -1.5, 1.5)),
    ("Storage", "ห้องเก็บของ", (-4.0, 2.0, 1.7, 7.7)),
    ("ChiefOffice", "ห้องหัวหน้าสถานี", (4.0, 12.0, -9.7, -1.7)),
    ("Lobby", "โถงประตูทางออก", (12.2, 18.0, -4.0, 4.0)),
]
ROOMS = [(n, l, tuple(v * SCALE for v in b)) for n, l, b in ROOMS_OLD]


def _room_of(x, z):
    for i, (_, _, (x0, x1, z0, z1)) in enumerate(ROOMS_OLD):
        if x0 - 0.05 <= x <= x1 + 0.05 and z0 - 0.05 <= z <= z1 + 0.05:
            return i
    return -1


def _axis(v, a0, a1):
    n0, n1 = a0 * SCALE, a1 * SCALE
    if v - a0 < SNAP:
        return n0 + (v - a0)
    if a1 - v < SNAP:
        return n1 - (a1 - v)
    c_old, c_new = (a0 + a1) / 2, (n0 + n1) / 2
    return c_new + (v - c_old) * SCALE


def M(x, z):
    """แปลงพิกัดผังเดิม → ผังใหม่"""
    i = _room_of(x, z)
    if i < 0:
        return x * SCALE, z * SCALE
    _, _, (x0, x1, z0, z1) = ROOMS_OLD[i]
    return round(_axis(x, x0, x1), 3), round(_axis(z, z0, z1), 3)


def P(x, y, z):
    nx, nz = M(x, z)
    return nx, y, nz


def room_new(name):
    for n, _, b in ROOMS:
        if n == name:
            return b


DOORS = [  # name, (x, z) ผังเดิม (กึ่งกลางผนัง), แกนที่ประตูทะลุ
    ("Door_Lobby", (12.1, 0.0), "x"),
    ("Door_Signal", (-8.0, -1.6), "z"),
    ("Door_Chief", (8.0, -1.6), "z"),
    ("Door_Storage", (-1.0, 1.6), "z"),
]
EXIT_X = room_new("Lobby")[1] + T / 2   # ประตูทางออกอยู่กลางผนังตะวันออกของโถง

PROPS = [  # name, (x, y, z) ผังเดิม, size (เมตร — ไม่ขยายตาม ยกเว้นระบุ)
    ("RadioConsole", (-8.0, 0.5, -9.0), (7.0, 1.0, 1.0)),
    ("RadioRack", (-11.4, 1.0, -6.0), (1.0, 2.0, 3.0)),
    ("ChiefDesk", (8.0, 0.4, -7.0), (3.4, 0.8, 1.4)),
    ("ChiefShelf", (11.5, 1.0, -4.5), (0.8, 2.0, 2.5)),
    ("Shelf_A", (-3.4, 1.0, 4.6), (1.0, 2.0, 3.6)),
    ("Shelf_B", (-0.2, 1.0, 7.1), (2.6, 2.0, 1.0)),
    ("Crate", (1.2, 0.4, 3.0), (0.8, 0.8, 0.8)),
    ("Crate_B", (-2.6, 0.45, 2.6), (0.9, 0.9, 0.9)),
    ("LobbyBench", (17.3, 0.25, 2.8), (1.0, 0.5, 2.0)),
    ("LobbyCounter", (14.5, 0.55, -3.3), (4.0, 1.1, 0.8)),
]
EMERGENCY_LIGHTS = [  # (x, y, z) ผังเดิม, energy
    ((-8.0, 2.7, -5.7), 0.32), ((-6.0, 2.7, 0.0), 0.22), ((0.0, 2.7, 0.0), 0.18), ((6.0, 2.7, 0.0), 0.22),
    ((-1.0, 2.7, 4.7), 0.2), ((8.0, 2.7, -5.7), 0.2), ((15.0, 2.7, 0.0), 0.32),
]
POWER_LIGHTS = [((-9.5, 2.8, -5.0), 1.4), ((-6.5, 2.8, -7.5), 1.2), ((-8.0, 2.8, 0.0), 0.7)]
LIGHT_RANGE = 6.5 * SCALE

Y90 = "0, 0, 1, 0, 1, 0, -1, 0, 0"     # หมุน +90° รอบแกน Y (หน้า +Z → +X)
YM90 = "0, 0, -1, 0, 1, 0, 1, 0, 0"    # หมุน -90° (หน้า +Z → -X)
Y180 = "-1, 0, 0, 0, 1, 0, 0, 0, -1"   # หมุน 180° (หน้า +Z → -Z)
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
fog_density = 0.04

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
size = Vector3(3.2, 0.45, 0.04)

[sub_resource type="BoxShape3D" id="Shape_Exit"]
size = Vector3(1.6, 2.6, 4.0)
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
    """pos เป็นพิกัดผังเดิม"""
    node(name, "StaticBody3D", parent, props=[
        f"transform = {tr(*P(*pos), basis=basis)}",
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
# ช่องประตู: กว้าง DOOR_W สูง DOOR_H ลึกพอทะลุผนังหนา (ผนังระหว่างห้องหนา 0.3 หลังขยาย)
for name, (x, z), axis in DOORS:
    nx, nz = x * SCALE, z * SCALE
    size = (1.0, DOOR_H, DOOR_W) if axis == "x" else (DOOR_W, DOOR_H, 1.0)
    node(name, "CSGBox3D", B, props=[
        f"transform = {tr(nx, DOOR_H / 2, nz)}", "operation = 2", f"size = {vec(*size)}"])
node("Door_Exit", "CSGBox3D", B, props=[
    f"transform = {tr(EXIT_X, DOOR_H / 2, 0.0)}", "operation = 2", f"size = {vec(1.0, DOOR_H, DOOR_W)}"])
# พื้นสีเข้มทับพื้นห้อง (บาง) ให้แยกพื้น/ผนังออก
for name, _, (x0, x1, z0, z1) in ROOMS:
    node(f"{name}_Floor", "CSGBox3D", B, props=[
        f"transform = {tr((x0 + x1) / 2, 0.005, (z0 + z1) / 2)}",
        f"size = {vec(x1 - x0, 0.01, z1 - z0)}",
        'material = SubResource("Mat_Floor")'])
for name, pos, (sx, sy, sz) in PROPS:
    node(name, "CSGBox3D", B, props=[
        f"transform = {tr(*P(*pos))}", f"size = {vec(sx, sy, sz)}", 'material = SubResource("Mat_Prop")'])
lobby = room_new("Lobby")
node("Porch", "CSGBox3D", B, props=[
    f"transform = {tr(lobby[1] + T + 4.2, -0.1, 0.0)}", f"size = {vec(8.4, 0.2, 9.0)}", 'material = SubResource("Mat_Prop")'])

# ---------------------------------------------------------------- lights
node("Lights", "Node3D")
for i, (pos, e) in enumerate(EMERGENCY_LIGHTS):
    node(f"Emergency_{i}", "OmniLight3D", "Lights", extra=' groups=["flicker_lights"]', props=[
        f"transform = {tr(*P(*pos))}", "light_color = Color(0.85, 0.18, 0.1, 1)",
        f"light_energy = {e:g}", f"omni_range = {LIGHT_RANGE:g}"])
for i, (pos, e) in enumerate(POWER_LIGHTS):
    node(f"Power_{i}", "OmniLight3D", "Lights", extra=' groups=["power_lights", "flicker_lights"]', props=[
        f"transform = {tr(*P(*pos))}", "visible = false", "light_color = Color(1, 0.85, 0.6, 1)",
        f"light_energy = {e:g}", "shadow_enabled = true", f"omni_range = {7.5 * SCALE:g}"])
node("Moonlight", "OmniLight3D", "Lights", props=[
    f"transform = {tr(lobby[1] + 5.0, 3.0, 0.0)}", "light_color = Color(0.45, 0.55, 0.85, 1)",
    "light_energy = 0.7", "omni_range = 10.0"])
node("ConsoleScreen", "MeshInstance3D", "Lights", extra=' groups=["power_screens"]', props=[
    f"transform = {tr(*P(-8.0, 1.3, -9.45))}", "visible = false", 'mesh = SubResource("Mesh_Screen")'])

# ป้ายชื่อห้อง (จางๆ ใกล้เพดาน)
node("RoomLabels", "Node3D")
for name, label, (x0, x1, z0, z1) in ROOMS:
    node(f"Label_{name}", "Label3D", "RoomLabels", props=[
        f"transform = {tr((x0 + x1) / 2, 2.75, (z0 + z1) / 2)}",
        "billboard = 1", "modulate = Color(0.85, 0.8, 0.7, 0.22)", "pixel_size = 0.003",
        'font = ExtResource("font")', "font_size = 40", f'text = "{label}"'])

# ---------------------------------------------------------------- markers
node("PlayerSpawn", "Marker3D", props=[f"transform = {tr(*P(-8.0, 0.05, -4.5))}"])
node("EnemySpawn", "Marker3D", props=[f"transform = {tr(*P(15.5, 0.05, 2.0))}"])
node("DebugExitPoint", "Marker3D", props=[f"transform = {tr(*P(16.3, 0.05, 0.0), basis=YM90)}"])
# waypoint ลาดตระเวน 2 จุดต่อห้อง (+3 จุดในทางเดิน) — จุดในห้องรับสัญญาณอยู่ใน group wp_signal_room
# (ช่วงผ่อนผันหลังเปิดไฟ ศัตรูจะยังไม่เดินมาจุดกลุ่มนี้)
WAYPOINTS = [
    ("WP_Signal_A", (-8, -5.5), True), ("WP_Signal_B", (-6, -8), True),
    ("WP_Corridor_W", (-9, 0), False), ("WP_Corridor_M", (0, 0), False), ("WP_Corridor_E", (8, 0), False),
    ("WP_Storage_A", (-1, 4.5), False), ("WP_Storage_B", (-2.5, 6.8), False),
    ("WP_Chief_A", (8, -5.5), False), ("WP_Chief_B", (10, -8), False),
    ("WP_Lobby_A", (15, 0), False), ("WP_Lobby_B", (16, -1.5), False),
]
node("Waypoints", "Node3D")
for name, (x, z), signal in WAYPOINTS:
    groups = ' groups=["wp_signal_room"]' if signal else ""
    node(name, "Marker3D", "Waypoints", extra=groups, props=[f"transform = {tr(*P(x, 0.05, z))}"])

# ---------------------------------------------------------------- actors
node("Player", None, extra=' instance=ExtResource("player")', props=[f"transform = {tr(*P(-8.0, 0.05, -4.5))}"])
node("Enemy", None, extra=' instance=ExtResource("enemy")', props=[f"transform = {tr(*P(15.5, 0.05, 2.0))}"])
node("HUD", "CanvasLayer", props=['script = ExtResource("hud")'])

# ---------------------------------------------------------------- interactables
node("Interactables", "Node3D")
PAPER = (0.85, 0.8, 0.65)
TAPE = (0.15, 0.13, 0.12)
BATT = (0.95, 0.75, 0.15)
LOCKER = (1.0, 2.1, 0.7)
LOCKER_C = (0.2, 0.3, 0.27)
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
# จุดซ่อนตัว: เดิม 4 จุด + ใหม่ห้องละ 1 จุด = 9 จุด (ด้านหน้าตู้ = +Z ของตู้)
interactable("Hide_CorridorLocker", "hide", (-11.6, 1.05, 0.7), LOCKER, LOCKER_C, basis=Y90)
interactable("Hide_SignalDesk", "hide", (-4.6, 0.4, -4.6), (1.6, 0.8, 0.9), (0.3, 0.22, 0.15), basis=YM90,
             extra=["view_offset = Vector3(0, 0.45, 0.1)", "is_under_desk = true"])
interactable("Hide_StorageLocker", "hide", (1.6, 1.05, 6.0), LOCKER, LOCKER_C, basis=YM90)
interactable("Hide_ChiefWardrobe", "hide", (5.2, 1.1, -9.25), (1.2, 2.2, 0.8), (0.25, 0.17, 0.1),
             extra=["view_offset = Vector3(0, 1.5, 0.25)"])
interactable("Hide_SignalLocker", "hide", (-11.6, 1.05, -9.2), LOCKER, LOCKER_C, basis=Y90)
interactable("Hide_CorridorLocker_E", "hide", (3.0, 1.05, 1.15), LOCKER, LOCKER_C, basis=Y180)
interactable("Hide_StorageLocker_W", "hide", (-3.6, 1.05, 2.2), LOCKER, LOCKER_C, basis=Y90)
interactable("Hide_ChiefCabinet", "hide", (11.6, 1.05, -7.5), LOCKER, LOCKER_C, basis=YM90)
interactable("Hide_LobbyLocker", "hide", (12.6, 1.05, 3.4), LOCKER, LOCKER_C, basis=Y90)

# คลื่นที่ซ่อนอยู่ 3 คลื่น (ปริศนา 2) — รัศมีขยายตาม SCALE
node("FrequencySources", "Node3D")
for i, (pos, rng) in enumerate([((-8.0, 1.2, -8.5), 7.0), ((5.0, 1.5, 0.0), 6.0), ((-1.0, 1.2, 6.5), 6.0)]):
    node(f"Source_{i}", "Marker3D", "FrequencySources", props=[
        f"transform = {tr(*P(*pos))}", 'script = ExtResource("source")', f"freq_index = {i}",
        f"range_m = {rng * SCALE:g}"])

# ประตูทางออก + จุดชนะ
node("ExitDoor", "StaticBody3D", props=[f"transform = {tr(EXIT_X, 0.0, 0.0)}", 'script = ExtResource("door")',
                                     f"size = Vector3(0.15, {DOOR_H:g}, {DOOR_W:g})"])
node("ExitTrigger", "Area3D", "ExitDoor", props=[f"transform = {tr(2.6, 1.3, 0.0)}"])
node("CollisionShape3D", "CollisionShape3D", "ExitDoor/ExitTrigger", props=['shape = SubResource("Shape_Exit")'])

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "levels", "radio_station.tscn")
with open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(out))
print("wrote", os.path.normpath(path), len(out), "lines")
if __name__ == "__main__":
    for label, (x, z) in [("player spawn", (-8, -4.5)), ("enemy spawn", (15.5, 2.0)), ("debug exit", (16.3, 0)),
                          ("source 91.3", (-8, -8.5)), ("source 97.7", (5, 0)), ("source 104.5", (-1, 6.5))]:
        print(f"  {label:14s} -> {M(x, z)}")
    print("  exit door x   ->", EXIT_X)
