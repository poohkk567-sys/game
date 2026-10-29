# RED CAP / CAP OFF ULTIMATE

ร่างที่สองหัวโล้น ไม่มีหมวก ไม่มีเสื้อ ไม่มีกระเป๋า รูปร่างแข็งแรงขึ้นและสีผิว/หน้าตาเดิม กางเกงดำและรองเท้าปลาย/พื้นสีครีมเหมือนร่างปกติ อ้างอิง design_reference.png

## ลำดับแปลงร่าง 16 เฟรม
transform.png / transform_frames.res เรียง4คอลัมน์ x4แถว อ่านซ้ายไปขวา:
0ยืนใส่หมวก 1จับปีกหมวก 2ยกหมวก 3ถือหมวกเผยหัวโล้น
4เก็บหมวก 5หยิบขวดซีอิ๊วดำฝาแดง 6ยกขวด 7เหยาะซอสบนหัว
8เหยาะซอสต่อ 9เก็บขวด 10จับชายเสื้อ 11ดึงเสื้อขึ้น
12ถอดเสื้อผ่านหัว 13ถือเสื้อถอดแล้ว 14เก็บเสื้อ 15ตั้งการ์ดร่างหัวโล้นถอดเสื้อ

## ท่าร่างใหม่ 112 เฟรม
แผ่นโปร่งใส7แผ่น แผ่นละ16ภาพ แถวบนสองแถวท่าแรก8ภาพ แถวล่างสองแถวท่าที่สอง8ภาพ
idle_walk: IDLE/WALK
run_jump: RUN/JUMP
crouch_guard: CROUCH/GUARD
punch_kick: PUNCH/KICK
punch_combo: PUNCH_2/PUNCH_3
kick_combo: KICK_2/KICK_3
hit_fall: HIT/FALL

awakened_frames.res เป็น SpriteFrames14ท่า AIR_PUNCH/AIR_KICK ใช้ภาพโจมตีของร่างนี้ BOUND ใช้ HIT ค้าง จึงไม่มีหมวก/เสื้อกลับมาในช่วงกระโดด โดนโจมตี หรือล้ม
คงคอมโบและค่าดาเมจเดิม ไม่มีการยืมสกิล/หมัดม่วงของ PHUZASHI

## Resource
ทั้งสอง .res สร้างด้วย Godot4.2.2 รองรับ4.2.2ขึ้นไป แคนวาสเสมือน1024x1024 pivot(512,960)
Importer รักษาภาพตัวเต็ม รวมหมวก ขวด และเสื้อที่ถืออยู่ โดยแยกทั้ง silhouette พร้อมอุปกรณ์ใน resource แทนการตัดแขนขา PNG ต้นทางรุ่นนี้แก้เฉพาะขวด/ซอสเป็นซีอิ๊วดำและเว้นระยะภาพใหม่
manifest.json / transform_manifest.json บันทึกกรอบภาพ จุดพื้น และสเกล

สร้างใหม่:
godot --headless --path . --editor --import --quit
godot --headless --path . --script tools/import_red_awakened.gd
godot --headless --path . --script tools/import_red_transform.gd
ใช้ Godot4.2.2 สำหรับขั้นตอนสร้าง .res เพื่อรักษาความเข้ากันได้

เพิ่ม skills.png / skills_frames.res: SOY_BOMB ขว้างขวด 8 ภาพ และ CARROT_SPIN หมุนเตะ 8 ภาพ นำเข้าด้วย tools/import_six_skill_art.gd บน Godot 4.2.2
