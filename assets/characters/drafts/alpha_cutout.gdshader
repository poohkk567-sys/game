shader_type canvas_item;
// The generated draft contains faint stray alpha beyond the actual silhouettes.
// Keep the source PNG intact and suppress that noise only while rendering.
void fragment() {
	if (COLOR.a < 0.5) {
		discard;
	}
}
