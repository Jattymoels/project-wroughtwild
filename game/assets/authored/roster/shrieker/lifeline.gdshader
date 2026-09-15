shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// ART-06B preserves ART-03's explicit, pause-aware pulse clock and UV channels.
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D scar_texture : filter_linear_mipmap_anisotropic;
uniform vec3 core_colour : source_color = vec3(1.0,0.19,0.025);
uniform vec3 damage_tint = vec3(0.16,0.14,0.12);
uniform float scar_clock = 0.0;
uniform float period_seconds = 4.0;
uniform float peak_emission = 2.8;
uniform float minimum_light = 0.22;
uniform float crest_width = 0.20;
uniform int pulse_mode = 3;
instance uniform float phase_offset = 0.0;

void fragment() {
	vec3 marks = texture(scar_texture,UV).rgb;
	vec3 base = texture(base_texture,UV).rgb;
	vec3 orm = texture(orm_texture,UV).rgb;
	// Keep the original host texture inside the dark damage instead of flat paint.
	ALBEDO = mix(base,base*damage_tint,marks.g);
	ROUGHNESS = mix(orm.g,0.96,marks.g);
	METALLIC = mix(orm.b,0.0,marks.g);
	float wave = 0.0;
	if (pulse_mode == 1) wave = 0.55;
	else if (pulse_mode >= 2) {
		float delay = marks.b*0.8*float(pulse_mode==3);
		float phase = fract(scar_clock/max(period_seconds,0.1)-delay+phase_offset);
		float crest = 1.0-smoothstep(0.0,crest_width,abs(phase-0.5));
		wave = mix(minimum_light,1.0,crest);
	}
	EMISSION = core_colour*marks.r*peak_emission*wave;
}
