shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_map : filter_linear_mipmap_anisotropic;
uniform vec3 host_tint=vec3(1.0);
uniform vec3 mineral_colour=vec3(.5);
uniform float mineral_roughness=.8;
uniform float mineral_metallic=.1;
uniform vec3 state_emission=vec3(0.0);
uniform vec3 tint=vec3(1.0);
uniform float clock_seconds=0.0;
uniform float period=3.5;
uniform bool heat_active=false;
uniform bool light_enabled=true;
uniform bool clay=false;
varying vec3 local_position;
varying vec3 local_normal;
void vertex(){local_position=VERTEX;local_normal=NORMAL;}
void fragment(){
    vec3 axis=pow(abs(normalize(local_normal)),vec3(4.0));axis/=max(axis.x+axis.y+axis.z,.001);
    vec3 p=local_position*1.7;
    vec3 stone=texture(albedo_map,p.zy).rgb*axis.x+texture(albedo_map,p.xz).rgb*axis.y+texture(albedo_map,p.xy).rgb*axis.z;
    vec3 rock=stone*host_tint;
    vec3 dp1=dFdx(VERTEX),dp2=dFdy(VERTEX);
    vec3 r1=cross(dp2,NORMAL),r2=cross(NORMAL,dp1);
    float determinant=dot(dp1,r1);
    vec3 gradient=(r1*dFdx(stone.r)+r2*dFdy(stone.r))*sign(determinant)/max(abs(determinant),0.00000001);
    NORMAL=normalize(NORMAL-.012*gradient);
    float mineral=clamp(COLOR.r,0.0,1.0);
    float scar=clamp(COLOR.g,0.0,1.0);
    float rim=smoothstep(.02,.35,scar)*(1.0-smoothstep(.55,.90,scar));
    ALBEDO=mix(rock,mineral_colour,mineral*.88)*(1.0-.78*rim)*tint;
    vec3 orm=texture(orm_map,p.zy).rgb*axis.x+texture(orm_map,p.xz).rgb*axis.y+texture(orm_map,p.xy).rgb*axis.z;
    ROUGHNESS=mix(clamp(orm.g,.7,1.0),mineral_roughness,mineral);
    METALLIC=mineral_metallic*mineral;
    float travel=.65+.35*sin((clock_seconds/period-COLOR.b*.35)*6.2831853);
    EMISSION=light_enabled ? state_emission*mix(.10,.40,mineral) : vec3(0.0);
    if(heat_active && light_enabled) EMISSION+=vec3(1.0,.18,.018)*pow(scar,3.0)*travel*.65;
    if(clay){ALBEDO=vec3(.38);ROUGHNESS=.9;METALLIC=0.0;EMISSION=vec3(0.0);}
}
