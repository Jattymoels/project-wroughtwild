shader_type spatial;
uniform vec4 stone_tint : source_color=vec4(.29,.31,.28,1.0);
uniform vec4 lichen_tint : source_color=vec4(.33,.36,.20,1.0);
varying vec3 p;
varying vec3 n;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;n=MODEL_NORMAL_MATRIX*NORMAL;}
void fragment(){
 float band=sin(p.y*8.0+sin(p.x*1.8)+sin(p.z*1.7))*.5+.5;
 float wear=sin(p.x*2.17+p.z*.83)*sin(p.z*2.43-p.x*.48)*.5+.5;
 float lichen=smoothstep(.56,.79,wear)*smoothstep(.3,.9,normalize(n).y);
 ALBEDO=mix(stone_tint.rgb*(.82+band*.13+wear*.12),lichen_tint.rgb,lichen*.55);
 ROUGHNESS=.94;SPECULAR=.16;
}
