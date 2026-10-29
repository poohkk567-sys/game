shader_type canvas_item;
// Alpha mixing preserves the dark mask/robe over bright stage art.
render_mode unshaded;
uniform vec2 region_origin = vec2(0.0);
uniform vec2 region_extent = vec2(1.0);
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec2 p = (UV-region_origin)/region_extent;
	vec2 feather = smoothstep(vec2(0.0),vec2(0.018),p)
		* smoothstep(vec2(0.0),vec2(0.018),vec2(1.0)-p);
	COLOR = texture(TEXTURE,UV)*tint;
	COLOR.a *= feather.x*feather.y;
}
