# ดาวน์โหลด PHUZASHI — DARK PULSE

รุ่นล่าสุด: [Red Cap อัลติ100MP แปลงร่าง (.zip)](https://github.com/poohkk567-sys/game/blob/codex/red-cap-ultimate-transform/docs/downloads/PHUZASHI_Red_Cap_Transform_Godot.zip?raw=true) รวมสนามโรงเรียนและสองผู้เล่น ไม่มี EXE ใหม่ ดู [วิธีใช้](../RED_CAP_TRANSFORM_TH.md)

รุ่นก่อน: [สนามโรงเรียน สองผู้เล่น และโมเดลใหม่ (.zip)](https://github.com/poohkk567-sys/game/blob/codex/school-local-versus/docs/downloads/PHUZASHI_School_2P_Godot.zip?raw=true) เปิด Godot Import `project.godot` → F5 ดู [ปุ่มสองผู้เล่น](../LOCAL_VERSUS_TH.md) ไม่มี EXE ใหม่

รุ่นก่อน: [โปรเจกต์ Red Cap (.zip)](https://github.com/poohkk567-sys/game/blob/codex/red-cap-normal-moves/docs/downloads/PHUZASHI_Red_Cap_Normals_Godot.zip?raw=true) · [สไปรต์ชีตแยก](https://github.com/poohkk567-sys/game/blob/codex/red-cap-normal-moves/docs/downloads/RED_CAP_Normal_Spritesheets.zip?raw=true) แตก ZIP → Godot Import `project.godot` → F5 → Tab สลับตัวละคร รอบนี้ไม่มี EXE ใหม่

ไฟล์ Windows ด้านล่างเป็นรุ่นเก่าก่อนเพิ่ม Red Cap

- [Windows 64-bit: เปิดเล่นได้เลย](https://github.com/poohkk567-sys/game/blob/codex/phuzashi-training-complete/docs/downloads/PHUZASHI_Windows_x64.zip?raw=true)
- [โปรเจกต์ Godot: เปิดแก้ไข](https://github.com/poohkk567-sys/game/blob/codex/phuzashi-training-complete/docs/downloads/PHUZASHI_Godot_Source.zip?raw=true)

## Windows

1. แตก ZIP ทั้งหมด
2. เข้าโฟลเดอร์ PHUZASHI แล้วดับเบิลคลิก PHUZASHI.exe
3. คลิกหน้าต่างเกม กด F2 ดูทุกท่า หรือ F1 ดูปุ่มควบคุม

ข้อมูลเกมฝังอยู่ใน EXE แล้ว ไม่ต้องติดตั้ง Godot หรือหาไฟล์ PCK เพิ่ม ชุดนี้มีตัวละครเดียวและ spritesheet ครบ 96 เฟรม

## Godot

แตก ZIP เปิด Godot 4.2.2+ แล้ว Import project.godot กด F5 เล่น ไฟล์ source แยกจาก executable เพื่อให้แก้ไขและตรวจงานได้

## การตรวจชุดไฟล์

- Export release ด้วย Godot 4.6.3 และ template ทางการ
- ตรวจ Windows PE x86-64 และ header/footer ของ PCK ที่ฝังใน EXE
- ตรวจ CRC และ SHA-256 ของ ZIP ทั้งสองชุด
- เปิด exported runtime ฝั่ง Linux ด้วยข้อมูลเกมชุดเดียวกัน ทั้งแบบ headless และ GL Compatibility
- แตก source ZIP แล้วรันทดสอบ 163 รายการด้วย Godot 4.2.2 ผ่าน
- ยังไม่ได้รัน EXE บน Windows จริง; สถานะนี้ระบุใน build_manifest.json

ไฟล์ SHA-256 และ commit ของข้อมูลเกมอยู่ในโฟลเดอร์นี้ เวอร์ชันดาวน์โหลดเป็น snapshot: เมื่อเปลี่ยนเกม ให้สร้าง ZIP ใหม่ด้วย tools/package_game.py

## สร้าง ZIP ใหม่

ใช้ Godot 4.6.3 พร้อม Windows/Linux release templates ที่ตรงเวอร์ชัน และ LICENSE.txt/COPYRIGHT.txt จาก Godot (เปลี่ยนชื่อเป็น GODOT_LICENSE.txt/GODOT_COPYRIGHT.txt ในโฟลเดอร์ licenses):

```sh
python3 tools/package_game.py --templates /path/to/templates --licenses /path/to/licenses
```

เครื่องมือสร้างโปรเจกต์ staging แยกจากไฟล์จริง, export EXE ที่ฝัง PCK, export และทดสอบ Linux runtime, สร้าง ZIP พร้อม checksums และ source แยกชุด การอ้างอิง template เฉพาะเครื่องไม่ถูกใส่ลง source ZIP
