# Distinct combo poses and purple uppercut validation

Four ground combo stages now use newly drawn full-body animations, eight frames
each. The base 96-frame resource, original character PNGs, airborne controls,
input buffer, damage totals and Shadow Blink assets remain unchanged.

The uppercut's hit shape spans the rising sweep. Its purple energy follows
per-frame fist markers, and its short-lived impact is spawned only by a real hit.
Both visual layers pause and clear on reset; fist energy also clears on interruption,
while impacts finish their short fade without applying extra damage. MP costs and
damage remain 8/10/16 and 14/16/22 for the ground chains.

## Automated checks

`tools/check.sh` passed **324 checks per engine** on Godot **4.2.2** and **4.6.3**:

| Suite | Checks | Failures |
| --- | ---: | ---: |
| Training / physics / original art / showcase | 88 | 0 |
| Base illustrated animations | 75 | 0 |
| Pulse / dragon VFX | 11 | 0 |
| Blink gameplay | 13 | 0 |
| Illustrated Blink lifecycle | 20 | 0 |
| Air attacks / combos / new source selection | 87 | 0 |
| New full-body frames / powered fist / impact lifecycle | 30 | 0 |
| Total per engine | **324** | **0** |

The 30 added checks verify all 32 complete drawings and pivots, playing the
uppercut, tracking its raised fist in both facings, one real hit per stage,
one impact per finisher, pause/resume, miss behavior, interruption, expiry,
reset and restoring the original idle scale. Existing combo tests now require
the four distinct sheets; the aerial normals still require unchanged base art.

## Actual rendering

`tests/test_combo_pose_render.gd` rendered all 32 drawings in both directions:
**64 samples, zero failures**. It checks connected whole-body silhouettes,
ground alignment and clipping in a transparent viewport. CI runs this alongside
the existing base-sprite and master-rig render checks.
The original base-sprite render suite also passed locally: **192 frames, zero
failures**, confirming that returning from the larger combo canvas does not
change the original ground alignment or silhouettes.

`tests/record_combo_poses.gd` captures both complete grounded combos, facing
right and left, at 60% speed so the anticipation, turn, strike and recovery are
readable. See `docs/PHUZASHI_Distinct_Combos.mp4` and screenshots under
`docs/screenshots/distinct_combos/`. OpenGL Compatibility uses a Mesa llvmpipe
virtual display; its unsupported VSync warning is a display limitation.
The complete capture rendered **927 frames at 60 FPS** (15.45 seconds), without
project script/shader errors.

## Delivery

The Godot source ZIP includes new sheets/resources, scripts, tests, Thai opening
instructions and review media. Packaging verifies CRCs and every file's bytes.
The extracted project is imported and tested directly in Godot. No EXE is built.
