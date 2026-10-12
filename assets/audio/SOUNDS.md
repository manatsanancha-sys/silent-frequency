# เสียงในเกม (assets/audio)

เสียงทั้งหมดตอนนี้เป็น **placeholder ที่สร้างแบบ procedural** ด้วย `tools/gen_audio.py` (numpy) — mono 22.05 kHz 16-bit WAV
**เปลี่ยนเป็นเสียงจริงได้เลย** โดยวางไฟล์ `.wav` ชื่อเดียวกันทับ (ความยาวเท่าไหร่ก็ได้) ไม่ต้องแก้โค้ด
ไฟล์ที่ระบุว่า "วนซ้ำ" จะถูกตั้ง loop อัตโนมัติใน `Game/Core/audio_manager.gd` (รายการ `LOOPING`)
ถ้าจะใช้ .ogg ให้แก้ `AUDIO_DIR`/นามสกุลใน `audio_manager.gd`

| ไฟล์ | Bus | วนซ้ำ | ใช้ที่ไหน / ควรเป็นเสียงอะไร |
|---|---|---|---|
| `ambient_drone.wav` | Music | ✅ | เสียงบรรยากาศต่ำๆ ตลอดทั้งเกมและเมนู (drone, ลมหวีด) |
| `static_loop.wav` | SFX | ✅ | เสียงซ่าของเครื่องรับสัญญาณ (เบาลงเมื่อจูนใกล้คลื่น) + เสียงพื้นหลังเครื่องเล่นเทป |
| `transmission_loop.wav` | SFX | ✅ | เสียงคลื่นที่จับได้ระหว่างแสดง subtitle (โทนแปลกๆ ใต้เสียงซ่า) |
| `power_hum_loop.wav` | SFX | ✅ | เสียงไฟฟ้าหึ่งหลังเปิดสวิตช์ไฟหลัก |
| `heartbeat.wav` | SFX | ✅ | หัวใจเต้น 1 รอบ (ตุบ-ตุบ) — ดัง/เร็วขึ้นตามระยะศัตรู (ปรับ pitch) |
| `footstep.wav` | SFX | | ฝีเท้าผู้เล่น (เบา/ดังตามเดิน-วิ่ง-ย่อ) |
| `footstep_enemy.wav` | SFX | | ฝีเท้าหนักๆ ของศัตรู (3D) |
| `enemy_scream.wav` | SFX | | ศัตรูเห็นผู้เล่น เริ่มไล่ล่า (3D) |
| `jumpscare.wav` | SFX | | โดนจับ |
| `pickup.wav` | SFX | | เก็บของ |
| `paper.wav` | SFX | | เปิดอ่านบันทึก |
| `fuse_insert.wav` | SFX | | ใส่ฟิวส์ (3D) |
| `switch_on.wav` | SFX | | เปิดสวิตช์ไฟหลัก (3D) |
| `door_open.wav` | SFX | | ประตูทางออกเปิด / ศัตรูเข้ามาในสถานี (3D) |
| `keypad_beep.wav` | SFX | | กดปุ่มแป้นรหัส |
| `keypad_error.wav` | SFX | | รหัสผิด — เสียงเตือนดัง (ศัตรูได้ยิน) |
| `keypad_ok.wav` | SFX | | รหัสถูก |
| `tape_click.wav` | SFX | | กดปุ่มเครื่องเล่นเทป |
| `radio_click.wav` | SFX | | เปิด/ปิดเครื่องรับสัญญาณ |
| `radio_lock.wav` | SFX | | จับคลื่นได้ |
| `flashlight_click.wav` | SFX | | เปิด/ปิดไฟฉาย |
| `battery_swap.wav` | SFX | | เปลี่ยนแบตไฟฉาย |
| `locker.wav` | SFX | | เปิด/ปิดตู้ซ่อนตัว |
| `ui_click.wav` | SFX | | คลิกปุ่มเมนู |
| `win_sting.wav` | SFX | | หน้า You Win |
| `gameover_sting.wav` | SFX | | หน้า Game Over |

แหล่งเสียงจริงแนะนำ (CC0): Kenney (kenney.nl/assets — Interface Sounds, Impact Sounds), freesound.org (กรอง license เป็น CC0)
ถ้าใช้เสียงที่ไม่ใช่ CC0 ต้องใส่เครดิตในหน้า Credits (`Game/UI/Menus/main_menu.gd` → `CREDITS`)
