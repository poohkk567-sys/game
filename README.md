# PHUZASHI — DARK PULSE

เกมต่อสู้ 2D มุมมองด้านข้าง ฉากฝึกสลับเล่น PHUZASHI / RED CAP ทีละตัว สำหรับ Godot **4.2.2+** รุ่นปัจจุบันมีภาพเต็มตัว **240 เฟรม**: PHUZASHI แบบใหม่128เฟรม และ RED CAP112เฟรม เก็บภาพเดิมไว้สำหรับตรวจย้อนหลัง พร้อมโจมตีกลางอากาศและคอมโบสามจังหวะ

![Twelve illustrated moves](docs/screenshots/pose_gallery.png)

[ชมวิดีโอทุกท่าจากเกมจริง](docs/PHUZASHI_All_Moves.mp4)

## ล่าสุด: PHUZASHI แบบใหม่ · สนามโรงเรียน · 2 ผู้เล่น

[ดาวน์โหลดเกมทดสอบสองผู้เล่น (.zip)](https://github.com/poohkk567-sys/game/blob/codex/school-local-versus/docs/downloads/PHUZASHI_School_2P_Godot.zip?raw=true) — แตก ZIP → Godot Import `project.godot` → F5

PHUZASHI ใช้โมเดลผิวขาวแบบใหม่ครบ128เฟรม โดยคงสกิลและเอฟเฟกต์เดิมครบ สนามหน้าโรงเรียนตามภาพอ้างอิง พร้อม RED CAP เล่นพร้อมกันคนละตัวบนคีย์บอร์ดเดียว มี HP/MP แยกสองฝั่ง ระบบแพ้ชนะ จับเวลา และแข่งชนะ2ยก

**P1:** A/D เดิน · Space กระโดด · J/K ต่อย/เตะ · L ป้องกัน · U/I สกิล · S+J ปีศาจ

**P2:** ลูกศรเดิน/กระโดด/หมอบ · Numpad1/2/3 หรือ , . / ต่อย/เตะ/ป้องกัน

F1 ดูปุ่ม · R เริ่มแมตช์ใหม่ · F6 สลับสนามฝึกคนเดียว อ่าน [คู่มือสองผู้เล่น](docs/LOCAL_VERSUS_TH.md) / [วิดีโอ](docs/PHUZASHI_Local_Versus.mp4) รุ่นนี้ไม่มี EXE ใหม่

![สนามใหม่พร้อมสองผู้เล่น](docs/screenshots/versus_school_gate.png)

## ตัวหมวกแดงไม่มีผม พร้อมท่าปกติและคอมโบ

[ดาวน์โหลดเกมทดสอบ Red Cap (.zip)](https://github.com/poohkk567-sys/game/blob/codex/red-cap-normal-moves/docs/downloads/PHUZASHI_Red_Cap_Normals_Godot.zip?raw=true) · [สไปรต์ชีต 112 เฟรม](https://github.com/poohkk567-sys/game/blob/codex/red-cap-normal-moves/docs/downloads/RED_CAP_Normal_Spritesheets.zip?raw=true)

แตก ZIP → Godot Import `project.godot` → F5 → **Tab สลับตัวละคร** มีเดิน วิ่ง กระโดด หมอบ ป้องกัน กระโดดต่อย/เตะ และคอมโบ J–J–J / K–K–K ของตัวใหม่ครบ รวม 16 สถานะท่าปกติ ไม่มีผมโผล่ใต้หมวกแดง สกิลพิเศษของตัวใหม่ยังเว้นไว้ตามที่ขอ

[วิธีเล่นและภาพในเกม](docs/RED_CAP_NORMAL_MOVES_TH.md) · [วิดีโอ](docs/PHUZASHI_Red_Cap_Normals.mp4) ไม่มี EXE ใหม่ในรอบนี้

## S + J เรียกปีศาจล็อกเป้า (PHUZASHI)

[ดาวน์โหลดเกมทดสอบ Demon Bind (.zip)](https://github.com/poohkk567-sys/game/blob/codex/demon-bind-skill/docs/downloads/PHUZASHI_Demon_Bind_Godot.zip?raw=true) — แตก ZIP → Godot Import `project.godot` → F5

กด **S ค้างแล้วกด J** หรือกด S+J พร้อมกัน ใช้ **25 MP** เรียกปีศาจเงาพุ่งไปล็อกเป้าด้านหน้า **0.7 วินาทีหลังจับติด** มีโซ่ม่วงและเวลานับถอยหลัง เป้าฝึกหยุดลอยขณะโดนล็อก และระบบรองรับการหยุดตัวละครหรือ AI ที่เคลื่อนที่จริงแล้ว ดู [วิธีเล่นและรายละเอียด](docs/DEMON_BIND_TH.md) / [วิดีโอในเกม](docs/PHUZASHI_Demon_Bind.mp4)

## คอมโบเปลี่ยนท่าจริงและหมัดม่วงปิดคอมโบ

[ดาวน์โหลดเกมทดสอบรุ่นท่าใหม่ (.zip)](https://github.com/poohkk567-sys/game/blob/codex/distinct-combo-poses/docs/downloads/PHUZASHI_Distinct_Combos_Godot.zip?raw=true) — แตก ZIP → Godot Import `project.godot` → F5

**J–J–J:** หมัดตรง → หมัดฮุกบิดตัว → อัปเปอร์คัตพลังม่วง

**K–K–K:** เตะเดิม → หมุนตัวเตะ → ยกขาเตะฟาดปิดคอมโบ

ใช้ภาพใหม่ 4 ชุด ชุดละ 8 เฟรม หมัดที่ 3 มีพลังหุ้มกำปั้น เส้นพลังขณะยกหมัด และระเบิดม่วงเมื่อโดนเป้าจริง ดู [รายละเอียดและสไปรต์ชีต](docs/DISTINCT_COMBO_POSES_TH.md) / [วิดีโอจากเกมจริง](docs/PHUZASHI_Distinct_Combos.mp4) ไม่มี EXE ใหม่ในรอบนี้

## กระโดดต่อย–เตะ และคอมโบ 3 จังหวะ

[ดาวน์โหลดเกมทดสอบ Godot รุ่นคอมโบ (.zip)](https://github.com/poohkk567-sys/game/blob/codex/air-attacks-three-hit-combos/docs/downloads/PHUZASHI_Air_Combos_Godot.zip?raw=true) — แตก ZIP → Import `project.godot` → F5

กด **Space + J** กระโดดต่อย / **Space + K** กระโดดเตะ หรือกด J/K หลังเริ่มกระโดดแล้วก็ได้ กด **J–J–J** เพื่อต่อย 3 จังหวะ และ **K–K–K** เพื่อเตะ 3 จังหวะ กดต่อเนื่องล่วงหน้าได้ มีเอฟเฟกต์ท่าปิดคอมโบและ F2 สาธิตท่าใหม่ ดู [วิธีเล่นและดาเมจ](docs/COMBAT_COMBOS_TH.md) / [วิดีโอจากเกมจริง](docs/PHUZASHI_Air_Combos.mp4) ชุดนี้ไม่มี EXE ใหม่

## Shadow Blink พร้อมเอฟเฟกต์รอยแยก 16 เฟรม

[ดาวน์โหลดโปรเจกต์ทดสอบ Godot (.zip)](https://github.com/poohkk567-sys/game/blob/codex/shadow-blink-enhanced-vfx/docs/downloads/PHUZASHI_Shadow_Blink_FX_Godot.zip?raw=true) — แตก ZIP → Import `project.godot` → F5 → แตะ A หรือ D สองครั้งเพื่อพุ่งหลบ

เพิ่มรอยแยกต้นทาง เส้นพลังสายฟ้า เงาร่างตามหลัง และวงระเบิดปลายทาง ใช้ภาพที่ผู้ใช้เลือก ดู [รายละเอียดและภาพในเกม](docs/SHADOW_BLINK_TH.md) หรือ [วิดีโอพุ่งซ้าย–ขวา](docs/PHUZASHI_Shadow_Blink_FX.mp4) รอบนี้ไม่มี EXE ใหม่

## ดาวน์โหลดไฟล์เล่นบน Windows

[ดาวน์โหลด PHUZASHI สำหรับ Windows 64-bit (.zip)](https://github.com/poohkk567-sys/game/blob/codex/phuzashi-training-complete/docs/downloads/PHUZASHI_Windows_x64.zip?raw=true)

แตก ZIP แล้วเข้าโฟลเดอร์ `PHUZASHI` ดับเบิลคลิก `PHUZASHI.exe` เล่นได้โดยไม่ต้องติดตั้ง Godot กด F2 สาธิตทุกท่า หรือ F1 ดูปุ่มควบคุม

[ไฟล์โปรเจกต์ Godot สำหรับแก้ไข (.zip)](https://github.com/poohkk567-sys/game/blob/codex/phuzashi-training-complete/docs/downloads/PHUZASHI_Godot_Source.zip?raw=true)

## เปิดเล่นผ่าน Godot

1. เปิด Godot → Import → เลือก `project.godot`
2. กด **F5** เล่น หรือเปิด `scenes/main.tscn` แล้วกด **F6**
3. กด **F2** สาธิตครบทุกท่า หรือ **F1** ดูรายการปุ่ม

```sh
godot --path .
```

## ท่าทั้งหมด

ตารางนี้เป็นท่าต้นฉบับ PHUZASHI; ตัวหมวกแดงมีสไปรต์ของตัวเองเพิ่มอีก 112 เฟรมตามลิงก์ด้านบน

เพิ่มใหม่ **80 เฟรมใน 5 แผ่น** ต่อจากยืน–เดิน 16 เฟรมที่ผู้ใช้เลือก รูปลักษณ์อ้างอิง PHUZASHI ชุดเดียวกัน

| ท่า | เฟรม | การเล่น | ภาพต้นทาง |
| --- | --- | --- | --- |
| IDLE / WALK | 8 + 8 | วนรอบ | [ยืน–เดิน](assets/characters/drafts/idle_walk_draft.png) |
| RUN / JUMP | 8 + 8 | วิ่งวนรอบ / กระโดดตามฟิสิกส์ | [เคลื่อนไหว](assets/characters/spritesheets/mobility.png) |
| CROUCH / GUARD | 8 + 8 | เข้าท่าแล้วค้างเฟรมสุดท้าย | [หมอบ–ป้องกัน](assets/characters/spritesheets/defense.png) |
| PUNCH / KICK | 8 + 8 | เตรียม–สัมผัส–คืนท่า | [ต่อย–เตะ](assets/characters/spritesheets/strikes.png) |
| HIT / FALL | 8 + 8 | โดนโจมตี / ล้ม–นอน–ลุก | [รับแรงโจมตี](assets/characters/spritesheets/reactions.png) |
| SPECIAL / ULTIMATE | 8 + 8 | ชาร์จ–ปล่อยพลัง–คืนท่า | [สกิล–อัลติเมต](assets/characters/spritesheets/powers.png) |

ใช้ `AnimatedSprite2D` กับ `SpriteFrames` ทั้ง 12 สถานะ ไม่มีการดัดข้อต่อหรือ mesh กับภาพชุดใหม่ เอฟเฟกต์กระสุน โล่ และมังกรแสดงแยกจากตัวละคร เฟรมโจมตีสัมพันธ์กับช่วงสร้างความเสียหายจริง

## ปุ่มควบคุม

| ปุ่ม | การทำงาน |
| --- | --- |
| A / D หรือ ← / → | เดินและหันตามทิศทาง |
| Shift + ทิศทาง | วิ่ง |
| Space | กระโดดและควบคุมทิศทางกลางอากาศ |
| S / ↓ ค้าง | หมอบ ลดขนาด collider |
| L ค้าง | ป้องกัน; ทดลองด้วย H / N |
| J / K | ต่อย 8 damage / เตะ 14 damage |
| U | Dark Pulse — 25 MP, กระสุนเดินทาง, 24 damage |
| I | Ultimate — 60 MP, มังกรพลังม่วง, 60 damage |
| H / N | ทดลองโดนโจมตี 8 HP / ล้ม 18 HP แล้วลุกอัตโนมัติ |
| R | รีเซ็ตตำแหน่ง HP, MP, เป้า และกระสุน |
| F1 / F2 | รายการท่า / สาธิตครบ 12 ท่า |
| F3 / F4 | แสดง hitbox / เทียบกับแอนิเมชันจาก Master เดิม |
| Esc | หยุด / เล่นต่อ |

เข้าใกล้คริสตัลด้านขวาเพื่อต่อยและเตะ สกิลยิงได้จากระยะไกล MP ฟื้น 9 หน่วย/วินาที การโจมตีมีช่วงเตรียม/ออกท่า/คืนท่า และสร้างความเสียหายหนึ่งครั้งต่อท่าต่อเป้า การป้องกันลดความเสียหายจาก H / N เหลือ 2 HP

## การจัดเฟรมและไฟล์ต้นฉบับ

ภาพ PNG ต้นทางมีท่าที่ยื่นพ้นกริดปกติ จึงตัดตามตัวละครที่ต่อเนื่องกันจริง ไม่แบ่งภาพเป็นช่องเท่ากันจนมือหรือเท้าขาด `AtlasTexture` ใช้ canvas ร่วม 512×384 และ pivot (256,360) เท้าทุกเฟรมอยู่ระดับเดียวกัน ใช้สเกลเดียวตลอดชุด

เฟรมล้มสองเฟรมมีกรอบภาพซ้อนกับตัวข้าง ๆ ตัวนำเข้าแยกเฉพาะพิกเซลของตัวที่ถูกต้องแบบ lossless และเก็บเป็น texture ใน resource ส่วนภาพ PNG ต้นทางยังคงเดิม ข้อมูลเฟรมทั้งหมดอยู่ใน [manifest.json](assets/characters/spritesheets/manifest.json)

Master เดิม `assets/characters/PHUZASHI_MASTER_SHOES_APPROVED.png` คงเดิมทุกไบต์:

```text
SHA-256 d0d6156d5114d612c1d04e39781fcd5c783eb09b0ba1268fc8b42c9779e6be06
```

ภาพแอนิเมชันชุดใหม่เป็นภาพเต็มตัวที่สร้างต่อจากชุดยืน–เดินที่ผู้ใช้เลือก ไม่ใช่การคัดลอก Master เฟรมเดียวซ้ำให้เป็นทุกท่า

## โครงสร้าง

```text
assets/characters/              Master และชุดยืน–เดินเดิม
assets/characters/spritesheets/ แผ่นใหม่, manifest และ SpriteFrames
scenes/                        ฉากฝึกและฉากตัวละคร
scripts/character/             Input, movement, combat, animation และ projectile
scripts/stage/                 ฉากภูเขา คริสตัล และโหมดสาธิต
scripts/ui/                    HUD, รายการท่า และ pause overlay
tests/                         ตรวจระบบเกม เฟรมภาพ และบันทึกสาธิต
tools/                         ตัวนำเข้า spritesheet และคำสั่งทดสอบ
docs/                          รายงาน ภาพ และวิดีโอ
browser/                       HTML ต้นแบบเก่า เก็บไว้อ้างอิง
```

## ทดสอบและสร้าง resource ใหม่

```sh
tools/check.sh
# หรือระบุ binary:
GODOT_BIN=/path/to/godot tools/check.sh
```

ทดสอบบน Godot 4.2.2 และ 4.6.3: ระบบเกม 88 รายการ + ระบบ spritesheet 75 รายการ รวม **163 รายการต่อเวอร์ชัน** และภาพเรนเดอร์ **192 เฟรมต่อเวอร์ชัน** มี CI ตรวจซ้ำ ดู [รายงาน](docs/TEST_REPORT.md) และ [รายละเอียดระบบ](docs/IMPLEMENTATION.md)

การสร้าง `phuzashi_frames.res` ใหม่ใช้ **Godot 4.2.2** เพื่อให้ binary resource อ่านได้ตั้งแต่เวอร์ชันขั้นต่ำขึ้นไป:

```sh
/path/to/godot-4.2.2 --headless --path . --editor --import --quit
/path/to/godot-4.2.2 --headless --path . --script tools/import_spritesheets.gd
```

ผู้เล่นเปิดเกมได้ทันทีจาก resource ที่รวมมาแล้ว ขั้นตอนนำเข้าใหม่นี้ใช้เมื่อเปลี่ยนภาพต้นทาง
