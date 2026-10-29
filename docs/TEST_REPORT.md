# Test report — 2026-10-29

## Red Cap ultimate transformation

| Engine | Import/gameplay | Transformation + awakened rendering |
| --- | --- | --- |
| Godot 4.2.2 | **614 checks, 0 failures** | **304 samples, 0 failures** |
| Godot 4.6.3 | **614 checks, 0 failures** | **304 samples, 0 failures** |

The current total is 550 regression checks (including updated Red Cap expectations for its newly assigned ultimate) plus 64 transformation checks. The latter exercise the actual school scene and the solo-training scene.

Coverage includes numpad5/semicolon input, full100-MP gating with no partial charges, ready/ground/guard/attack/status restrictions, exactly one charge per held input, cap/sauce/shirt chronology, frozen movement and input buffering, pause, delayed mana regeneration, zero offensive damage, complete body swap, all112 awakened drawings, persistent form through normal combos/air attacks/HIT/BOUND/KO, repeat rejection, interruption without refunds, round/reset cancellation and restore, solo I, profile switching, and preservation of PHUZASHI's original60-MP dragon.

Rendering covers16 transformation frames in both directions, including held cap/bottle/shirt props, plus the awakened bank's112 normal drawings and24 alias frames mirrored: **304 samples**. Checks verify a complete body silhouette, source isolation, floor pivot and viewport bounds.

The transition is3.2seconds, costs100MP immediately and can be interrupted by an opponent hit or movement lock. Completion persists until round/reset; normals retain original damage and input rules. Neither form borrows PHUZASHI's special powers. Native4.6 gameplay footage shows both directions and post-transform combat.

Both resources were saved using Godot4.2.2. The importer retains generated PNGs and groups each whole transformation body with its held props. Existing PHUZASHI/effect art is unchanged.

## Earlier school local-versus result

| Engine | Import/gameplay | New PHUZASHI rendered samples |
| --- | --- | --- |
| Godot 4.2.2 stable | **550 checks, 0 failures** | **344, 0 failures** |
| Godot 4.6.3 stable | **550 checks, 0 failures** | **344, 0 failures** |

Gameplay total: Training88 + SpriteTrial75 + VFX11 + Blink13 + BlinkVFX20 + Combos90 + ComboPoses30 + DemonBind55 + RedCap77 + LocalVersus91 = **550**. Existing suites remain unchanged; the new suite loads the real school scene and physics server.

The 91 versus checks cover independent simultaneous movement, jump/crouch/guard and hurtboxes; both players attacking both directions without self-damage; exact 34/52-damage three-hit combos and 9/15-damage aerial attacks; guarded chip damage; unchanged 24-damage pulse and 60-damage dragon/MP costs; a real second player pinned by Demon Bind and released after 0.7s; Blink immunity; purple-fist tracking on the new uppercut; and complete body frames/contact timing.

They also cover ready countdown, timeout winner, first-to-two scoring, simultaneous KO draw, no duplicated score, persistent KO pose, restart, pause/focus loss, cleanup, and F6 travel to new-model solo training and back without leaked fighters.

The new body has 16 source clips x 8 = **128 unique complete drawings**. Rendering checks all source frames, AIR_PUNCH/AIR_KICK/BOUND/DEMON_BIND aliases and twelve Blink poses, mirrored: **344 samples per engine**. Source silhouettes are checked at full opacity because Blink deliberately fades during runtime; the existing Blink suites still check live timing/effects.

Godot 4.6.3 additionally passes the retained mesh216 + original sprites192 + original combo64 + RedCap224 = 696 samples. Including the new344, the current actual-render regression is **1,040 passing samples**.

Actual GL Compatibility footage on Mesa llvmpipe captures both human input channels, school sign Thai/English, new fair-skin model, normal combos, aerial attack, Demon Bind, Dark Pulse, purple uppercut, dragon, Blink, controls and round result. Unsupported VSync is the only expected virtual-display warning. New SpriteFrames were saved with Godot 4.2.2.

The importer preserves generated PNGs. It orders rows by their floor baselines so crouching/seated figures remain in the right order, and isolates complete connected silhouettes where rectangular source bounds overlap. Original PHUZASHI master and existing effect PNGs remain byte-identical.

## Earlier Red Cap / training results

| Engine | Import and gameplay | Red Cap rendered frames |
| --- | --- | --- |
| Godot 4.2.2 stable (`15073afe3`) | **459 checks, 0 failures** | **224 frames, 0 failures** |
| Godot 4.6.3 stable (`7d41c59c4`) | **459 checks, 0 failures** | **224 frames, 0 failures** |

Current gameplay coverage is Training 88 + Sprite Trial 75 + VFX 11 + Blink 13 + Blink VFX 20 + Combat Combos 90 + Combo Poses 30 + Demon Bind 55 + Red Cap 77 = **459 checks per engine**. The tests load the real main scene and exercise actual physics and combat queries. The original PHUZASHI suites remain unchanged.

The new Red Cap bank contains fourteen clips of eight complete drawings (112 total), including distinct hook, uppercut, spinning kick and axe kick. Aerial attacks reuse this character's own normal artwork. All drawings follow the approved hairless red-cap reference. The PHUZASHI master retains its original SHA-256, and original PNGs/resources remain byte-identical.

Red Cap checks cover real Tab switching, normal locomotion and facing, crouch/guard holding, HIT/FALL recovery, three-stage combos and aerial damage in both directions, MP preservation, demo coverage, pause/reset, switching during attacks, and removal of old effects. They verify that Red Cap has no PHUZASHI skill animations or powered-fist effects, and switching back restores Dark Pulse.

Godot 4.2 headless does not forward parsed keyboard events to the Viewport input handler. The headless key helper sends matching key events to the stage input handler; windowed tests use `Input.parse_input_event`. Native Godot 4.2 Tab dispatch was also checked successfully.

Native GL Compatibility rendering also passed the retained PHUZASHI mesh (216 silhouettes), original sprite bank (192 frames), and distinct combo bank (64 frames) on Godot 4.6.3. Alongside the new 224 Red Cap frames, the current render regression covers **696 samples**, all passing. Godot 4.2.2 independently rendered all 224 Red Cap samples successfully. The only renderer warning was unsupported VSync on the virtual display.

The new binary SpriteFrames resource was saved with **Godot 4.2.2** and loaded on both versions.

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
