# สัญญาณจากความเงียบ (The Silent Frequency)

เกมสยองขวัญ 3D มุมมองบุคคลที่หนึ่ง — งานวิชา Computer Game Development · Godot 4.3+ (พัฒนา/ทดสอบด้วย 4.7)

> ตุลาคม 2541 — "ภานุ" เจ้าหน้าที่เทคนิคสถานีวิทยุบนยอดเขา เข้าเวรดึกแทนเพื่อนที่หายตัวไป
> ไฟทั้งสถานีดับ ประตูหน้าล็อกด้วยรหัส ต้องคืนไฟ ฟังคลื่นวิทยุและเทปเก่าเพื่อรู้ความจริงเมื่อ 20 ปีก่อน
> แล้วหนีออกไปก่อนรุ่งสาง — โดยมี "มัน" ที่ถูกเสียงวิทยุดึงดูดมาเดินอยู่ในความมืด ผู้เล่นไม่มีอาวุธ

**สถานะ: เล่นจบได้ครบ** (เมนู → ปริศนา 3 ข้อ → ใส่รหัส → ฉากจบ, Game Over/Retry, เซฟ/โหลด) · export เป็นเว็บแล้วที่ `docs/`
เทสอัตโนมัติ 78 ข้อผ่านทั้งหมด · เช็กลิสต์ให้คนทดสอบ: [TESTING.md](TESTING.md) · งานค้าง: [TODO.md](TODO.md) · task list: [TASKS.md](TASKS.md)

---

## วิธีเปิดโปรเจกต์
1. ติดตั้ง **Godot 4.3 ขึ้นไป** (เวอร์ชันมาตรฐาน ไม่ใช่ .NET) — โปรเจกต์ถูกบันทึกด้วย 4.7 ถ้าเปิดด้วยเวอร์ชันเก่ากว่าจะมีคำเตือน แนะนำ 4.7
2. Godot → **Import** → เลือก `project.godot` → รอ import เสร็จ → **F5**
3. (ไม่บังคับ) ไฟล์ `.blend` ของฉากเดโม template ต้องตั้ง Blender ใน Editor Settings ถึงจะเปิดได้ — **เกมจริงไม่ใช้ไฟล์ .blend เลย**

## ปุ่มควบคุม
| ปุ่ม | การทำงาน |
|---|---|
| WASD / ลูกศร | เดิน |
| เมาส์ | มองรอบตัว (บนเว็บ: คลิกในจอ 1 ครั้งเพื่อล็อกเมาส์) |
| **Shift** | วิ่ง — เร็วกว่ามัน แต่เสียงดัง |
| **C** หรือ **Ctrl** | ย่อตัว — ช้า แต่แทบไม่มีเสียง และมันเห็นยากขึ้น |
| **E** | โต้ตอบ / เก็บของ / อ่าน / เข้า-ออกที่ซ่อน |
| **F** | เปิด/ปิดไฟฉาย |
| **Tab** หรือ **Q** | เปิด/ปิดเครื่องรับสัญญาณ → จูนด้วย **ล้อเมาส์** หรือ **A / D** |
| **Esc** | เมนูหยุดเกม / ปิดหน้าต่างอ่านบันทึก-แป้นรหัส |
| F9 / F10 / F11 | debug เท่านั้น: วาร์ปไปทางออก / ปิดศัตรู / ปลดล็อกทุกปริศนา (ดู TESTING.md) |

## วิธีเล่นโดยย่อ
1. **คืนพลังงาน** — ฟิวส์ในห้องหัวหน้าสถานี → ตู้ฟิวส์ในห้องเก็บของ → สวิตช์ไฟหลักในห้องรับสัญญาณ (ไฟติด และ "มัน" ตื่น)
2. **จูนคลื่น** — หาคลื่นที่ซ่อนอยู่ 3 คลื่น (แถบความแรงบอกว่าใกล้แค่ไหน) แต่ละคลื่นเล่าเรื่องและให้รหัส 1 หลัก
3. **เทปและบันทึก** — บันทึก 2 + เทป 2 กระจายในห้อง อ่านทันทีที่เก็บ / เทปเปิดที่เครื่องเล่นในห้องหัวหน้า เทปสุดท้ายให้หลักที่ 4 และเปิดเผยความจริง
4. **หนี** — ใส่รหัส 4 หลักที่แป้นข้างประตูหน้า แล้วออกไปก่อน 06:00 น. (15 นาทีจริง)

---

## โครงสร้างโฟลเดอร์
```
silent-frequency/
├── Game/                       ★ โค้ดเกมของเรา
│   ├── Core/                   autoload: game_state.gd (สถานะ/ปริศนา/เซฟ), audio_manager.gd, story.gd (บทภาษาไทยทั้งหมด)
│   ├── Player/                 player.tscn/.gd — เดิน วิ่ง ย่อ noise ไฟฉาย ซ่อนตัว
│   ├── Systems/                FrequencyFinder/ (เครื่องรับสัญญาณ + จุดปล่อยคลื่น), noise_bus.gd (เสียงเหตุการณ์)
│   ├── Enemy/                  enemy.tscn + enemy_ai.gd — AI 3 state + NavigationAgent3D
│   ├── Interactables/          ฐาน interactable.gd + ของเก็บ/ตู้ฟิวส์/สวิตช์/เครื่องเล่นเทป/แป้นรหัส/ประตู/ที่ซ่อน
│   ├── Level/station.gd        สคริปต์ด่าน: นาฬิกา ไฟ ศัตรู หัวใจเต้น debug keys
│   └── UI/                     Theme/, Menus/ (เมนูหลัก, Game Over, You Win), PauseMenu/, HUD/, vhs.gdshader, ui_kit.gd
├── levels/
│   ├── radio_station.tscn      ★ ด่านหลัก (สร้างจาก tools/gen_radio_station.py)
│   ├── radio_station_navmesh.tres  navmesh ที่ bake ไว้
│   └── main_level.tscn         ฉากเดโมของ template (ไม่ได้ใช้ในเกม)
├── assets/fonts/               ฟอนต์ไทย OFL (Sarabun, Trirong, Mali) + ไฟล์ license
├── assets/audio/               เสียง procedural 26 ไฟล์ + SOUNDS.md
├── tests/                      เทสอัตโนมัติ end-to-end (run_tests.tscn)
├── tools/                      gen_radio_station.py, gen_audio.py, bake_navmesh.tscn
├── docs/                       ★ เกมเวอร์ชันเว็บ (export แล้ว) — สำหรับ GitHub Pages
├── notes/                      สรุปโครงสร้าง template + README ต้นฉบับ
├── DemoPlayer/ Interaction/ Inventory/   โค้ดของ template (ใช้ InteractionBase ต่อ, ส่วนอื่นเก็บไว้)
├── export_presets.cfg          preset "Web" → docs/index.html
└── TESTING.md / TODO.md / TASKS.md
```

---

## เวอร์ชันเว็บ
### ทดสอบในเครื่อง
เปิดผ่าน `file://` ไม่ได้ ต้องมีเว็บเซิร์ฟเวอร์:
```bash
cd docs
python -m http.server 8000
```
แล้วเปิด <http://localhost:8000>

### Export ใหม่ (หลังแก้เกม)
ต้องมี export templates ของ Godot เวอร์ชันเดียวกัน (Editor → Manage Export Templates) — เครื่องที่ทำงานนี้มี 4.7 แล้ว
```bash
godot --headless --path . --export-release "Web" docs/index.html
```
หรือใน editor: Project → Export → **Web** → Export Project (path ตั้งเป็น `docs/index.html` ไว้แล้ว)

### Deploy GitHub Pages
1. push ขึ้น GitHub (โฟลเดอร์ `docs/` อยู่ใน repo แล้ว มี `docs/.nojekyll`)
2. repo → **Settings → Pages** → Source: *Deploy from a branch* → Branch **main** / โฟลเดอร์ **/docs** → Save
3. รอ 1–2 นาที เปิด `https://manatsanancha-sys.github.io/silent-frequency/`

### Deploy itch.io
1. zip **เนื้อหาข้างใน** `docs/` (เลือกไฟล์ทั้งหมดใน docs แล้ว zip — ให้ `index.html` อยู่ที่รากของ zip ไม่ใช่อยู่ในโฟลเดอร์ docs)
2. itch.io → Create new project → **Kind of project: HTML** → อัปโหลด zip → ติ๊ก **"This file will be played in the browser"**
3. ตั้ง viewport 1280×720 (หรือติ๊ก fullscreen button) → Save

### สิ่งที่ตั้งค่าเพื่อเว็บ
- renderer = **gl_compatibility** (WebGL 2) ทั้ง desktop และ mobile
- **ปิด thread support** (`variant/thread_support=false`) → ไม่ต้องใช้ header COOP/COEP, เล่นบน GitHub Pages/itch ได้
- เอฟเฟกต์ที่**ไม่ได้ใช้/ปิด**: volumetric fog, SSAO, SSIL, SDFGI, SSR, glow — ใช้แค่ fog ธรรมดา (depth fog) + tonemap ที่ Compatibility รองรับ
- shader night vision ของ camcorder (template) ไม่ได้ใช้ → ใช้ **VHS overlay** แบบ canvas_item (`Game/UI/vhs.gdshader`) แทน ซึ่งทำงานใน Compatibility ได้ → **เปิดไว้**
- เสียง: หน้า "คลิกเพื่อเริ่ม" ก่อนเมนู (เบราว์เซอร์ต้องมี user gesture ก่อนเล่นเสียง) แสดงครั้งเดียวต่อการเปิดหน้า
- เมาส์: คลิกในจอเพื่อล็อก, ถ้าเบราว์เซอร์ปลดล็อก (กด Esc) เกมจะเปิดเมนูหยุดให้อัตโนมัติ
- เซฟใช้ `ConfigFile` ที่ `user://` → บนเว็บ Godot เก็บใน IndexedDB (ทดสอบแล้ว: รีเฟรชหน้าเซฟยังอยู่)
- ปุ่ม "ออกจากเกม" ซ่อนเมื่อ `OS.has_feature("web")`
- export filter ตัดของเดโม template (.blend, ฉากเดโม, crafting) และ `tests/ tools/ notes/` ออก → `index.pck` ≈ 1.6 MB, `index.wasm` ≈ 39.5 MB (ไม่มีไฟล์ไหนเกิน 100 MB)
- ตรวจแล้วไม่มีโฟลเดอร์ `.git` ซ้อนในโฟลเดอร์ย่อย

---

## ผลการตรวจสอบ
- **โหลดทุกฉากแบบ headless** (Godot 4.7): ไม่มี script error / warning ตอนรัน
- **เทสอัตโนมัติ** `godot --headless --path . res://tests/run_tests.tscn` → **PASS 78/78** ครอบคลุม:
  เมนู (Continue ปิดเมื่อไม่มีเซฟ) · เกมใหม่ + checkpoint แรก · navmesh มีเส้นทางจากจุดเกิดไปทุก waypoint ·
  ปริศนา 1 (ล็อกตามลำดับ) · จูน 3 คลื่น · บันทึก/เทป 4 ชิ้น · รหัสผิด/ถูก · ประตูเปิด → You Win · เซฟถูกลบหลังชนะ ·
  โดนจับ → Game Over → Retry (ความคืบหน้า/รหัส/ของที่เก็บถูกคืนครบ, ศัตรูเกิดไกล) · Continue จากเมนู · หมดเวลา → Game Over ·
  Pause (กล้อง/ตัวละคร/นาฬิกาหยุด, resume เดินได้) · AI (มองไม่เห็นในที่มืด/ข้างหลัง, เสียง → INVESTIGATE, เห็น → CHASE, ซ่อน → มองไม่เห็น → INVESTIGATE → PATROL) · ความเร็วไล่ล่าอยู่ระหว่างเดินกับวิ่ง
- **เว็บ** (ทดสอบใน browser pane, Chromium): โหลดได้ WebGL2 single-thread, เมนู/ภาษาไทย/VHS ถูกต้อง, ไม่มีปุ่ม Quit, เข้าด่านได้ HUD ครบ, Esc pause ทำงาน, เซฟอยู่รอดหลังรีเฟรช
- สิ่งที่เครื่องมือตรวจไม่ได้ → ต้องเล่นเองตาม [TESTING.md](TESTING.md): ภาพ/เสียง/ความรู้สึก, pointer lock ในเบราว์เซอร์จริง

---

## สมมติฐานที่ตัดสินใจเอง
1. **เสียงทั้งหมดสร้างแบบ procedural** (`tools/gen_audio.py`) แทนการดาวน์โหลดจาก Kenney — ควบคุมได้ครบทุกเสียงและไม่มีปัญหา license; เปลี่ยนเป็นไฟล์จริงได้ด้วยชื่อเดิม
2. **ฟอนต์**: Sarabun (ทั่วไป), Trirong (หัวข้อ "ตัวอักษรเก่า"), **Mali** (หน้าบันทึกลายมือ) — เดิมใช้ Itim แต่ glyph บางตัวทำให้เกิด error `Rect2i size is negative` จึงเปลี่ยน
3. **UI สร้างด้วยโค้ด** (`UiKit`) แทนไฟล์ .tscn ใหญ่ๆ — หน้าตาสม่ำเสมอทุกจอ แก้ข้อความ/ลำดับปุ่มในสคริปต์ได้ง่าย (ฉาก .tscn ของเมนูเป็นแค่ root + script)
4. **ฉากสร้างจากสคริปต์ Python** (CSG greybox) แล้วบันทึกเป็น .tscn ปกติ เปิด/แก้ใน editor ได้ (ถ้าแก้ใน editor แล้ว อย่ารัน generator ซ้ำ)
5. ใช้ผัง 5 ห้องเดิม: **ห้องรับสัญญาณ (จุดเริ่ม) – ทางเดิน – ห้องเก็บของ (ตู้ฟิวส์) – ห้องหัวหน้าสถานี – โถงประตูทางออก** + ลานหน้าสถานีด้านนอกประตู
6. **ศัตรูตื่นหลังเปิดไฟ** (ปริศนา 1) — ตามเนื้อเรื่องที่มันถูกเสียงวิทยุดึงดูด ช่วงแรกจึงเป็นช่วงสำรวจปลอดภัย
7. **มันเห็นในที่มืดได้แค่ 6 ม.** แต่ถ้าผู้เล่นเปิดไฟฉายเห็นได้ 15 ม. — ทำให้ไฟฉายเป็นทั้งตัวช่วยและความเสี่ยง
8. ค่าเสียง (0–1): ยืน 0 · ย่อ 0.12 · เดิน 0.4 · วิ่ง 1.0 · เปิดวิทยุ +0.1 · หมุนหาคลื่น +สูงสุด 0.6 · รับคลื่น/ฟังเทป มีเสียง → ศัตรูได้ยินในรัศมี noise × 16 ม. (เกณฑ์ขั้นต่ำ 0.2)
9. ความเร็ว: ผู้เล่น เดิน 3.0 / วิ่ง 5.6 / ย่อ 1.6 · ศัตรู ลาดตระเวน 1.5 / ตรวจสอบ 2.6 / ไล่ล่า **4.9** (ปรับได้ใน Inspector ของ Enemy)
10. **ขณะเปิดเครื่องรับสัญญาณ A/D ใช้จูนแทนเดินด้านข้าง** (ตามสเปกที่ให้ใช้ A/D จูน) — W/S ยังเดินได้
11. **รหัสประตูสุ่มใหม่ทุกเกม** (บทแทรกตัวเลขให้อัตโนมัติ) ความถี่ 3 คลื่นคงที่ 91.3 / 97.7 / 104.5 MHz
12. เลขที่ได้จากคลื่น/เทปแสดงที่มุมขวาบนให้ด้วย (กันผู้เล่นลืม) — ข้อความเป้าหมายบอกขั้นต่อไปเสมอ
13. "ชิ้นสุดท้าย" ของปริศนา 3 = **ชิ้นที่ 4 ตามลำดับเรื่อง** (เทปคำสารภาพหัวหน้าสมพงษ์) — เก็บได้ทุกลำดับ แต่เทปนี้คือที่ให้หลักที่ 4
14. **Checkpoint/เซฟอัตโนมัติ**: ตอนเริ่มเกม, ใส่ฟิวส์, เปิดไฟ, ได้แต่ละคลื่น, เก็บบันทึก/เทปแต่ละชิ้น, ฟังเทปจบ (บ่อยกว่า "ทุกปริศนา" เพื่อไม่ให้เสียความคืบหน้ามาก) — แบตที่เก็บหลังเซฟล่าสุดจะกลับมาเมื่อ Retry
15. Retry โหลด checkpoint ล่าสุด รวมเวลาที่เหลือ ณ ตอนนั้น และศัตรูเกิดที่จุดไกลผู้เล่นที่สุด
16. ชนะแล้ว**ลบเซฟ** (ปุ่ม Continue ปิด) · "เล่นใหม่" ทับเซฟเดิมโดยไม่ถาม
17. ถ้าศัตรู**เห็นผู้เล่นภายใน 0.8 วิก่อนเข้าตู้** มันจะไปลากออก = Game Over
18. แบตไฟฉาย 1 ก้อน = 150 วินาที, ถือสำรองได้ 4 ก้อน, หมดแล้วเปลี่ยนอัตโนมัติ (ไม่ต้องมีปุ่มเพิ่ม)
19. pause menu มีแถบปรับเสียง Music/SFX ด้วย และเมนูหลักมีหน้า "ตั้งค่าเสียง" (ค่าเก็บใน `user://settings.cfg`)
20. Esc บนเว็บ: เบราว์เซอร์ปลดล็อกเมาส์เอง เกมจึงตรวจจับแล้วเปิด pause ให้
21. โค้ด template ที่ไม่ใช้ (DemoPlayer, camcorder, crafting, ฉากเดโม) **เก็บไว้ ไม่ลบ** แต่ตัดออกจาก web export · `InteractionBase` ของ template ยังเป็นฐานของ interactable ทุกตัว
22. ไฟล์ที่ Godot 4.7 สร้างเอง (`.uid`, `.import`) commit ไว้ด้วย
23. export path คือ `docs/index.html` → ย้ายเอกสารเดิมใน `docs/` ไปไว้ `notes/`

## สิ่งที่ยังไม่ได้ทำ
ดู [TODO.md](TODO.md) — หลักๆ: เสียง/โมเดลจริง, ตั้งค่าความไวเมาส์, เล่นบนมือถือ, ภาษาอังกฤษ, การทดสอบด้วยคนตาม TESTING.md

---

## GitHub
Remote: `https://github.com/manatsanancha-sys/silent-frequency.git` (branch `main`)
ถ้า push ไม่ได้ (ยังไม่ login): ติดตั้ง GitHub CLI แล้ว `gh auth login` หรือใช้ Personal Access Token แทนรหัสผ่านตอน git ถาม

## เครดิตและ License
- **horror-fps-template** โดย Thiago Santana (ThiDiamondDev) — MIT License — <https://github.com/ThiDiamondDev/horror-fps-template>
  ไฟล์ [`LICENSE`](LICENSE) ต้นฉบับเก็บไว้ที่ root ตามเงื่อนไข MIT (ต้องคงข้อความลิขสิทธิ์และ permission notice) · ส่วนที่มาจาก template: `DemoPlayer/`, `Interaction/`, `Inventory/`, `levels/main_level.tscn`
- **ฟอนต์** (SIL Open Font License 1.1 — ไฟล์ license อยู่ใน `assets/fonts/OFL-*.txt`):
  Sarabun — The Sarabun Project Authors · Trirong — Cadson Demak · Mali — The Mali Project Authors
- **เสียง** — สร้างเองแบบ procedural (`tools/gen_audio.py`)
- **Godot Engine** — MIT License
- เครดิตทั้งหมดแสดงในเกมที่เมนูหลัก → เครดิต
