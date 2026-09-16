shader_type spatial;
render_mode cull_disabled,diffuse_burley;
varying vec3 world_pos;
void vertex(){
 float phase=MODEL_MATRIX[3].x*.17+MODEL_MATRIX[3].z*.11;
 VERTEX.x+=sin(TIME*.65+phase+VERTEX.z*.6)*.018*max(0.,VERTEX.y-5.);
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;
}
void fragment(){
 if(!FRONT_FACING)NORMAL=-NORMAL;
 vec3 up=normalize((VIEW_MATRIX*vec4(0,1,0,0)).xyz);
 NORMAL=normalize(mix(NORMAL,up,.28));
 ALBEDO=COLOR.rgb*1.2;
 BACKLIGHT=ALBEDO*.22;
 ROUGHNESS=.84;SPECULAR=.24;
}
