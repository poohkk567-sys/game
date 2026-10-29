# นินจายืนตัวเล็กและโซ่รัดตัว

[ดาวน์โหลดโปรเจกต์ Godot รุ่นนี้](https://github.com/poohkk567-sys/game/archive/refs/heads/codex/standing-bind-source.zip)

แตกZIPทั้งหมด → Godot4.2.2ขึ้นไป → Import `project.godot` → Import & Edit → รอนำเข้า → F5 ไม่มีEXEใหม่

ท่าล็อคของ PHUZASHI และ PHUZASHI CHILL เปลี่ยนจากปีศาจย่อตัวเกาะที่ถูกคู่ต่อสู้บัง เป็นนินจาร่างเล็ก **ยืนดึงโซ่** มีภาพแอนิเมชันใหม่8เฟรม แยกจากสแตนด์ใหญ่ที่ขึ้นตอนเชียร์

- วาร์ปหายแล้วโผล่หลังเป้าหมายตามทิศที่เป้าหมายหันเหมือนเดิม ยืนห่างจากกลางตัว104pxให้เห็นทั้งตัว ขนาด100pxปกติ/116pxเมื่อได้บัฟ
- โซ่ม่วงเป็นข้อ ๆ พาดจากมือไปรัดหน้าอก เอวและสะโพก มีโซ่ไขว้ลำตัว วาดส่วนหลังและส่วนหน้าแยกกันให้รู้สึกรัดรอบตัวจริง ไม่บังหน้าเป้าหมาย
- นินจาและโซ่มีลำดับการวาดของตัวเอง คู่ต่อสู้จึงไม่ทับจนหายอีก ใกล้ขอบสนามขยับภาพให้อยู่ครบภายในจอ
- คงปุ่มS+J/จอยลง+ต่อย(ค่าเริ่มต้นลง+X) มานา25 ระยะ620px ไม่ทำดาเมจ ล็อค0.7วินาทีปกติ/1.1วินาทีขณะมีบัฟเชียร์
- ท่าจบ รีเซ็ต หรือเปลี่ยนยกจะลบนินจาและโซ่พร้อมสถานะล็อค เงื่อนไขเชียร์ ดาวกระจาย พระASS และฟีโน่จากรุ่นก่อนคงเดิม

[ขวาปกติ](screenshots/standing_bind_right_normal.png) · [ซ้ายปกติ](screenshots/standing_bind_left_normal.png) · [มีบัฟ](screenshots/standing_bind_right_buff.png) · [ขอบขวา](screenshots/standing_bind_wall_right.png) · [ขอบซ้าย](screenshots/standing_bind_wall_left.png)

[วิดีโอในเกม](https://github.com/poohkk567-sys/game/blob/codex/standing-ninja-chains/docs/PHUZASHI_Standing_Bind_Preview.mp4?raw=true) · [ผลทดสอบ](STANDING_BIND_TEST_REPORT.md) · [ปุ่มและกติกาทั้งเกม](BLOOD_PACT_CHILL_TH.md)

วิดีโอใช้มานา100เฉพาะfixtureสาธิต การเล่นจริงเริ่ม50MP ไม่มีวิดีโอในZIPซอร์ส
