# Test report — 2026-10-28

## Current result

| Engine | Import and gameplay | Actual spritesheet rendering |
| --- | --- | --- |
| Godot 4.2.2 stable (`15073afe3`) | **163 checks, 0 failures** | **192 frames, 0 failures** |
| Godot 4.6.3 stable (`7d41c59c4`) | **163 checks, 0 failures** | **192 frames, 0 failures** |

Gameplay checks comprise 88 existing physics/source-art checks and 75 spritesheet checks. They run inside Godot against the real main scene and physics server. The final resource was generated with the oldest supported engine and loaded successfully on both versions.

## Coverage

- Main scene, grounding, exact platform/collider alignment and both arena bounds.
- Walk/run speed, direction, mirroring, jump height, rejected double-jump and landing.
- Crouch collider reduction, guard damage reduction and action locks.
- Startup/active/recovery timing, one hit per attack, damage and MP costs.
- Traveling pulse impacts/cleanup in both directions; ultimate reach and damage.
- Hit-stun, knockdown/get-up, reset, pause, focus loss and twelve-state showcase.
- Original master SHA-256 and pixel ownership/reconstruction for the F4 comparison.
- Eight illustrated frames and valid texture margins for all twelve states.
- Correct loop/hold modes; held crouch/guard stay at frame 7 rather than returning to standing.
- Actual input selects illustrated walk/run/punch and returns to idle after recovery.
- Contact drawings match active attack windows; HIT/FALL/JUMP frames follow gameplay progress.
- F4 changes only art, and pause freezes normal AnimatedSprite2D playback.

## Rendered review

Each engine rendered all 96 illustrated frames in both directions (192 images), including fractional horizontal positions. Checks verify an attached full-body silhouette, the correct renderer, and visible feet/support at the floor. GL Compatibility was used with Mesa llvmpipe on a virtual X display.

The new tests found neighboring-character fragments in FALL frames 0 and 1. Their source rectangles overlap despite representing separate silhouettes. The importer now isolates those two connected components without repainting their colors. All 192 rendered frames pass after that repair.

Reviewed in-game captures and the complete twelve-pose gallery:

- [Gallery: 96 frames / 12 moves](screenshots/pose_gallery.png)
- [Training ground](screenshots/training.png)
- [Guard](screenshots/guard.png)
- [Kick](screenshots/kick.png)
- [Knockdown](screenshots/fall.png)
- [Ultimate](screenshots/ultimate.png)
- [Complete gameplay showcase video](PHUZASHI_All_Moves.mp4)

The showcase video is rendered by Godot Movie Maker at 1280×720, 30 FPS, for about 29 seconds. It demonstrates every spritesheet state and the separate combat effects. The prior idle/walk comparison video remains as historical review material.

The virtual display warns that V-Sync cannot be changed. This is an environment warning. No final project parse errors, missing resources or runtime script errors are accepted by the check runner. Hardware GPU drivers and native Windows/macOS packaging have not been exercised.

## Reproduce

```sh
# 88 gameplay/source checks + 75 spritesheet checks:
tools/check.sh

# All 96 frames in both directions (working display required):
godot --path . --audio-driver Dummy --fixed-fps 60 --script tests/test_sprite_render.gd

# Retained master-mesh comparison regression (216 poses):
godot --path . --audio-driver Dummy --fixed-fps 60 --script tests/test_skin_render.gd

# Capture viewport images and the new gallery:
godot --path . --audio-driver Dummy --fixed-fps 60 --script tests/capture_review.gd

# Record the full showcase:
godot --path . --audio-driver Dummy --fixed-fps 30 \
  --write-movie work/full_sprites_showcase.avi --script tests/record_showcase.gd
```

CI runs the gameplay suites on both engine versions and the sprite/legacy-mesh rendered regressions on 4.6.3 through Xvfb/Mesa.

To regenerate the frame bundle, import sources and run `tools/import_spritesheets.gd` using **Godot 4.2.2**. The compressed binary resource must be saved by the minimum supported version to preserve backwards compatibility.

## Portable download packages

A Windows x86-64 release executable was exported with Godot 4.6.3 and the matching official template. It embeds the game PCK, so its ZIP requires no separate PCK or Godot installation. The PE architecture, embedded pack header/footer, archive CRCs and SHA-256 digests were checked.

The matching Linux release export using the same project data passed a headless startup and an actual GL Compatibility viewport recording. This export test initially found that selecting only the main scene omitted script preloads; the packaging preset now includes all game resources from an isolated staging project. The source ZIP was separately extracted and passed all 163 checks with Godot 4.2.2.

The Windows executable has not been run on native Windows in this environment. This limitation is recorded in the build manifest. See docs/downloads/README.md for reproduction and download links.
