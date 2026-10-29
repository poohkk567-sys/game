# ผลทดสอบ PHUZASHI CHILL / Blood Pact / ออร่า

ทดสอบบน Linux ด้วย Godot **4.2.2.stable** และ **4.6.3.stable** ทั้งระบบเกมแบบ headless และการเรนเดอร์จริง OpenGL Compatibility / Mesa llvmpipe

## ระบบเกม: 1,532 ข้อต่อรุ่น ผ่านทั้งหมด

`bash tools/check.sh` / `GODOT_BIN=/path/to/godot-4.2.2 bash tools/check.sh`

| ชุดตรวจ | ข้อ/รุ่น |
|---|---:|
| Training / spritesheet trial / VFX | 88 / 75 / 11 |
| Blink / Blink VFX | 13 / 20 |
| Air and ground combos / distinct combo poses | 90 / 30 |
| Demon Bind | 55 |
| Red Cap / local versus / transformation | 79 / 91 / 64 |
| Mana and guard / gamepads / carrot skills | 75 / 54 / 49 |
| Controller settings / established game rules | 36 / 53 |
| Muay Thai / six-slot skills | 47 / 115 |
| Contact and crouch controls | 140 |
| Keyboard/controller parity for both players | 222 |
| Blood Pact and guardian lifetimes | 49 |
| PHUZASHI CHILL model and full skill parity | 76 |
| **รวม 22 ชุด** | **1,532 ผ่าน / 0 ล้มเหลว** |

รวมสองรุ่น **3,064 ข้อ** ไม่มี SCRIPT ERROR หรือ ERROR ในผลตรวจสุดท้าย

- BLACK COAT: ใช้70MPครั้งเดียว เริ่มบัฟ/เลือดไหลตอนฟัน ลด20HPครบ5วินาที หยุดที่1HP แต่ตายจากอีกฝ่ายได้ บัฟ30%ครบ10วินาที ไม่ซ้อน ไม่เพิ่มchip ไม่รบกวนมานาปกติ ขัดจังหวะก่อนฟันแล้วไม่เกิดบัฟ หลังฟันโดนตีแล้วยังเลือดไหล รีเซ็ต/ตาย/เปลี่ยนตัวล้างสถานะ
- คอมโบจริงแบบหันซ้าย/ขวา: BLACK COAT ระหว่างบัฟต่อย44 / เตะ68 HP; PHUZASHI CHILL ต่อ34 / เตะ52 HP เหมือนตัวเดิม
- PHUZASHI CHILL: ภาพใหม่16คลิปหลัก128เฟรม ไม่มีการยืมภาพตัวเดิม มี Blink12เฟรมที่ประกอบจากภาพใหม่ และฟีโน่คนขับใหม่16เฟรม สกิลครบหกท่าค่าดาเมจ/มานา/จังหวะเดิม เชียร์เรียกหญิงจริง ออร่าม่วง ล็อค1.1วินาทีเมื่อได้บัฟ Counterสวน20HP และ Blink5MP
- PHUZASHI ทั้งสองแบบ: ออร่าปีศาจม่วงมีเฉพาะบัฟเชียร์ ล็อคขาจับค่าตอนร่าย บัฟหมดการร่ายครั้งถัดไปกลับ0.7วินาทีและภาพปกติ
- ASSJIRO: ผู้พิทักษ์ส้มทองเกิดช่วงแปลงและร่างหัวโล้น หายระหว่างพายุแครอท กลับหลังจบท่า ไม่เปลี่ยน70MP/เก็บมานา/ลดดาเมจ30%/สกิลฟรีติดคูลดาวน์
- Keyboard/joy: ทดสอบปุ่มจริงทั้งสองฝั่ง ค่าเริ่มต้นและรีแมป ลง+ปุ่มเตะเป็นS+K/เชียร์ ไม่ไปใช้ปุ่มกระโดด และอัลติ BLACK COAT ใช้ได้จริงทั้งคีย์บอร์ดและจอย
- ทดสอบดันตัวติดขอบ/การ์ด/ล็อค แรงถอย สั่นและhit pause เกจป้องกัน Perfect Guard การเลือกตัวและสลับฉาก คัตอินทุกโปรไฟล์ และคืน50MPเมื่อเริ่มยก

## ภาพจริง: 1,072 samples ต่อรุ่น ผ่านทั้งหมด

`godot --path . --audio-driver Dummy --fixed-fps 60 --script tests/test_roster_render.gd`

เรนเดอร์สองทิศทาง ตรวจภาพที่ไม่ว่างและไม่ชนขอบviewport ครอบคลุมมวยไทย PHUZASHI CHILL และBLACK COAT ทุกคลิป/เฟรม รวมภาพเดินPHUZASHI ฟีโน่ทั้งสองโมเดล ตัวช่วยเชียร์ ออร่าสามสี และคนอ้วนเปิดประตู16เฟรม รวมสองรุ่น **2,144 samples / 0 ล้มเหลว**

พบและแก้ประตูอยู่หลังฉากหลังจนมองไม่เห็น ปรับตำแหน่งให้เห็นหน้าคนอ้วนชัด และค่อยเผยออร่าแดงหลังฟัน พบshaderตัดalphaจากสีที่จางระหว่างBlink จึงใช้shaderของCHILLที่ตัดจากalphaต้นทางเพื่อคงร่างเงาจางไว้ โดยไม่เปลี่ยนจังหวะอมตะ/มานา

[ภาพยืนเปรียบเทียบทุกตัว](screenshots/pact_preview_all_characters.png) · [คอมโบหมัดสาม](screenshots/pact_preview_chill_punch_three.png) · [ฟีโน่ใหม่](screenshots/pact_preview_chill_fino.png) · [คนอ้วนฟัน](screenshots/pact_preview_fat_slash.png) · [ม่วง](screenshots/pact_preview_purple_bind.png) · [ส้มทอง](screenshots/pact_preview_gold_guardian.png)

วิดีโอ `PHUZASHI_Chill_Preview.mp4` บันทึกจากGodotจริง 1280×720 /60fps ประมาณ13วินาที เติม100MPเฉพาะสาธิต ทุกยกเล่นจริงเริ่ม50MPตามเดิม

## ไฟล์โปรเจกต์สำหรับเล่น

ชุดดาวน์โหลดมี assets/scenes/scripts/tests/tools ครบ รวมคอนเซปต์และภาพตรวจ ไม่มีEXE/PCK/cache/videoหรือZIPรุ่นเก่าซ้อน เนื่องจากไฟล์รวมใหญ่กว่า100MiB จึงแจกเป็นZIPที่GitHubสร้างจากสาขาซอร์สโดยตรง ไม่บรรจุZIPก้อนใหญ่ลงGitซ้ำ

ตรวจCRCและเทียบไฟล์ทุกไฟล์กับชุดที่แพ็ก ก่อนเปิดจากZIPที่แตกใหม่ด้วยGodot4.2.2 และตรวจ Blood Pact49 + CHILL76 + Controller Parity222 = **347 ข้อ / 0 ล้มเหลว** อีกครั้ง

ข้อจำกัดการตรวจ: Linux/OpenGL Compatibility และเหตุการณ์จอยจำลองทั้งสองเครื่องเล่น ยังไม่ได้จับจอยจริงของผู้ใช้บนWindows ผลการรีแมป/แบ่งอุปกรณ์ยืนยันด้วยInputEventJoypadButton/axisของGodotจริง ไม่จำลองด้วยคีย์บอร์ดแทน

แบบเสื้อแทร็กดำ–ทองเป็นภาพคอนเซปต์ปรับลายเส้นเท่านั้น ไม่ใช่ตัวที่หกในหน้าเลือกและยังไม่มีท่า ตามคำขอ

Master เดิมยังคงSHA-256:
`d0d6156d5114d612c1d04e39781fcd5c783eb09b0ba1268fc8b42c9779e6be06`
