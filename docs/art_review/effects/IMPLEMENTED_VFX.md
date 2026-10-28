# PHUZASHI VFX — integrated edition

The pre-existing **16-cell Dark Pulse** and **16-cell Violet Dragon** draft textures have been copied without modification from docs/art_review/effects into assets/effects, where Godot can import them.

Runtime frame mapping:

- Dark Pulse 0–3 charge from hand, 4–7 release, 8–11 traveling projectile, 12–15 impact.
- Violet Dragon 0–3 charging seal, 4–7 manifestation, 8–11 surge, 12–15 explosion/recovery.

The effects use clipped atlas source regions, nearest filtering, facing mirroring, and additional timed arcs, sparks and trails. The impact persists visually for 0.28 seconds, but collision is disabled as soon as it hits. The projectile still moves at **620 px/s**, costs **25 MP**, and deals **24 damage only once**. Ultimate remains **60 MP and 60 damage**, with its original damage window. No player sprite, shoe, character collision box, or attack balance was changed.

**Test:** Import in Godot 4.2.2+ and run tools/check.sh, which also executes tests/test_vfx.gd. Then press F5, H for SPECIAL, and U for ULTIMATE (check F1 move list for current key bindings). F2 demos all moves. Test both left and right directions. Source changes do NOT update the older Windows ZIP automatically; a fresh export is necessary.

The original art was described as a **draft**, and clipped cell boundaries may still need aesthetic polish in LibreSprite. This update integrates all 32 frames into functional gameplay rather than asserting that the artwork itself is final-quality.
