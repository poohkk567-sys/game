# Distinct combo drawings

Four new 4×2 transparent sheets, eight complete character drawings each:
PUNCH_2 (twisting hook), PUNCH_3 (rising uppercut), KICK_2 (spinning kick),
KICK_3 (overhead axe kick). The original approved master and 96 base drawings
are unchanged. The new poses use those images as character references.

`combo_frames.res` contains 32 AtlasTextures on a 1024×1024 virtual canvas,
pivot (512,960). Each clip uses a single uniform scale measured from its guard
poses; each complete frame is anchored to its lowest supporting-foot pixels.
No limbs are cut apart or resized individually, and the source PNGs are unchanged.
`manifest.json` records every source region, foot anchor and clip scale.

Rebuild with Godot 4.2.2 to retain compatibility with Godot 4.2.2+:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tools/import_combo_poses.gd
```

The runtime selects these drawings only for their matching ground combo stages.
PUNCH_3 hand markers in `draft_sprite_animation.gd` locate its powered fist;
`purple_fist.gd` adds the existing violet energy atlas and lightning as a separate
layer. Target impacts are cosmetic and cannot apply damage a second time.
