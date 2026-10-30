# Crimson Temper effects

`crimson_skills.png` is the original transparent image generated with image_gen from the approved Crimson Grin guardian reference. It contains four stages per row: FANG, DRIVE, RISE, CRUSH, BURST. The PNG is copied intact from `/workspace/generated_images/exec-eda6d058-988e-48f1-9d0e-4f063c839beb.png`.

`tools/import_black_skills.gd` reads alpha gutters in Godot, creates clipped AtlasTextures, and saves `crimson_frames.res` with Godot 4.2.2. No bitmap editing, recoloring of old effects, or runtime image slicing is required. A small virtual transparent margin keeps the effect off its destination edge. Runtime draws the dedicated atlas with alpha blending, scarlet contact sparks and directional trails. The other fighters' sheets remain independent.
