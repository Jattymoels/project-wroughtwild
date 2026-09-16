shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;
uniform bool foliage=true;
varying vec3 world_pos;
varying float leaf_part;
void vertex(){
 leaf_part=foliage ? smoothstep(1.02,1.28,COLOR.g/max(COLOR.r,.001)) : 0.0;
 float sway=sin(TIME*.7+MODEL_MATRIX[3].x*.12+MODEL_MATRIX[3].z*.17+VERTEX.y*.24);
 VERTEX.x+=sway*.025*max(0.0,VERTEX.y-2.0)*leaf_part;
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment(){
 if(!FRONT_FACING)NORMAL=-NORMAL;
 vec3 up=normalize((VIEW_MATRIX*vec4(0,1,0,0)).xyz);
 NORMAL=normalize(mix(NORMAL,up,.40*leaf_part));
 float fibre=sin(world_pos.y*.48+sin(world_pos.x*21.0+world_pos.z*17.0)*2.0);
 float grain=.88+.12*fibre;
 ALBEDO=COLOR.rgb*mix(grain,1.38,leaf_part);
 BACKLIGHT=COLOR.rgb*.14*leaf_part;
 ROUGHNESS=.93;SPECULAR=.15;
}
