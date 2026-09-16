shader_type spatial;
render_mode diffuse_burley, specular_disabled, cull_disabled;
#include "res://land02/ground.gdshaderinc"
uniform sampler2D detail_mask:filter_nearest,repeat_disable;
uniform vec2 world_size=vec2(1024.0);
varying vec3 p;
varying vec3 n;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;n=MODEL_NORMAL_MATRIX*NORMAL;}
void fragment(){
 if(texture(detail_mask,p.xz/world_size).r>.5)discard;
 ALBEDO=COLOR.rgb;land02_surface(p,normalize(n),ALBEDO);ROUGHNESS=.92;
}
