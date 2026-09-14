shader_type spatial;
render_mode cull_back;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float work_level = 0.0;
uniform bool emission_off = false;
void fragment() {
	vec3 bark = texture(albedo_tex, UV).rgb;
	ALBEDO = mix(bark, vec3(0.018,0.012,0.006), COLOR.r);
	ALBEDO = mix(ALBEDO, vec3(0.07,0.11,0.05), COLOR.g);
	ROUGHNESS = mix(0.87,0.95,COLOR.r);
	EMISSION = emission_off ? vec3(0.0) : vec3(0.18,0.26,0.12) * COLOR.g * (0.08+work_level*0.4);
}
