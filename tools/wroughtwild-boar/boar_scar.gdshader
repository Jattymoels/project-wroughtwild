shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D scar_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic;
uniform bool use_normal_map = false;
uniform vec3 core_colour : source_color = vec3(1.0, 0.12, 0.012);
uniform vec3 scar_edge : source_color = vec3(0.035, 0.018, 0.012);
uniform float scar_clock = 0.0;
uniform float period_seconds = 4.0;
uniform float peak_emission = 3.2;
uniform float minimum_light = 0.25;
uniform float crest_width = 0.18;
// 0: emission off, 1: steady, 2: breathing, 3: travelling through the authored branches.
uniform int pulse_mode = 3;
instance uniform float phase_offset = 0.0;
// Presentation adapter inputs. They never apply damage or alter actor clocks.
uniform vec4 status_tint : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform vec3 status_emission : source_color = vec3(0.0);

void fragment() {
	vec4 marks = texture(scar_texture, UV);
	vec3 base = texture(base_texture, UV).rgb;
	vec3 orm = texture(orm_texture, UV).rgb;
	ALBEDO = mix(base, scar_edge, marks.g);
	ALBEDO = mix(ALBEDO, status_tint.rgb, status_tint.a);
	ROUGHNESS = mix(orm.g, 0.96, marks.g);
	METALLIC = mix(orm.b, 0.0, marks.g);
	if (use_normal_map) {
		NORMAL_MAP = texture(normal_texture, UV).rgb;
	}
	float wave = 0.0;
	if (pulse_mode == 1) {
		wave = 0.55;
	} else if (pulse_mode >= 2) {
		float path_delay = marks.b * 0.8 * float(pulse_mode == 3);
		float phase = fract(scar_clock / max(period_seconds, 0.1) - path_delay + phase_offset);
		float crest = 1.0 - smoothstep(0.0, crest_width, abs(phase - 0.5));
		wave = mix(minimum_light, 1.0, crest);
	}
	EMISSION = core_colour * marks.r * peak_emission * wave * (1.0 - status_tint.a) + status_emission;
}
