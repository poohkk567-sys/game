# Implementation notes

## Repository and scene structure

The uploaded Godot scenes referenced `res://scenes/`, `res://scripts/` and `res://assets/`, but their dependencies lived in the repository root. Files now live under their actual resource paths. `project.godot` opens `scenes/main.tscn`; that scene instances `scenes/phuzashi.tscn`. The original HTML prototype is preserved under `browser/` and is not the current game's runtime.

- `input_setup.gd`: installs named InputMap actions without overwriting existing remaps.
- `phuzashi.gd`: movement, state priority, attack timing, resource costs, physics queries, and training reset.
- `phuzashi_rig.gd`: original-pixel cutouts, joint hierarchy and 12 authored keyframe timelines.
- `dark_pulse.gd`: finite-lifetime traveling special projectile, one collision per projectile.
- `combat_effects.gd`: guard shield, attack trails, charge effects and the violet dragon.
- `stage_art.gd`: static environment, generated once rather than redrawn every gameplay frame.
- `training_crystal.gd`: an inanimate hurt area, damage/combination counters and automatic target refill.
- `training_ground.gd`: input toggles, pause and the twelve-move showcase.
- `training_hud.gd`: health/MP, state, attack phase, move list and target statistics.

The arena uses a 1280×720 reference canvas. Both the platform art and physical floor start at y=586. Horizontal movement is clamped to the arena; jump input has a 100 ms coyote window and 120 ms buffer. Jumping cannot be repeated in the air. A held crouch lowers the body collision shape and a held guard absorbs the training hit inputs. Actions, hit-stun and knockdown temporarily lock new attacks.

## Mountain drawing fix

The old outline used a fixed base at y=320 while some peaks had ridge vertices below that base (`peak_y + 62`, `peak_y + 80`). For example, the mountain with peak y=288 placed ridge points at y=350 and y=368. The final edge then cut back through the outline, producing an invalid polygon for Godot's triangulator.

`mountain_points()` now produces a ridge ordered from left to right, clamps the peak above its base with enough clearance for every ridge point, and closes along the bottom. Snow and shadow faces are separate simple polygons. Regression tests call Godot's `Geometry2D.triangulate_polygon()` with normal peaks and the former failure cases, including a requested peak below its base.

## Source art preservation and animation

The repository supplies one approved 64×64 frame. The reference image describes the requested moves; it is not treated as a transparent, uniformly spaced sprite atlas.

The approved PNG is moved without modification. Its original face, hair, outfit, colors, skull motif, trousers and shoes are retained. At load time each visible source pixel is assigned exactly once to one of ten rigid pieces: torso, head, two upper arms, two forearms, two thighs and two lower legs including the original shoes. The generated in-memory textures copy their colors directly from the master. They are not painted or saved over the source image.

The rig rotates and translates these pieces at uniform 3× display scale with nearest filtering. Each clip has its own timeline, with anticipation/contact/recovery keys for combat moves. No per-limb scaling or character recoloring is applied. This is a cutout animation implementation; it does not claim to provide newly illustrated, frame-by-frame sprites or unseen surfaces from the single source image.

A convex hull of the opaque pixels of each piece provides a support bound after rotation. Grounded animation poses are shifted vertically until their lowest visible pixel meets the floor. Jump poses retain their airborne offset. This fixes footwear and knockdown art sinking into the platform. Tests sample 21 phases of each grounded clip and recompute its actual transformed support bound.

## Combat and training

| Move | Duration | Active phase | MP | Damage |
| --- | --- | --- | --- | --- |
| Punch | 0.42 s | 34–60% | 0 | 8 |
| Kick | 0.58 s | 40–65% | 0 | 14 |
| Special | 0.90 s | Projectile spawns at 42% | 25 | 24 |
| Ultimate | 1.80 s | 48–80% | 60 | 60 |

Melee and ultimate use physics shape queries against collision layer 4. A per-action set prevents multiple damage applications while a target remains in the active shape. The special spawns one `Area2D`, travels at 620 px/s, and disappears on impact, timeout, boundary exit or training reset. Both facing directions are tested. MP regenerates at 9 units/s. The crystal has no AI or attack behavior and is not a second fighter.

H applies 8 HP of training damage and 0.48 seconds of hit-stun. N applies 18 HP and a 1.4 second fall/get-up sequence. Held guard reduces either to 2 chip damage. These are explicit practice inputs, not opponent attacks. HP remains depleted until R; target HP refills after depletion. Reset also clears action state, jump buffering and in-flight projectiles.

Esc pauses gameplay while retaining input for resuming and drawing the overlay. F2 cycles every state at 2.4 seconds per demonstration, refills resources and releases its synthetic held actions when stopped. Gameplay key input exits demonstration mode. Losing application focus releases held inputs to avoid stuck movement.
