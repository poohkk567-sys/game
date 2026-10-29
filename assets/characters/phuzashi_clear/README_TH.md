# PHUZASHI แบบใหม่ที่เลือกแล้ว

อ้างอิง `approved_reference.png` ฝั่งชุดดำ: ผิวขาวอมชมพู ผมดำหน้าม้าทรงซอย เสื้อดำลายใบหน้าขนาดใหญ่ทับแขนลายทางถี่ หูฟังมีสายขาว กระเป๋าดำ กางเกงกางเขนและลายโซ่สีขาว รองเท้าดำปลาย/พื้นสีครีม

ภาพโปร่งใส 8 แผ่น แผ่นละ 4 คอลัมน์ × 4 แถว อ่านซ้ายไปขวา สองแถวบนเป็นท่าแรก 8 เฟรม สองแถวล่างเป็นท่าที่สอง 8 เฟรม รวม 16 ท่า / 128 ภาพเต็มตัว

| แผ่น | ท่าแรก | ท่าที่สอง |
| --- | --- | --- |
| idle_walk.png | IDLE | WALK |
| run_jump.png | RUN | JUMP |
| crouch_guard.png | CROUCH | GUARD |
| punch_kick.png | PUNCH | KICK |
| punch_combo.png | PUNCH_2 ฮุก | PUNCH_3 อัปเปอร์คัต |
| kick_combo.png | KICK_2 หมุนเตะ | KICK_3 เตะสับ |
| hit_fall.png | HIT | FALL |
| powers.png | SPECIAL | ULTIMATE |

AIR_PUNCH/AIR_KICK ใช้ภาพโจมตีของชุดนี้ BOUND ใช้ HIT ค้าง DEMON_BIND ใช้ SPECIAL และ BLINK ใช้ 12 ท่าจาก CROUCH/RUN/IDLE ของชุดนี้
ท่าโจมตีคงระยะ ดาเมจ MP และช่วง active เดิมทั้งหมด เอฟเฟกต์กระสุน มังกร หมัดม่วง และปีศาจใช้ไฟล์เดิม ตำแหน่งพลังหมัดม่วงปรับให้ตรงกำปั้นของตัวใหม่

`manifest.json` ระบุพื้นที่ภาพ จุดพื้น และสเกลต่อท่า `clear_frames.res` เป็น SpriteFrames สำหรับ Godot 4.2.2+ แคนวาสเสมือน1024×1024 pivot(512,960) ขนาดตัวในเกมประมาณ156พิกเซล
Importer อ่านภาพเต็มตัวและเรียงตามแถวจากระดับพื้น แยกเฟรมที่กรอบสี่เหลี่ยมทับกันด้วย silhouette ทั้งตัวใน resource เพื่อรักษาแขนขาครบ ไม่มีการแก้ PNG ต้นทาง

สร้าง .res ใหม่ด้วย Godot **4.2.2**:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tools/import_clear_phuzashi.gd
```

ภาพถ่ายต้นฉบับบุคคลไม่ได้ถูกใส่ใน Repository ไฟล์ PHUZASHI รุ่นเดิมยังเก็บไว้สำหรับตรวจย้อนหลัง
