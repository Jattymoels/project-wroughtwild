shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float wave=sin(world.x*1.7+TIME*.65)*cos(world.z*1.3-TIME*.4);
 float ripple=pow(max(0.0,sin(world.x*3.1+world.z*2.4+TIME*.65)),20.0);
 vec3 shallow=vec3(.22,.38,.31),deep=vec3(.065,.23,.26);
 ALBEDO=mix(shallow,deep,smoothstep(0.,.7,COLOR.r))*(1.+wave*.06)+ripple*.025;
 ROUGHNESS=.23+wave*.025;METALLIC=.18;
 NORMAL=normalize(NORMAL+vec3(cos(world.x*1.7+TIME*.65)*.045,0,sin(world.z*1.3-TIME*.4)*.045));
 ALPHA=.88;
}
