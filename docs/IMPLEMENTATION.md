# Implementation

## Current animation: twelve complete spritesheet sequences

The default character renderer uses `AnimatedSprite2D` and 96 complete full-body drawings: eight frames each for IDLE, WALK, RUN, JUMP, CROUCH, GUARD, PUNCH, KICK, HIT, FALL, SPECIAL and ULTIMATE. Eighty new frames in five sheets extend the sixteen idle/walk frames selected by the user. New artwork follows that same character model, clothing and shoes. The approved single-frame master remains byte-identical.

`scripts/character/draft_sprite_animation.gd` retains its earlier filename but now presents the full library in `assets/characters/spritesheets/phuzashi_frames.res`. It never deforms these drawings. IDLE/WALK/RUN loop. CROUCH/GUARD enter their poses once and hold their final frame while the key remains pressed. Timed actions select their frames from gameplay progress, with explicit contact thresholds matching damage windows. Jump progress follows vertical velocity; knockdown includes horizontal lying frames and a get-up sequence.

Only one character renderer is visible. F4 switches between the spritesheets and the previous master-based mesh for comparison; this changes no physics, action timers or resource costs. The HUD identifies the active renderer. Effects remain independent nodes and drawings, including the traveling pulse, guard shield and violet dragon.

## Sprite import and source isolation

The source drawings do not form a perfectly uniform atlas: running feet, extended punches and horizontal knockdown poses cross nominal cell boundaries. `tools/import_spritesheets.gd` uses Godot's alpha bitmap contours to identify sixteen complete silhouettes per sheet, groups them by row and sorts by horizontal position. Each is imported whole, rather than cut at an arbitrary grid boundary.

Every frame has a virtual 512×384 canvas and pivot (256,360). Margins align the opaque ground support and the waist. A fixed scale of 52/286 inside the existing 3× character display scale is shared by all states, including crouched and lying poses. It does not rescale individual limbs or normalize away intentional changes of pose.

Two FALL source rectangles overlap a neighboring character. Those two frames use an exact connected-component copy of the source colors, removing only pixels belonging to the neighboring silhouette. The lossless isolated textures are embedded in the resource. All other frames reference the source PNG atlases directly. Faint stray alpha is discarded by the same cutout shader as the idle/walk trial. Source PNGs are left unchanged.

The common canvas is wider than the previous trial canvas so extended kicks and the falling body cannot be clipped by texture margins. `manifest.json` records every source rectangle, anchor and isolated-frame flag. The binary resource is generated with Godot 4.2.2 so it is readable by both the minimum version and newer engines. Rebuilding with a newer binary-resource format can break backwards compatibility; use the documented 4.2.2 build command.

## Game systems

- `input_setup.gd`: named actions without overwriting existing remaps.
- `phuzashi.gd`: movement, state priority, action timing, damage queries and training reset.
- `phuzashi_rig.gd`: renderer selection and the retained F4 master comparison.
- `dark_pulse.gd`: finite-lifetime traveling projectile, one impact per projectile.
- `combat_effects.gd`: guard, attack trails, charge effects and violet dragon.
- `stage_art.gd`: static environment drawn once.
- `training_crystal.gd`: inanimate target, damage/combo counters and automatic refill.
- `training_ground.gd`: pause, input toggles and the twelve-move showcase.
- `training_hud.gd`: health/MP, state, renderer, attack phase and move list.

The arena is 1280×720. Platform artwork and its physics floor start at y=586. Movement is clamped to the arena, with 100 ms coyote time and a 120 ms jump buffer. Crouch lowers the collider. Held guard absorbs the training hit inputs. Actions, hit-stun and knockdown temporarily prevent new attacks.

| Move | Duration | Active phase | MP | Damage |
| --- | --- | --- | --- | --- |
| Punch | 0.42 s | 34–60% | 0 | 8 |
| Kick | 0.58 s | 40–65% | 0 | 14 |
| Special | 0.90 s | Projectile at 42% | 25 | 24 |
| Ultimate | 1.80 s | 48–80% | 60 | 60 |

Melee and ultimate query collision layer 4, with a per-action set preventing repeated hits in one active window. The pulse travels at 620 px/s and disappears on impact, timeout, boundary exit or reset. MP regenerates at 9/s. H applies 8 HP and 0.48 s hit-stun; N applies 18 HP and a 1.4 s fall/get-up sequence. Guard reduces either to 2 chip damage. There is no second fighter or opponent AI.

Esc pauses gameplay. F2 demonstrates each state for 2.4 seconds, resetting resources between demonstrations and releasing synthetic inputs when stopped. Gameplay keys exit demonstration mode. Focus loss releases held inputs without resetting manual progress.

## Original project repairs

The uploaded scenes referenced scenes/, scripts/ and assets/ while their dependencies were in the repository root. Files were moved to valid resource paths, and the original browser prototype was preserved separately.

The original mountain outline closed at y=320 while intermediate ridge vertices could lie below that base, causing self-intersection. The current ridge is ordered left-to-right and clamped above the base, with separate simple snow/shadow polygons. Tests call Godot's triangulator for normal and former failure cases.

The earlier independent cutouts were replaced with a continuous master-texture mesh to repair joint seams. That implementation is retained only for F4 comparison. Normal play now uses whole illustrated frames for every state, addressing the user's preference for spritesheets over deformation of one frame.
