# Task list — The Silent Frequency (full game)

สถานะ: ⬜ ยังไม่ทำ · 🔄 กำลังทำ · ✅ เสร็จ · ⚠️ ทำได้บางส่วน (ดู TODO.md)

## Phase 1 — เมนูและสถานะเกม
- ⬜ GameState autoload (state, puzzle progress, items, checkpoint, timer)
- ⬜ Save/Load ด้วย ConfigFile ที่ user:// + autosave ทุกปริศนา
- ⬜ Main Menu (Play / Continue / How to Play / Credits / Quit ซ่อนบนเว็บ)
- ⬜ How to Play, Credits
- ⬜ Pause Menu (Resume / Back to Main Menu)
- ⬜ Game Over (Retry จาก checkpoint / Main Menu)
- ⬜ You Win (ฉากจบ / Play Again / Main Menu)
- ⬜ UI Theme สยอง (พื้นดำ ตัวอักษรเก่า)

## Phase 2 — ภาษาไทยและฟอนต์
- ⬜ ดาวน์โหลดฟอนต์ไทย OFL ไว้ใน assets/fonts
- ⬜ ตั้งเป็นฟอนต์ใน Theme หลัก + เครดิต

## Phase 3 — ด่าน
- ⬜ สถานี 5 ห้อง (ห้องรับสัญญาณ=เริ่ม, ทางเดิน, ห้องเก็บของ+ตู้ฟิวส์, ห้องหัวหน้า, โถงประตูทางออก)
- ⬜ ไฟดับตอนเริ่ม / ไฟห้องรับสัญญาณติดหลังปริศนา 1
- ⬜ จุดซ่อน ≥ 3, แบต 3–4 จุด
- ⬜ ข้อความบอกปุ่มทุก interactable

## Phase 4 — ผู้เล่น
- ⬜ เดิน/วิ่ง/ย่อ, noise level
- ⬜ ไฟฉาย + แบต + UI
- ⬜ ซ่อนตัว (มุมกล้องผ่านช่อง)
- ⬜ Frequency Finder (ล้อเมาส์/A-D, UI ความถี่, subtitle, noise)

## Phase 5 — ศัตรู
- ⬜ NavigationRegion3D + navmesh ครอบทุกห้อง
- ⬜ PATROL / INVESTIGATE / CHASE + จับ = Game Over
- ⬜ ไฟกระพริบ + เสียงหัวใจตามระยะ, @export ทั้งหมด

## Phase 6 — ปริศนาและเนื้อเรื่อง
- ⬜ ปริศนา 1 คืนพลังงาน
- ⬜ ปริศนา 2 จูน 3 คลื่น → 3 หลัก
- ⬜ ปริศนา 3 บันทึก/เทป 4 ชิ้น → หลักที่ 4
- ⬜ Keypad ประตูทางออก → You Win
- ⬜ บทภาษาไทย, นาฬิกา 02:00→06:00 (15 นาที)

## Phase 7 — เสียง
- ⬜ เสียง procedural (wav) ใน assets/audio + SOUNDS.md
- ⬜ Audio bus Music/SFX
- ⬜ VHS overlay (Compatibility)

## Phase 8 — Web export
- ⬜ renderer gl_compatibility, ปิดเอฟเฟกต์ที่ไม่รองรับ
- ⬜ export_presets.cfg preset "Web" → docs/index.html, no threads
- ⬜ export จริง + docs/.nojekyll, เช็กไฟล์ >100MB, ไม่มี .git ซ้อน
- ⬜ คลิกเพื่อเริ่ม / pointer lock / save บนเว็บ

## Phase 9 — ตรวจสอบและส่งมอบ
- ⬜ headless โหลดทุก scene ไม่มี error
- ⬜ เทสอัตโนมัติเส้นทางหลัก (จบเกม / game over / retry / continue / pause)
- ⬜ TESTING.md + debug keys
- ⬜ README.md อัปเดต
- ⬜ push origin main
