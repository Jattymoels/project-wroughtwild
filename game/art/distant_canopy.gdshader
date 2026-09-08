shader_type spatial;
render_mode cull_disabled;
uniform sampler2D detail_mask : filter_nearest, repeat_disable;
uniform vec2 world_size;
varying float leaf_weight;
void vertex() {
	leaf_weight = smoothstep(3.0,4.8,VERTEX.y);
	vec3 anchor = MODEL_MATRIX[3].xyz;
	if (texture(detail_mask,anchor.xz/world_size).r < 0.5) VERTEX.y += INSTANCE_CUSTOM.r;
}
void fragment() {
	ALBEDO = COLOR.rgb;
	if (!FRONT_FACING) NORMAL = -NORMAL;
	ROUGHNESS = 0.94;
	EMISSION = COLOR.rgb * leaf_weight * 0.20;
}
