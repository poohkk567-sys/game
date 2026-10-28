shader_type canvas_item;
render_mode unshaded;

uniform vec2 region_origin = vec2(0.0);
uniform vec2 region_extent = vec2(1.0);
uniform vec2 feather = vec2(0.015);
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 local_uv = (UV - region_origin) / region_extent;
	vec2 edge = smoothstep(vec2(0.0), feather, local_uv)
		* smoothstep(vec2(0.0), feather, vec2(1.0) - local_uv);
	COLOR = texture(TEXTURE, UV) * tint;
	COLOR.a *= edge.x * edge.y;
}
