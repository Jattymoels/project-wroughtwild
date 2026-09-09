shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D scar_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic;
uniform vec3 core_colour : source_color = vec3(1.0, 0.24, 0.035);
uniform float cosmetic_clock = 0.0;
uniform float work_clock = 0.0;
uniform float period_seconds = 4.0;
uniform float minimum_light = 0.25;
uniform float peak_emission = 3.4;
uniform float native_gain = 0.0;
// 0=off, 1=stored/paused steady, 2=ready-source ambient, 3=actual firing.
uniform int state_mode = 0;
uniform bool light_off = false;
void fragment() {
	vec3 marks = texture(scar_texture, UV).rgb;
	vec3 orm = texture(orm_texture, UV).rgb;
	ALBEDO = mix(texture(base_texture, UV).rgb, vec3(0.009,0.004,0.002), marks.g);
	ROUGHNESS = mix(orm.g, 0.97, marks.g);
	METALLIC = mix(orm.b, 0.0, marks.g);
	NORMAL_MAP = texture(normal_texture, UV).rgb;
	NORMAL_MAP_DEPTH = 0.7;
	float amplitude = 0.0;
	if (state_mode == 1) amplitude = 0.55;
	if (state_mode == 2 || state_mode == 3) {
		float clock = state_mode == 3 ? work_clock : cosmetic_clock;
		float phase = fract(clock / period_seconds - marks.b * 0.8);
		float crest = 1.0 - smoothstep(0.0, 0.18, abs(phase - 0.5));
		amplitude = mix(minimum_light, 1.0, crest);
	}
	EMISSION = light_off ? vec3(0.0) : core_colour * marks.r * peak_emission * native_gain * amplitude;
}
