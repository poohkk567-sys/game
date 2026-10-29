# Compact rear ninja grapple

`ninja_grapple.png` contains eight separate complete pixel-art drawings (4×2), facing right. This is a squat gripping creature, not the tall guardian stand. Original generated pixels are preserved. `tools/import_ninja_grapple.gd` locates transparent gutters and aligns the eye/core while preserving all limbs and smoke. Regenerate with Godot4.2.2 after importing the PNG; it writes `assets/effects/ninja_grapple_frames.res`.

Gameplay height is100px normally and116px empowered. The ninja faces the victim's direction and sits64px behind their center, keeping the mask visible beyond the victim's body. Shader edges feather the atlas boundaries. The real movement lock remains on the victim; the smoke and creature never own HP, mana, hitboxes or timers.
