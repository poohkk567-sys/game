# Mana, guard, carrot skills and gamepad validation

Validated on Godot 4.2.2 and 4.6.3, GL Compatibility. Run `tools/check.sh` for the complete functional suite.

| Integration suite | Checks per engine | Result |
| --- | ---: | --- |
| Training / mountain / original skin | 88 | Pass |
| Sprite trial | 75 | Pass |
| Original VFX | 11 | Pass |
| Blink gameplay / VFX | 13 + 20 | Pass |
| Ground and aerial combos | 90 | Pass |
| Distinct combo poses | 30 | Pass |
| Original Demon Bind | 55 | Pass |
| Red Cap normal moves | 77 | Pass |
| Local versus | 91 | Pass |
| Red transformation | 64 | Pass |
| Mana / guard / Perfect Guard | 75 | Pass |
| Gamepads | 54 | Pass |
| Red carrot skills | 49 | Pass |
| **Total** | **792** | **Zero failures** |

The new suites cover real collision queries, exact 7 MP/s charging, attack/air/guard/bind/transform/KO restrictions, one mana award per normal contact, no rewards on whiffs/blocks/perfect guards/skills, 3+3+5 combo rewards, every guard cost, recovery delay, one-second break, overlapping movement locks, reset/pause, physical headbutt movement, seven barrage pulses, interruptions, mirrored directions, both Red Cap forms, and actual key bindings.

Controller tests send InputEventJoypadButton/Motion through Godot's real device-specific InputMap using device IDs 2/5/7. They cover one pad + keyboard, two simultaneous pads, axis/trigger deadzones, all mapped controls, profile-specific skills and ultimates, Start/Back, held-trigger neutral rearming, replacement-device IDs, disconnect pause and training navigation. Godot4.2 headless tests explicitly flush input and feed the root viewport for UI callbacks because its headless DisplayServer has no window event dispatcher. The same **54 controller checks also pass in a native Godot4.2 window**, using its window dispatcher.

**No physical gamepad was available; these results validate simulated controller input, not a particular USB/Bluetooth controller or driver.**

Native rendering:

- New overlays: **140 samples per engine**, zero failures: 16 headbutt cells +16 barrage cells +charge/perfect-guard/guard-break, both directions, both capped/awakened bodies. Compares rendered output with the intact fighter baseline and checks for clipping/missing effects.
- Retained awakened/transformation artwork: **304 samples on4.6.3**, zero failures.
- Retained approved PHUZASHI artwork: **344 frames on4.6.3**, zero failures.
- Total inspected native regression samples on4.6.3: **788**.
- Default school scene recorded directly in Godot at1280×720, 60FPS, **1297 frames /21.616667 seconds**. Eleven screenshots are in `docs/screenshots/mana_carrot_*`.

Approved PHUZASHI master remains byte-identical:

`d0d6156d5114d612c1d04e39781fcd5c783eb09b0ba1268fc8b42c9779e6be06`

All preexisting character drawings and purple VFX textures remain unchanged. Headbutt leans the existing whole-body run drawings; barrage alternates the existing complete punch drawings. Two new transparent16-cell orange/green effect sheets render separately behind the fighter.

Source packaging uses `tools/package_combo_source.py` with review-prefix/video filters to include all runtime assets, scenes, scripts, tests and tools, current review media, Thai guides and startup instructions. The packager checks ZIP CRC, compares every archived file to its workspace source, writes SHA-256, and rejects EXE/PCK/editor caches. No new executable is produced.
