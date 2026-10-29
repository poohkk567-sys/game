# Demon Bind spirit

`demon_bind.png` is a transparent 4×4 VFX sheet, 16 frames. It depicts a temporary
summoned spirit rather than an additional fighter. SHA-256:
`456855a4b9fee5abb75668c9491be0ad7cae05a61f8e428be91f6bfeb645ebf8`.

Frames 0–3 summon, 4–7 travel, 8–11 loop the grip, 12–15 dissolve. Atlas regions
are rounded to the exact pixel boundaries and rendered with edge feathering;
the source PNG is unchanged. The demon is drawn behind its target so the target
remains visible within its claws and chains.

`scripts/effects/demon_bind.gd` applies a 0.7-second movement lock only on arrival.
The independent status component owns the duration and position pinning; removing
a cosmetic spirit cannot accidentally extend or remove another cast's status.
Refreshes retire the previous holding spirit instead of stacking identical holds.
