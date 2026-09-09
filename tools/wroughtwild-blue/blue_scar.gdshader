shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D scar_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic;
uniform vec3 core_colour : source_color = vec3(0.24,0.53,1.0);
uniform float cosmetic_clock = 0.0;
uniform float request_fraction = 0.0;
uniform float release_fraction = -1.0;
uniform float period_seconds = 4.5;
uniform float minimum_light = 0.25;
uniform float peak_emission = 4.0;
uniform float native_gain = 0.0;
// 0=off, 1=recovered, 2=natural life, 3=native pending, 4=native release.
uniform int state_mode = 0;
uniform bool light_off = false;
void fragment() {
	vec3 marks=texture(scar_texture,UV).rgb;
	vec3 orm=texture(orm_texture,UV).rgb;
	ALBEDO=mix(texture(base_texture,UV).rgb,vec3(0.005,0.008,0.014),marks.g);
	ROUGHNESS=mix(orm.g,0.97,marks.g);
	METALLIC=mix(orm.b,0.0,marks.g);
	NORMAL_MAP=texture(normal_texture,UV).rgb;
	NORMAL_MAP_DEPTH=0.7;
	float amplitude=0.0;
	if(state_mode==1) amplitude=0.4;
	if(state_mode==2) {
		float phase=fract(cosmetic_clock/period_seconds);
		// Linger in a local fracture, then shift smoothly to the next section.
		float location=mix(0.18,0.83,smoothstep(0.55,0.85,phase));
		float crest=1.0-smoothstep(0.05,0.26,abs(marks.b-location));
		amplitude=minimum_light+(1.0-minimum_light)*crest*(1.0-smoothstep(0.90,1.0,phase));
	}
	if(state_mode==3) {
		// Only native elapsed time moves the held crest. Paused stays exactly still.
		float location=mix(0.12,0.88,request_fraction);
		amplitude=0.25+0.75*(1.0-smoothstep(0.035,0.21,abs(marks.b-location)));
	}
	if(state_mode==4 && release_fraction>=0.0 && release_fraction<=1.0) {
		float location=mix(0.75,1.3,release_fraction);
		amplitude=(1.0-smoothstep(0.05,0.30,abs(marks.b-location)))*(1.0-smoothstep(0.65,1.0,release_fraction));
	}
	EMISSION=light_off?vec3(0.0):core_colour*marks.r*peak_emission*native_gain*amplitude;
}
