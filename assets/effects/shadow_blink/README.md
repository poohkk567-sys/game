# Approved Shadow Blink VFX

`shadow_blink_approved.png` is the exact transparent 1254 × 1254 RGBA preview
selected by the user, arranged as 16 illustrated effects. SHA-256:
`6040de76cb8a691cb8d3b3fa0a8fab0b38206c23021ae8a49c504e4de866dfa7`.

The runtime uses authored AtlasTexture bounds and pivots because the illustrated
spacing is irregular. See `scripts/effects/shadow_blink_vfx.gd`. The source PNG
is unchanged. `atlas_edges.gdshader` feathers five source pixels at crop edges
to suppress neighbouring particles; the main effect preserves the source colors.

Departure is world-anchored, travel follows the existing movement curve, and
arrival uses the clamped destination. Three ghosts reuse complete approved
character frames. Every node is pausable, resettable and removed after 0.72 s.
Gameplay movement remains 0.4 s and invulnerability is unchanged.
