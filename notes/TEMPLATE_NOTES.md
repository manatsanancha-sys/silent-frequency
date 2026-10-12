# สรุปโครงสร้าง Template ต้นฉบับ

ต้นฉบับ: [ThiDiamondDev/horror-fps-template](https://github.com/ThiDiamondDev/horror-fps-template) (commit `d751cfe`, Godot 4.3, renderer: Mobile)

> README ของ template บอกว่าต้องเปิดการ import ไฟล์ `.blend` ใน Godot (ตั้ง Blender path ใน Editor Settings) ไม่งั้นโมเดล Door/Key/PowerCell/FlashLight จะโหลดไม่ขึ้น

## โฟลเดอร์

| โฟลเดอร์ / ไฟล์ | หน้าที่ |
|---|---|
| `project.godot` | ตั้งค่าโปรเจกต์, autoload `Inventory`, input map (WASD/ลูกศร, Space, E, I, Q, T) |
| `levels/main_level.tscn` | ฉากเดโมเดิม: พื้น, ผนัง, ประตูล็อกกุญแจ, บันได, คันโยก + ลิฟต์, ไอเท็มเก็บได้, กล่อง crafting |
| `DemoPlayer/` | ผู้เล่น FPS — `demo_player.tscn` (CharacterBody3D: เดิน/กระโดด/ปีนบันได) ซ้อนกับ `PlayerController.tscn` (Head + กล้อง, RayCast สำหรับ interact, label, Inventory UI) |
| `Interaction/InteractionBase.gd` | คลาสฐาน `InteractionBase` (StaticBody3D) — อะไรก็ตามที่กด E ได้ |
| `Interaction/DragInteraction.*` | ฐานของวัตถุที่ "กด E ค้าง + ลากเมาส์" (ประตู, ลิ้นชัก, คันโยก) |
| `Interaction/Door/` | ประตูลากเปิด ล็อกด้วยกุญแจได้ (`key_name`) |
| `Interaction/Furniture/` | ตู้ + ลิ้นชักลากเปิด |
| `Interaction/Ladder/` | Area สำหรับสลับผู้เล่นเป็นโหมดปีนบันได |
| `Interaction/Lever/`, `LeverActivatedBase.*`, `Elevator/` | คันโยกที่สั่งวัตถุอื่น (เช่นลิฟต์) |
| `Interaction/Items/CollectibleItem.*` | ฐานของไอเท็มที่เก็บเข้า inventory ได้ (`item: ItemResource`) |
| `Interaction/Items/Camcorder/` | **กล้อง night vision** — Camera3D หลักของผู้เล่น มี SpotLight, แบตลดตาม Animation "Decrease Energy", UI แบต/REC/zoom, shader ย้อมสีเขียว |
| `Interaction/Items/FlashLight/` | ไฟฉายรุ่นเก่า (สคริปต์อ้าง `Inventory.power_cells` ที่ไม่มีแล้ว — ไม่ได้ใช้ในเดโม) |
| `Interaction/Items/PowerCell/` | แบตเตอรี่ เก็บแล้วใช้ชาร์จกล้อง (`use_item`) |
| `Interaction/Items/Key/` | กุญแจปลดล็อกประตู |
| `Interaction/Items/CraftSystem/` | ไอเท็มตัวอย่าง A/B/C และสูตร AB/ABC สำหรับระบบ crafting |
| `Inventory/InventorySingleton.gd` | autoload `Inventory`: เก็บ dictionary ไอเท็ม + signal (collect/update/remove) |
| `Inventory/ItemResource.gd`, `CraftItemResource.gd` | Resource ของไอเท็ม / สูตร craft |
| `Inventory/UI/` | หน้าจอ inventory (กด I): ช่องไอเท็ม 4x4, ปุ่ม Use/Drop, แผง Craft |

## ปุ่มเดิม
WASD/ลูกศร เดิน · Space กระโดด · E interact (ค้าง+ลาก สำหรับประตู) · I inventory · Q เปิด/ปิดไฟ/night vision · T เปิด/ปิดกล้อง · Scroll ซูม

## หมายเหตุที่พบ
- `project.godot` เดิมมี `ToggleLight` ซ้ำอยู่นอกวงเล็บท้าย `[input]` (ไฟล์เพี้ยนเล็กน้อย) — แก้แล้วในโปรเจกต์นี้
- template **ไม่มีระบบต่อสู้** (ไม่มีอาวุธ/HP/ศัตรู) จึงไม่มีอะไรต้องปิดในส่วนนี้
- ไฟล์ `*.blend1` เป็น backup ของ Blender ไม่ได้ถูก Godot ใช้ — ใส่ใน `.gitignore`

## License
MIT License — Copyright (c) 2024 Thiago Santana

เงื่อนไขของ MIT: ใช้/แก้/แจกจ่ายได้ฟรี (รวมงานส่งวิชา) **แต่ต้องคงข้อความลิขสิทธิ์และตัว permission notice ไว้** ในทุกสำเนาหรือส่วนสำคัญของซอฟต์แวร์
สิ่งที่ทำในโปรเจกต์นี้:
1. เก็บไฟล์ `LICENSE` เดิมไว้ที่ root ไม่แก้ไข
2. ใส่เครดิตใน `README.md` (หัวข้อ "เครดิตและ License")
3. ถ้า export เกม แนะนำให้ใส่เครดิต "Based on horror-fps-template by Thiago Santana (MIT)" ในหน้า Credits ของเกมด้วย
