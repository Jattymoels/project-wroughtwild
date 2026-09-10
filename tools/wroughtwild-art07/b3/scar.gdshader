shader_type spatial;
render_mode cull_back;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_map : filter_linear_mipmap_anisotropic;
uniform float clock_seconds=0.0;
uniform bool light_enabled=true;
uniform float period=4.0;
uniform float peak=2.2;
void fragment(){
 vec3 base=texture(albedo_map,UV).rgb;
 vec3 orm=texture(orm_map,UV).rgb;
 float wound=COLOR.r;
 ALBEDO=mix(base,base*0.22,smoothstep(0.08,0.55,wound));
 ROUGHNESS=orm.g;METALLIC=orm.b;AO=orm.r;
 float flow=0.28+0.72*pow(0.5+0.5*sin(clock_seconds*6.283185/period-COLOR.b*5.0),3.0);
 EMISSION=vec3(1.0,0.17,0.008)*smoothstep(0.55,0.92,wound)*flow*peak*float(light_enabled);
}
