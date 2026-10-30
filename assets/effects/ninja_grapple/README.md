# Small standing ninja chain bind

`ninja_grapple.png` contains eight complete standing chain-pulling drawings (4×2), facing right. These replace the crouched creature that was hidden by the victim. Original generated pixels are preserved. The existing bank path and GRIP clip name remain compatible with consumers. `tools/import_ninja_grapple.gd` locates transparent gutters, aligns the eye/core and stores each frame's alpha bounds. Regenerate with Godot4.2.2 after importing the PNG; it writes `assets/effects/ninja_grapple_frames.res`.

Gameplay height remains100px normally and116px empowered. The ninja stands104px behind the victim, with its complete body clamped inside12..1268px near arena edges. Its sprite has a separate foreground draw layer; torso chains use a higher layer and rear/front halves to wrap the victim without being hidden. The real movement lock remains on the victim; these effects do not own damage, mana or lock timers.
