# Shadow Blink illustrated VFX validation

## Implemented

- The approved transparent PNG is byte-identical to the preview (SHA-256
  `6040de76cb8a691cb8d3b3fa0a8fab0b38206c23021ae8a49c504e4de866dfa7`).
- Sixteen authored source regions play as anchored departure, travelling energy,
  and anchored arrival/recovery; three full-body afterimages reuse existing art.
- The visual tail lasts 0.72 s. The existing move remains 0.4 s / 130 px / 15 MP,
  with the same cooldown and invulnerability window.
- Reset and stage exit remove the effect; pause stops its animation/lifetime.
- No character art, movement sprites or Windows executable was changed.

## Local checks

`bash tools/check.sh` passed on Godot **4.6.3** and **4.2.2**:

| Suite | Checks | Failures |
| --- | ---: | ---: |
| Training / physics / original sprite integrity | 88 | 0 |
| Illustrated character frames | 75 | 0 |
| Dark Pulse / dragon VFX | 11 | 0 |
| Shadow Blink gameplay | 13 | 0 |
| Illustrated Blink lifecycle / pause / reset / boundary / mirroring | 20 | 0 |
| Total per engine | **207** | **0** |

The real game was rendered using Godot 4.6.3, OpenGL Compatibility, Mesa llvmpipe
on an Xorg dummy display. Both directions were recorded as 289 rendered frames
at 60 FPS, with `Engine.time_scale = 0.4` to make the art readable in the video.
No script, shader or project runtime errors were reported. The virtual display
reports an unsupported VSync-setting warning.

The same left/right visual capture also completed on Godot 4.2.2 with the actual
OpenGL shader, without script/shader errors. The packaged ZIP was extracted,
imported in Godot 4.6.3, and its 20 Blink VFX checks passed from the extracted
project. All packaged source files were compared byte-for-byte with the workspace.

Screenshots: `docs/screenshots/shadow_blink/`. Video:
`docs/PHUZASHI_Shadow_Blink_FX.mp4`. The full sequence is reproducible with
`tests/record_blink_vfx.gd`; normal gameplay speed is unchanged.

## Download

`docs/downloads/PHUZASHI_Shadow_Blink_FX_Godot.zip` contains the source project,
assets, scenes, scripts, tests, tools and Thai opening instructions. It excludes
editor caches, previous downloads and executable builds. Open with Godot 4.2.2+
and press F5; double tap A or D for Blink.
