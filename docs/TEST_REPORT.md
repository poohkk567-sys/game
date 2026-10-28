# Test report — 2026-10-28

## Executed results

The actual Godot project was imported and tested inside the execution environment, using both official Linux binaries:

| Engine | Import | Gameplay integration suite |
| --- | --- | --- |
| Godot 4.2.2 stable (`15073afe3`) | Pass | **105 checks, 0 failures** (88 base + 17 spritesheet trial) |
| Godot 4.6.3 stable (`7d41c59c4`) | Pass | **105 checks, 0 failures** (88 base + 17 spritesheet trial) |

No project parse errors, missing resources, runtime script errors or leaked-object errors were reported in the final checks. Tests operate on the real main scene and Godot's physics server, rather than reproducing controller calculations outside the engine.

Coverage includes:

- Main scene loading, grounding and floor/art alignment.
- Byte-identical master PNG, unique ownership of every visible pixel, and exact reconstruction of its colors.
- Godot triangulation for seven mountain profiles, including former self-intersection cases.
- Walk/run speed, facing and mirroring, both arena boundaries, jump height, rejected double jump and landing.
- Crouch collider reduction, restoration on standing, and crouch/guard attack locks.
- Guard chip damage, hit-stun, knockdown and automatic get-up.
- Attack startup before damage, one hit per active window, punch/kick damage and recovery.
- Special/ultimate MP cost, rejected actions with insufficient MP, traveling projectile collisions and cleanup.
- Actual melee and projectile hits when facing left as well as right.
- Gameplay freeze and resume through the Esc input path.
- Reset clearing action state, resources and in-flight projectiles.
- Focus loss releasing held inputs without resetting manual training progress.
- A distinct authored timeline for every one of the twelve states.
- Rendered-mesh floor support sampled at 21 phases of each grounded clip.
- Rigid face/hair and footwear verified across 21 phases of all twelve clips.
- Actual index-buffer continuity at anatomical seams, original UVs, normalized skin weights, and independent fist/trouser contacts.
- All twelve showcase states reached from a cleared history and held demo input released on exit.

## Visual review in Godot

Rendered with Godot 4.6.3's GL Compatibility renderer on an Xorg dummy display using Mesa llvmpipe. Reviewed the actual viewport output for the training ground, contact kick, active ultimate, knockdown, move list, and a twelve-pose gallery.

The first version's independent cutout sprites left visible gaps at rotating joints, as reported in the guard screenshot. The corrected renderer uses one original-texture mesh with shared anatomical seam vertices and local joint weights. The face/hair and shoes stay rigid. Ground support now uses rendered vertices. The former floor alignment and horizontal fall pose corrections are retained.

**Rendered regression: 216 silhouettes, 0 failures** on Godot 4.6.3. It samples nine phases of all twelve clips, both facing directions, with integer and fractional screen positions. The same test against the original `84cdf1f` renderer reports **23 failures**, so the regression detects the original detached-body defect. This supplements the headless checks, which did not originally detect visible seams.

Saved review images:

- [Joint repair comparison](screenshots/joint_fix_comparison.png)
- [Guard in game](screenshots/guard.png)
- [Training ground](screenshots/training.png)
- [Twelve-pose gallery](screenshots/pose_gallery.png)
- [Ultimate in game](screenshots/ultimate.png)
- [Move list](screenshots/move_list.png)

The [complete showcase video](PHUZASHI_All_Moves.mp4) was also rendered through Godot Movie Maker at 1280×720, 30 FPS, for approximately 29 seconds. This is footage of the implemented game, including all twelve demonstrations.

The display driver reports that changing V-Sync is unsupported in the virtual display. Godot 4.2.2 also reports virtual-display cursor/unused Blender importer warnings. These are environment warnings; no Blender files or custom cursor resources are used by this project.

## Reproduce

```sh
# Import, integration tests and runtime error detection:
tools/check.sh

# Save viewport review PNGs (requires a working display):
mkdir -p work
godot --path . --audio-driver Dummy --fixed-fps 60 \
  --script tests/capture_review.gd

# Record the complete automatic showcase (requires a working display):
godot --path . --audio-driver Dummy --fixed-fps 30 \
  --write-movie work/showcase.avi --script tests/record_showcase.gd
```

For rendered checks, run with a display:

```sh
godot --path . --audio-driver Dummy --fixed-fps 60 --script tests/test_skin_render.gd

# Optional before/after comparison against the initial PR commit:
git show 84cdf1f:scripts/character/phuzashi_rig.gd > work/old_rig.gd
godot --path . --audio-driver Dummy --fixed-fps 60 --script tests/capture_joint_fix.gd
```

CI runs the import and gameplay suite against both engine versions and the rendered regression on Godot 4.6.3 using Xvfb/Mesa. GPU hardware drivers and Windows/macOS packaging were not exercised; the game uses Godot's cross-platform GL Compatibility renderer and has no native extensions.

## Playable spritesheet trial — follow-up

The actual main scene now uses eight illustrated IDLE frames and eight WALK frames by default. Other poses retain the original renderer. Both Godot 4.2.2 and 4.6.3 passed the original 88 checks plus **17 new trial checks**. The import helper is also parse-compatible with 4.2.2.

- Confirmed real AnimatedSprite2D frame advancement from gameplay input, both directions, correct fallback for RUN/attacks and return to illustrated idle.
- Confirmed F4 changes only artwork, reset restores idle, and pause freezes frame playback.
- All sixteen AtlasTextures share one canvas and exact feet baseline; one uniform scale is used.
- **32 rendered frames, 0 failures on each engine**: 16 frames × 2 directions, checking attached silhouettes, integer/fractional placement and floor alignment.
- Existing mesh regression retained: **216 silhouettes, 0 failures** on 4.6.3.
- [Idle screenshot](screenshots/spritesheet_idle.png), [walking screenshot](screenshots/spritesheet_walk.png), and [15-second gameplay comparison video](PHUZASHI_Spritesheet_Trial.mp4) were rendered by Godot.
- The draft has not been promoted to finalized character artwork; only the requested playable idle/walk trial is enabled.

```sh
# Headless trial checks are included in tools/check.sh.
# Actual draft-frame rendering, with a working display:
godot --path . --audio-driver Dummy --fixed-fps 60 --script tests/test_sprite_render.gd

# Record gameplay and F4 comparison:
godot --path . --audio-driver Dummy --fixed-fps 30 \
  --write-movie work/sprite_trial.avi --script tests/record_sprite_trial.gd
```
