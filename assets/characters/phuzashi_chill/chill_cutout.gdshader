shader_type canvas_item;
// Trim source-image haze before actor modulation, preserving the blink ghost.
void fragment() {
	if (texture(TEXTURE, UV).a < 0.5) {
		discard;
	}
}
