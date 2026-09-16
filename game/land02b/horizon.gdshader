shader_type spatial;
render_mode diffuse_burley, specular_disabled, cull_disabled;
uniform sampler2D detail_mask: filter_nearest,repeat_disable;
uniform sampler2D landmark_mask: filter_nearest,repeat_disable;
uniform vec2 world_size=vec2(1024.0);
varying vec2 world_uv;
varying vec3 world_position;
varying vec3 world_normal;
#include "res://land02b/ground.gdshaderinc"
void vertex(){world_uv=VERTEX.xz/world_size;world_position=VERTEX;world_normal=NORMAL;land02b_owner_uv=vec2(0);}
void fragment(){
 if(texture(detail_mask,world_uv).r>.5 || texture(landmark_mask,world_uv).r>.5)discard;
 ALBEDO=COLOR.rgb;ROUGHNESS=.95;
 vec3 gradient=vec3(0);
 float stone=1.-smoothstep(.65,.85,world_normal.y);
 float weather=.88+.12*sin(world_position.x*.14+sin(world_position.z*.11));
 ALBEDO*=weather;
 land02b_surface(world_position,world_normal,stone,ALBEDO,gradient,ROUGHNESS,EMISSION);
}
