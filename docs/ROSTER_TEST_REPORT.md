# Roster / controllers / Fino / cheer verification

Godot4.2.2 and4.6.3, GL Compatibility. Functional suites run through `tools/check.sh`.

| Suite | Checks per engine | Result |
| --- | ---: | --- |
| Training / mountains / master skin | 88 | Pass |
| Sprite trial, including new Fino contact/recovery | 75 | Pass |
| VFX | 11 | Pass |
| Blink / Blink VFX | 13 +20 | Pass |
| Ground / air combos | 90 | Pass |
| Distinct combo poses | 30 | Pass |
| Demon Bind | 55 | Pass |
| Assjiro normal moves | 77 | Pass |
| Local versus | 91 | Pass |
| Transformation | 64 | Pass |
| Mana / guard | 75 | Pass |
| Gamepad input | 54 | Pass |
| Awakened carrot skills | 49 | Pass |
| Controller settings / persistence / remapping | 36 | Pass |
| New production rules / title / Fino / cheer / walk | 53 | Pass |
| Muay Thai / taller body / combos / selection | 50 | Pass |
| **Total** | **931** | **Zero failures** |

Original combat fixtures explicitly use100HP to preserve their existing damage/KO scenarios. Dedicated new-rule and Muay suites verify the actual production default of200HP per fighter. Solo practice retains100HP. Damage reduction keeps fractional HP:8 damage becomes5.6,14 becomes9.8,60 becomes42; normal guard chip2 becomes1.4 for awakened Assjiro. Guard cost is unchanged.

Controller tests include real InputMap routing through device-specific JoypadButton/Motion events, opposite device orders, per-player bindings, duplicate-button swaps, axis capture/neutral gating, actual remapped gameplay, ConfigFile roundtrips, runtime-ID changes, keyboard-only modes, cancelled edits, duplicate assignments, disconnect/reconnect and identical-model controllers. The modal preserves match state; settings are not applied on Cancel. R3 remains a recovery shortcut. Godot4.2 headless helpers flush input and push the root viewport for windowless UI callbacks.

**Controller hardware was not available. Input is simulated; results do not assert compatibility with a particular USB/Bluetooth controller or OS driver.** DEMO devices in review screenshots are explicitly labeled.

New gameplay tests verify grounded/cooldown/interruption gates, both dash directions and no dash invulnerability/guard, locked capped-form skills, unlocked awakened skills, HP/guard/recoil/pose behavior, real moving Fino contact exactly once, interrupted Fino body restoration, removal of the dragon from runtime effects, distance-driven walking, cheer arrival, eight-second expiry, increased move speed, the actual1.1-second demon lock and reset cleanup. Muay tests cover112 own drawings, body/hurtbox height, authentic elbow/knee source poses, shorter strike ranges,36/52-damage combos in both directions, normal MP rewards, aerial attacks, low stance, shield, dash, KO and actual three-character title selection.

Native rendering: **364 new samples per engine, zero failures**:

- Muay Thai:17 runtime states ×8 frames ×2 directions =272.
- New PHUZASHI walk:8×2 =16.
- Purple/black Fino rider:16×2 =32.
- Pink-shoe cheer support runner/cheer:16×2 =32.
- Actual standing/crouching shields on all3 profiles, both directions:12.

The renderer checks visible complete silhouettes and viewport clipping. Both native engines also display the actual controller-settings screen. Muay's crouch holds the deep pose; jab/teep contact drawings align with their damage windows. Old assets remain unchanged except the retired dragon texture, which is removed. The original approved PHUZASHI master SHA-256 remains:

`d0d6156d5114d612c1d04e39781fcd5c783eb09b0ba1268fc8b42c9779e6be06`

Review video is recorded directly from Godot4.6.3:1280×720,60FPS,1340 frames /22.333333 seconds. The current Thai guide and five preview screenshots ship with the Godot source ZIP. Other review screenshots stay in the repository. No EXE/PCK/editor cache is included. The packager validates CRC and every included file byte-for-byte and writes a SHA-256 file.
