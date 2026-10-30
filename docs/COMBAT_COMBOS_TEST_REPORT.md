# Aerial normals and three-hit chains: validation

## Behavior

- Ground J/J/J chains PUNCH → PUNCH_2 → PUNCH_3 for 8/10/16 damage.
- Ground K/K/K chains KICK → KICK_2 → KICK_3 for 14/16/22 damage.
- Separate presses buffer up to the remaining two inputs; holding performs one
  attack. Chains link in recovery at 72% and allow 0.22 s after recovery.
- Space+J/K on the same frame, or J/K while airborne, starts AIR_PUNCH/AIR_KICK
  for 9/15 damage. Gravity and horizontal air control remain active. Landing
  immediately cancels the air attack; air normals do not unlock airborne skills.
- Each stage queries a real attack shape and hits each target only once. A new
  stage resets the once-per-target record. Damage works in both directions.
- Hit-stun, reset, jump and Blink clear ground-chain inputs. Pause freezes them.
- All six added animation clips reuse intact approved punch/kick frames, with
  contact frames timed to their hit windows. Original character assets are unchanged.
- The HUD, controls and 17-item F2 showcase include the new moves and chains.

## Local verification

`tools/check.sh` passed on Godot **4.2.2** and **4.6.3**:

| Suite | Checks per engine | Failures |
| --- | ---: | ---: |
| Training / physics / showcase / original artwork | 88 | 0 |
| Illustrated character animations | 75 | 0 |
| Pulse / dragon VFX | 11 | 0 |
| Shadow Blink gameplay | 13 | 0 |
| Illustrated Blink lifecycle | 20 | 0 |
| Air attacks / three-hit combos | 87 | 0 |
| Total | **294** | **0** |

The new integration suite uses actual input actions, the real scene, gravity
and collision queries. It covers both facings, exact three-hit damage totals,
one/two/held/four taps, early buffering, late continuation, timeout, mixed inputs,
interruption, reset, pause/resume, same-frame jump+attack, air steering, landing
cancellation and the transition back to grounded combat.

Actual rendered gameplay is recorded by `tests/record_combat_combos.gd` on an
OpenGL Compatibility virtual display, with normal game speed. The capture shows
both air attacks and both complete ground chains in both directions. See
`docs/PHUZASHI_Air_Combos.mp4` and `docs/screenshots/combat_combos/`.
The Godot 4.6.3 capture rendered 975 frames at 60 FPS (16.25 seconds) without
project script/shader errors. The dummy display reports an unsupported VSync
warning. Extended kick drawings are visible throughout the new kick hit windows.

The downloadable source ZIP includes the updated project, opening instructions,
tests and gameplay preview. It excludes editor caches, prior downloads and EXEs.
Packaging verifies ZIP CRCs and compares every file with the workspace. The
extracted source project is imported and runs the 87 new combat checks in Godot.
