shader_type spatial;
render_mode diffuse_burley, specular_disabled, cull_disabled;

// A far-only view of the generated heightfield. Exact visited chunks replace
// it through a tiny mask; it never supplies physics or invented terrain.
uniform sampler2D detail_mask : filter_nearest, repeat_disable;
uniform vec2 world_size = vec2(512.0);
varying vec2 world_uv;

void vertex() {
	world_uv = VERTEX.xz / world_size;
}

void fragment() {
	if (texture(detail_mask, world_uv).r > 0.5) discard;
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
}
