shader_type spatial;
uniform sampler2D litter : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform float tile_m = 2.4;
varying vec3 world_position;
vec2 mirrored(vec2 p){return abs(fract(p*.5)*2.0-1.0);}
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
    vec2 p=world_position.xz/tile_m;
    vec3 a=texture(litter,mirrored(p)).rgb;
    vec3 b=texture(litter,mirrored(vec2(-p.y,p.x)*.73+vec2(.37,.61))).rgb;
    float blend=.5+.32*sin(p.x*.77+sin(p.y*.61));
    vec3 c=mix(a,b,blend);
    float edge=smoothstep(.65,1.6,abs(world_position.x));
    float pocket=.5+.5*sin(world_position.z*.42+world_position.x*.8);
    vec3 humus=vec3(.052,.032,.018)*( .85+.3*sin(p.x*31.0)*sin(p.y*37.0));
    ALBEDO=mix(mix(humus,c,.25),c,edge)*mix(vec3(1.0),vec3(.78,.89,.63),edge*pocket*.32);
    ROUGHNESS=.97;
}
