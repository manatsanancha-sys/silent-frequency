# สัญญาณจากความเงียบ (The Silent Frequency)

เกมสยองขวัญ 3D มุมมองบุคคลที่หนึ่ง — งานวิชา Computer Game Development
ผู้เล่นติดอยู่ในสถานีวิทยุร้าง ต้องใช้ **Frequency Finder** ตามหาสัญญาณลึกลับ มีแค่**ไฟฉายแบตจำกัด** และต้อง**ซ่อนตัว**จากสิ่งที่เดินวนอยู่ในความมืด

> สถานะ: **โครงโปรเจกต์ (prototype skeleton)** — เปิดแล้วรันเดินได้ ระบบหลักยังเป็น placeholder

---

## วิธีเปิดโปรเจกต์

1. ติดตั้ง **Godot 4.3 ขึ้นไป** (เวอร์ชันมาตรฐาน ไม่ใช่ .NET) จาก <https://godotengine.org/download>
2. ติดตั้ง **Blender** (3.6+ หรือ 4.x) แล้วใน Godot ไปที่ `Editor > Editor Settings > FileSystem > Import > Blender` ตั้ง **Blender Path**
   (template ใช้ไฟล์ `.blend` สำหรับประตู/กุญแจ/แบตในฉากเดโมเดิม — ฉากหลักของเราไม่ต้องใช้ แต่ถ้าไม่ตั้ง editor จะแจ้ง error ตอน import)
3. เปิด Godot → **Import** → เลือกไฟล์ `silent-frequency/project.godot`
4. รอ import ครั้งแรกเสร็จ แล้วกด **F5** (Run Project) — ฉากหลักคือ `levels/radio_station.tscn`

### ปุ่มควบคุม
| ปุ่ม | การทำงาน |
|---|---|
| WASD / ลูกศร | เดิน |
| เมาส์ | มอง |
| Space | กระโดด |
| **Q** | เปิด/ปิดไฟฉาย (ถ้าแบตหมดจะใช้ Power Cell ในกระเป๋าชาร์จให้อัตโนมัติ) |
| **F** | เปิด/ปิด Frequency Finder · ล้อเมาส์ = จูนความถี่ (ตอนเปิดเครื่อง) |
| **C** | ย่อตัว (ตอนนี้แค่เปลี่ยนสถานะ ยังไม่เปลี่ยนท่า) |
| **E** | interact / เก็บของ / เข้า-ออกตู้ซ่อนตัว |
| I | inventory (เลือก Power Cell แล้วกด Use เพื่อชาร์จไฟฉาย) |

---

## โครงสร้างโปรเจกต์

```
silent-frequency/
├── levels/
│   ├── radio_station.tscn      ★ ฉากหลัก: สถานีวิทยุ greybox 5 ห้อง
│   └── main_level.tscn         ฉากเดโมของ template (เก็บไว้ดูตัวอย่าง)
├── Game/                       ★ โค้ดของเกมเรา
│   ├── Player/Flashlight/      ไฟฉายแบตจำกัด (สืบทอดจาก camcorder ของ template)
│   ├── Systems/
│   │   ├── noise_bus.gd        autoload NoiseBus — ระบบ "เสียง" ให้ศัตรูได้ยิน
│   │   ├── FrequencyFinder/    เครื่องจูนวิทยุ + จุดปล่อยสัญญาณ (placeholder)
│   │   └── Hiding/             autoload PlayerStealth + จุดซ่อนตัว (placeholder)
│   └── Enemy/                  AI ศัตรู 3 state + ฉากศัตรู greybox
├── DemoPlayer/                 ผู้เล่น FPS ของ template (แก้ให้ใช้ไฟฉาย)
├── Interaction/                ระบบ interact ของ template (ประตู ลิ้นชัก คันโยก ไอเท็ม)
├── Inventory/                  ระบบ inventory ของ template (crafting ปิดไว้)
├── tools/gen_radio_station.py  สคริปต์สร้างฉาก greybox ครั้งแรก
└── docs/                       สรุป template + README ต้นฉบับ
```

รายละเอียดว่าแต่ละโฟลเดอร์ของ template ทำอะไร: [docs/TEMPLATE_NOTES.md](docs/TEMPLATE_NOTES.md)

### ผังฉากสถานีวิทยุ (มองจากด้านบน, -Z = ทิศเหนือ)
```
 ┌──────────────┐         ┌──────────────┐
 │ ห้องรับสัญญาณ  │         │ ห้องหัวหน้าสถานี │
 │ (Signal Room) │         │ (Chief Office)│
 └──────┬───────┘         └──────┬───────┘
 ┌──────┴────────────────────────┴───────┬──────────┐
 │               ทางเดิน (Corridor)         ═  ห้องโถง   │
 └──────────────────┬────────────────────┤ (Lobby)  │
              ┌─────┴─────┐               │  ★ spawn │
              │ ห้องเก็บของ  │               └──────────┘
              │ (Storage)  │
              └───────────┘
```
- ห้องรับสัญญาณ: โต๊ะคอนโซลวิทยุ + **FrequencySource** (98.6 MHz) + แบต 1 ก้อน
- ห้องหัวหน้าสถานี: โต๊ะ ชั้นวาง + ตู้ซ่อนตัว
- ห้องเก็บของ: ชั้นวาง ลัง + ตู้ซ่อนตัว + แบต 1 ก้อน
- ห้องโถง: จุดเกิดผู้เล่น + แบต 1 ก้อน
- ทางเดิน: ศัตรูเดินลาดตระเวนผ่านทางเดิน → ห้องรับสัญญาณ → ห้องหัวหน้า

---

## สถานะงาน

### ✅ ทำแล้ว
- [x] Clone template, ลบ `.git` เดิม, `git init` ใหม่ และ commit แยกเป็นขั้นๆ
- [x] สรุปโครงสร้าง template และเงื่อนไข license ([docs/TEMPLATE_NOTES.md](docs/TEMPLATE_NOTES.md))
- [x] เปลี่ยนชื่อโปรเจกต์ใน `project.godot`, แก้ input map ที่ซ้ำ/เพี้ยน, เพิ่มปุ่ม C และ F
- [x] ฉากสถานีวิทยุ greybox 5 ห้อง (CSG + collision, ไฟสลัว, หมอก, ป้ายชื่อห้อง) ตั้งเป็น main scene
- [x] ไฟฉายแบตจำกัด: แบตลดตอนเปิด, ไฟหรี่ลงเมื่อแบตน้อย, กระพริบเมื่อต่ำกว่า 20%, ดับเมื่อหมด, ชาร์จด้วย Power Cell, แถบแบตบนจอ
- [x] Placeholder: Frequency Finder (จูน 88–108 MHz, คำนวณความแรงสัญญาณ, ล็อกสัญญาณ 2 วินาที → print ข้อความ)
- [x] Placeholder: ระบบซ่อนตัว (ตู้ล็อกเกอร์กด E เข้า/ออก, สถานะ hidden/crouch ให้ AI เช็ก)
- [x] Placeholder: AI ศัตรู 3 state — สำรวจ (PATROL) / ได้ยินเสียงแล้วมาดู (INVESTIGATE) / ไล่ล่า (CHASE) มี logic ขั้นต่ำให้เดินได้จริง
- [x] ปิดระบบ crafting (flag `CRAFTING_ENABLED := false` ใน `Inventory/UI/Inventory.gd`) — **ไม่ได้ลบไฟล์**
- [x] แก้บั๊กเล็กของ template: `Player.unset_selected_item()` ที่ถูกเรียกแต่ไม่มีอยู่จริง

### ⏳ ยังไม่ทำ (TODO)
- [ ] UI หน้าปัดวิทยุของ Frequency Finder + เสียงซ่า/เสียงพูด (AudioStreamPlayer)
- [ ] ซ่อนตัวจริง: ย้ายกล้องเข้าตู้, ล็อกการเดิน, กลั้นหายใจ
- [ ] ย่อตัวจริง: ลดความสูง collision + ความเร็ว, เสียงฝีเท้าส่งเข้า NoiseBus
- [ ] ศัตรูใช้ NavigationAgent3D + bake navmesh (ตอนนี้เดินเป็นเส้นตรงระหว่างจุด)
- [ ] Game over / jumpscare / เมนูหลัก / เซฟ
- [ ] เนื้อเรื่อง, ประตูล็อก/กุญแจในสถานี, เสียงบรรยากาศ
- [ ] เปลี่ยน greybox เป็นโมเดลจริง
- [ ] ทดสอบใน Godot editor จริง (ดูหัวข้อผลการตรวจด้านล่าง)

---

## ผลการตรวจ headless
**ข้าม** — เครื่องที่ตั้งโปรเจกต์ไม่มีคำสั่ง `godot` / `godot4` ใน PATH จึงยังไม่ได้รัน `godot --headless` เช็ก error

ไฟล์ `.tscn` และ `.gd` ที่เพิ่มใหม่เขียนด้วยมือ/สคริปต์ (ไม่ได้ผ่าน editor) **ครั้งแรกที่เปิดให้ดู Output/Debugger** ถ้ามี error ให้แก้ตามนั้น
ถ้าติดตั้ง Godot แล้วอยากเช็กเอง:
```bash
godot --headless --path . --import
godot --headless --path . --quit-after 120
```

---

## สมมติฐานที่ตัดสินใจเอง
1. **ไม่มีระบบต่อสู้ให้ปิด** — template นี้ไม่มีอาวุธ/HP/การโจมตีเลย จึงปิดแค่ crafting
2. **ปิด crafting ด้วย flag** แทนการย้ายไฟล์ — ย้ายไฟล์นอก editor เสี่ยงทำ reference ใน `.tscn` พัง; ไฟล์ crafting ทั้งหมดยังอยู่ที่เดิม และฉากเดโม `main_level.tscn` ยังใช้ได้
3. **ไฟฉาย = ฉากที่สืบทอด (inherited scene) จาก `camcorder.tscn`** แล้วเปลี่ยนสคริปต์ใหม่ — ใช้ UI แถบแบตเดิมซ้ำ, ซ่อน REC/zoom/night vision ไว้ ไฟล์ camcorder เดิมไม่ถูกแก้ จะสลับกลับก็แค่เปลี่ยน instance ใน `DemoPlayer/PlayerController.tscn`
4. แบตเป็นตัวเลข 0–100 ลด 1%/วินาที (≈100 วินาทีต่อก้อน) ค่าปรับได้ใน Inspector ของ node `Flashlight`; ถือ Power Cell ได้สูงสุด 8 ก้อน (แสดงผลเท่านั้น ยังไม่บังคับ)
5. **ห้องที่ 5 = ห้องโถงทางเข้า (Lobby)** เป็นจุดเกิดผู้เล่น
6. ฉากหลัก**ไม่ใช้ไฟล์ `.blend`** เลย (แบตเป็นกล่องสีเหลือง, ตู้เป็นกล่องสีเขียว) เพื่อให้รันได้แม้ยังไม่ได้ตั้ง Blender
7. ผนังสร้างด้วย `CSGBox3D` ใน `CSGCombiner3D` (use_collision) — แก้ขนาด/ย้ายห้องใน editor ได้ทันที เหมาะกับ greybox; ถ้าทำเกมจริงค่อยเปลี่ยนเป็น mesh
8. ใช้ **autoload** `NoiseBus` และ `PlayerStealth` เป็นตัวกลางระหว่างผู้เล่นกับศัตรู เพื่อให้แต่ละระบบไม่ต้องอ้างถึงกันตรงๆ
9. โค้ดใหม่อยู่ใน `Game/` ส่วนของ template คงตำแหน่งเดิม เพื่อแยกให้เห็นว่าอะไรเป็นของเรา
10. ป้ายชื่อห้องและข้อความภาษาไทยพึ่ง system font fallback ของ Godot — ถ้าแสดงเป็นสี่เหลี่ยม ให้ใส่ฟอนต์ไทย (เช่น Sarabun / Noto Sans Thai) ใน Project Settings > GUI > Theme > Custom Font
11. renderer คงเป็น **Mobile** ตาม template
12. ไฟล์ `*.blend1` (backup ของ Blender) ไม่ถูก commit เพื่อลดขนาด repo
13. README ต้นฉบับของ template ย้ายไปไว้ที่ [docs/TEMPLATE_README_original.md](docs/TEMPLATE_README_original.md)

---

## GitHub
Remote: `https://github.com/manatsanancha-sys/silent-frequency.git` (branch `main`)

push ขึ้น GitHub สำเร็จแล้ว (`git push -u origin main`, 2026-10-06) หลังจากนี้ใช้แค่:
```bash
git add -A
git commit -m "ข้อความ"
git push
```
ถ้าเครื่องอื่น push ไม่ได้ (ยังไม่ login): ติดตั้ง GitHub CLI แล้วรัน `gh auth login` หรือใช้ Personal Access Token แทนรหัสผ่านตอน git ถาม

---

## เครดิตและ License

โปรเจกต์นี้สร้างต่อยอดจาก **[horror-fps-template](https://github.com/ThiDiamondDev/horror-fps-template)** โดย **Thiago Santana (ThiDiamondDev)**
เผยแพร่ภายใต้ **MIT License** — Copyright (c) 2024 Thiago Santana

ตามเงื่อนไข MIT ต้องคงข้อความลิขสิทธิ์และ permission notice ไว้ในทุกสำเนา จึงเก็บไฟล์ [`LICENSE`](LICENSE) ต้นฉบับไว้ที่ root ของโปรเจกต์โดยไม่แก้ไข
ส่วนที่ได้มาจาก template: `DemoPlayer/`, `Interaction/`, `Inventory/`, `levels/main_level.tscn` (บางไฟล์ถูกแก้ไขเล็กน้อย ดู git history)
ถ้า export เกม ให้ใส่ในหน้า Credits ว่า: *"Based on horror-fps-template by Thiago Santana — MIT License"*
