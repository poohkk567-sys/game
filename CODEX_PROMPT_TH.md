# PHUZASHI — DARK PULSE / แนวทางพัฒนาต่อ

อ่าน README.md และ docs/IMPLEMENTATION.md ก่อนแก้ไข โปรเจกต์ใช้ Godot 4.2.2+ มี PHUZASHI ตัวเดียวและเป้าคริสตัล ไม่มีคู่ต่อสู้

## แอนิเมชันปัจจุบัน

ผู้ใช้เลือกภาพ spritesheet แบบใหม่ เกมใช้ AnimatedSprite2D ครบ 12 สถานะ ท่าละ 8 เฟรม รวม 96 เฟรมแล้ว: IDLE, WALK, RUN, JUMP, CROUCH, GUARD, PUNCH, KICK, HIT, FALL, SPECIAL, ULTIMATE

ไฟล์หลักคือ `assets/characters/spritesheets/phuzashi_frames.res` และ manifest.json ภาพต้นทางอยู่ใน spritesheets/ 5 แผ่น และ drafts/idle_walk_draft.png อีก 1 แผ่น กด F4 เพื่อเทียบกับ Master rig เดิม; เส้นทางปกติไม่ใช้การดัด mesh กับ spritesheet

รักษารูปลักษณ์จากชุดยืน–เดินที่ผู้ใช้เลือก ไม่ออกแบบตัวละครหรือรองเท้าใหม่ ไฟล์ Master เดิมต้องคง SHA-256 `d0d6156d5114d612c1d04e39781fcd5c783eb09b0ba1268fc8b42c9779e6be06`

## จุดสำคัญ

- อย่าตัดแผ่นด้วยกริดเท่ากัน: มือ เท้า หรือท่าล้มอาจยื่นข้ามช่อง ใช้ตัวนำเข้าที่แยก silhouette จริง
- บางกรอบภาพท่าล้มซ้อนกัน ต้องแยกพิกเซลของตัวที่ถูกต้อง ไม่รวมเศษภาพจากตัวข้าง ๆ
- ใช้ canvas 512×384, pivot (256,360), สเกลเดียวกันทั้งชุด
- IDLE/WALK/RUN วนรอบ; CROUCH/GUARD เล่นเข้าท่าแล้วค้าง ไม่เริ่มท่ายืนซ้ำขณะกดค้าง
- เฟรมโจมตี HIT/FALL และ JUMP ผูกกับความคืบหน้าจริงของเกม ไม่เล่น loop อิสระ
- แยกเอฟเฟกต์จากภาพตัวละคร
- สร้าง binary resource ด้วย Godot 4.2.2 เพื่อคงความเข้ากันได้กับเวอร์ชันขั้นต่ำ

รัน tools/check.sh และตรวจภาพด้วย tests/test_sprite_render.gd หลังแก้ระบบหรือภาพ ดู docs/TEST_REPORT.md สำหรับคำสั่งและการบันทึกวิดีโอ
