# Demon Bind validation

S+J spends 25 MP once and casts a grounded control skill. A single 16-frame spirit
selects the nearest eligible forward target, travels to it, and applies a 0.7 s
movement lock on arrival. A missed cast still spends MP; the spell itself deals
no damage. Pause freezes duration/visuals and training reset clears both.

The shared `scripts/combat/movement_lock.gd` runs after the owner's movement so
AI that still attempts to move is pinned at the captured position. The fighter
also gates its movement/action APIs and clears buffered attacks while bound.
The crystal freezes its bobbing/shaking and shows the remaining time. A target
must expose `apply_movement_lock(seconds)` and `is_movement_locked()`, join
`bind_targets`, and may supply `get_bind_anchor()` for its visual center.

## Local checks

`tools/check.sh` passed on Godot **4.2.2** and **4.6.3**:

| Suite | Checks per engine | Failures |
| --- | ---: | ---: |
| Training / physics / original artwork / showcase | 88 | 0 |
| Base sprite animations | 75 | 0 |
| Pulse / dragon VFX | 11 | 0 |
| Blink gameplay | 13 | 0 |
| Blink VFX lifecycle | 20 | 0 |
| Air attacks / combo source selection / cast frames | 90 | 0 |
| Distinct combo poses / purple fist lifecycle | 30 | 0 |
| Demon Bind | 55 | 0 |
| Total | **382** | **0** |

The new 55 real-scene checks cover exact mana cost, full duration from arrival,
same-frame and held-S input, single activation when held, no accidental punch or
damage projectile, pause, automatic release, both facings, misses, range/height
gating, nearest-target selection, low MP, grounded/busy restrictions, Blink
invulnerability, refresh/visual replacement, follow-up damage, interruption of
queued fighter actions, reset in flight/hold, target deletion, and scene exit.

A moving CharacterBody2D test actor deliberately ignores its lock in its own AI
and tries to move every physics frame. The shared status still pins it for
0.7 seconds, then allows movement again. This test actor is not added to gameplay.
The existing playable fighter is also directly bound and verified unable to
walk, run, jump, attack or Blink until the status expires.

`tests/record_demon_bind.gd` records actual S+J input, hold, release and subsequent
combo use in both directions, using Godot 4.6.3 OpenGL Compatibility on llvmpipe.
Review media is in `docs/PHUZASHI_Demon_Bind.mp4` and `docs/screenshots/demon_bind/`.
The virtual display's unsupported VSync-setting warning is not a project error.
The normal-speed capture rendered 511 frames at 60 FPS (8.52 seconds), without
script/shader errors. Screenshots show the demon around the crystal, the 0.7 s
countdown, and the updated F1 controls.

The source ZIP is CRC-checked, compared byte-for-byte with the workspace,
extracted, imported and tested directly in Godot. No EXE is built.
