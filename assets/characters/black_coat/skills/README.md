# BLACK COAT skill body drawings

`rise_crush.png` preserves the original transparent image generated with image_gen from BLACK COAT's approved design reference, copied from `/workspace/generated_images/exec-290ef16d-f68d-4922-bf03-3c257d53f422.png`.

Four columns/four rows: first eight drawings are RISE, last eight are CRUSH. Same black overshirt, brown tee, black trousers, gray-soled sneakers, rounded black fringe and earring. There are no baked-in power effects. Runtime overlays the separate scarlet atlas and hides the ordinary body during these two casts.

`tools/import_black_skills.gd` uses transparent gutters, connected-silhouette atlas bounds and a foot centroid to create aligned AtlasTextures in `black_cast_frames.res`, saved by Godot 4.2.2. The height reference is each animation's opening guard frame, preserving body scale when the uppercut arm extends overhead. The wider row-gutter search handles unequal row spacing; connected-body bounds exclude neighbouring shoe fragments. Original PNG is unchanged. Other attacks use BLACK's own existing punch/run/guard frames.
