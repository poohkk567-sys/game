# แนวทางพัฒนาต่อ / PHUZASHI — DARK PULSE

อ่าน README.md และ docs/IMPLEMENTATION.md ก่อนแก้ไข ใช้ Godot 4.2.2+ และคงตัวละคร PHUZASHI เพียงตัวเดียวตามขอบเขตปัจจุบัน

## รักษาต้นฉบับ

ห้ามแก้ไฟล์ `assets/characters/PHUZASHI_MASTER_SHOES_APPROVED.png` หรือออกแบบใบหน้า ผม ชุด ลายกะโหลก กางเกง และรองเท้าใหม่ SHA-256 ต้องเป็น `d0d6156d5114d612c1d04e39781fcd5c783eb09b0ba1268fc8b42c9779e6be06`

ต้นฉบับมีหนึ่งเฟรม เกมปัจจุบันใช้ rig 10 ข้อต่อขับ mesh ที่ใช้ texture เดิม โดยเชื่อม vertex ตามข้อต่อเพื่อป้องกันรอยขาด รักษาใบหน้าและรองเท้าเป็นส่วนแข็ง พร้อม timeline สำหรับ 12 สถานะแล้ว ไม่มีการวาด sprite sheet ใหม่ ถ้าปรับท่า ให้แก้ keyframe ใน `scripts/character/phuzashi_rig.gd` และตรวจภาพจริง ไม่เปลี่ยนรูปลักษณ์ตัวละคร

## การตรวจสอบ

รัน `tools/check.sh` หลังแก้ระบบเกม ต้องไม่มี SCRIPT ERROR หรือ ERROR ตรวจ `docs/TEST_REPORT.md` สำหรับวิธีบันทึกภาพและวิดีโอผ่าน Godot โดยตรง

ภูเขาต้องมีลำดับจุด ridge เรียงซ้ายไปขวาและอยู่เหนือฐาน ตรวจ triangulation รวมกรณี peak สูงกว่าค่า base ด้วย ห้ามนำรูปทรงที่เส้นขอบตัดกันกลับมาใช้


## Spritesheet trial ปัจจุบัน

ผู้ใช้ขอให้นำร่างยืน–เดินมาลองในเกมจริงแล้ว ฉากหลักเปิด `use_draft_spritesheet=true` ใช้ AnimatedSprite2D สำหรับ IDLE/WALK ท่าละ 8 เฟรม ส่วนท่าอื่นยังใช้ mesh เดิม F4 สลับเทียบโดยไม่เปลี่ยน physics ภาพร่างอยู่ใน assets/characters/drafts/ และยังไม่ใช่ชุดอาร์ตสุดท้าย อ่าน docs/art_review/SPRITESHEET_PLAN_TH.md และอย่าอ้างว่ามี spritesheet ครบทั้ง 12 ท่า
