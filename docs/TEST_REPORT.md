# Test report — 2026-10-28

## Executed results

The actual Godot project was imported and tested inside the execution environment, using both official Linux binaries:

| Engine | Import | Gameplay integration suite |
| --- | --- | --- |
| Godot 4.2.2 stable (`15073afe3`) | Pass | **70 checks, 0 failures** |
| Godot 4.6.3 stable (`7d41c59c4`) | Pass | **70 checks, 0 failures** |

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
- Floor support sampled at 21 phases of each grounded clip.
- All twelve showcase states reached from a cleared history and held demo input released on exit.

## Visual review in Godot

Rendered with Godot 4.6.3's GL Compatibility renderer on an Xorg dummy display using Mesa llvmpipe. Reviewed the actual viewport output for the training ground, contact kick, active ultimate, knockdown, move list, and a twelve-pose gallery.

The review found footwear and knockdown poses crossing the platform. The rig now plants transformed opaque-pixel bounds on the floor, with an integration regression for every grounded timeline. The fall pose was also adjusted to lie horizontally before getting up.

Saved review images:

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

CI runs the import and gameplay suite against both engine versions on pushes and pull requests. GPU hardware drivers and Windows/macOS packaging were not exercised; the game uses Godot's cross-platform GL Compatibility renderer and has no native extensions.
