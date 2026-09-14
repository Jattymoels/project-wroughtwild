shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D scar_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic;
uniform vec3 core_colour : source_color = vec3(0.43,0.90,0.39);
uniform float cosmetic_clock=0.0;
uniform float passage_fraction=-1.0;
uniform float period_seconds=4.2;
uniform float minimum_light=0.25;
uniform float peak_emission=3.7;
uniform float native_gain=0.0;
uniform bool first_sent=false;
uniform bool second_sent=false;
// The made Y has three actual recovered solids with independent atlases.
// Their local height maps to stem / first / second progression; UV scars stay attached.
uniform float branch_override=-1.0;
uniform float height_local=1.0;
uniform float flow_start=0.0;
uniform float flow_span=1.0;
varying float local_progress;
// 0=off, 1=recovered, 2=natural source, 3=actual native passage.
uniform int state_mode=0;
uniform bool light_off=false;
void vertex(){local_progress=clamp(VERTEX.y/height_local,0.0,1.0);}
void fragment(){
	vec4 marks=texture(scar_texture,UV);
	vec3 orm=texture(orm_texture,UV).rgb;
	ALBEDO=mix(texture(base_texture,UV).rgb,vec3(0.007,0.010,0.004),marks.g);
	ROUGHNESS=mix(orm.g,0.96,marks.g);METALLIC=mix(orm.b,0.0,marks.g);
	NORMAL_MAP=texture(normal_texture,UV).rgb;NORMAL_MAP_DEPTH=0.7;
	float flow=branch_override<0.0?marks.b:flow_start+local_progress*flow_span;
	float branch=branch_override<0.0?marks.a:branch_override;
	float amplitude=0.0;
	if(state_mode==1)amplitude=0.4;
	if(state_mode==2){
		float phase=fract(cosmetic_clock/period_seconds)*1.25-0.1;
		float crest=1.0-smoothstep(0.02,0.18,abs(flow-phase));
		amplitude=minimum_light+(1.0-minimum_light)*crest*(1.0-0.28*step(0.2,branch));
	}
	if(state_mode==3 && passage_fraction>=0.0 && passage_fraction<=1.0){
		bool enabled=branch<0.2 || (branch<0.75?first_sent:second_sent);
		float crest=1.0-smoothstep(0.02,0.20,abs(flow-(passage_fraction*1.25-0.05)));
		amplitude=enabled?crest*(1.0-0.25*step(0.2,branch)):0.0;
	}
	EMISSION=light_off?vec3(0.0):core_colour*marks.r*peak_emission*native_gain*amplitude;
}
