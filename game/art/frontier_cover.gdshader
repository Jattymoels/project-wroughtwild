// Codex experiment: both sides of thin blades receive consistent canopy light.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}
