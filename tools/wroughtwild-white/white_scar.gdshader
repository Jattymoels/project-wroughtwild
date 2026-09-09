shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D scar_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic;
uniform vec3 core_colour : source_color = vec3(1.0,0.96,0.79);
uniform float cosmetic_clock = 0.0;
uniform float request_fraction = -1.0;
uniform float period_seconds = 4.0;
uniform float minimum_light = 0.25;
uniform float peak_emission = 3.4;
uniform float native_gain = 0.0;
// 0=off, 1=quiet recovered material, 2=ready natural source, 3=actual request.
uniform int state_mode = 0;
uniform bool light_off = false;
void fragment() {
	vec3 marks=texture(scar_texture,UV).rgb;
	vec3 orm=texture(orm_texture,UV).rgb;
	ALBEDO=mix(texture(base_texture,UV).rgb,vec3(0.008,0.009,0.008),marks.g);
	ROUGHNESS=mix(orm.g,0.97,marks.g);
	METALLIC=mix(orm.b,0.0,marks.g);
	NORMAL_MAP=texture(normal_texture,UV).rgb;
	NORMAL_MAP_DEPTH=0.7;
	float amplitude=0.0;
	if(state_mode==1) amplitude=0.4;
	if(state_mode==2) {
		float phase=fract(cosmetic_clock/period_seconds);
		float swell=smoothstep(0.0,0.65,phase)*(1.0-smoothstep(0.65,1.0,phase));
		float passage=1.0-smoothstep(0.0,0.13,abs(phase-(0.55+marks.b*0.35)));
		amplitude=mix(minimum_light,0.55,swell)+0.45*passage;
	}
	if(state_mode==3 && request_fraction>=0.0 && request_fraction<=1.0) {
		float position=request_fraction*1.4-0.2;
		amplitude=(1.0-smoothstep(0.0,0.20,abs(marks.b-position)))*smoothstep(0.0,0.08,request_fraction)*(1.0-smoothstep(0.85,1.0,request_fraction));
	}
	EMISSION=light_off?vec3(0.0):core_colour*marks.r*peak_emission*native_gain*amplitude;
}
