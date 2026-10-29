# Accepted pixel-art side guardians

Each PNG contains eight complete right-facing aura drawings in a four-by-two layout. The anime trial is not a runtime asset.

`tools/import_side_guardians.gd` locates low-alpha gutters, aligns the eye/chest highlight across frames and writes the shared `side_guardians_frames.res` using **Godot4.2.2**. It retains the source pixels and never cuts a fighter into moving parts. Atlas edges are feathered in `spectral_aura.gdshader`; alpha mixing preserves masks, eyes and robe detail on bright stage art.

`side_guardian_art.gd` positions the same pixel bank for live buffs, the Fino ride and empowered Demon Bind. Actors, skill timings, costs and statuses remain owned by their existing gameplay components. Each sprite owns an independent shader material for its atlas coordinates.
