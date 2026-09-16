shader_type spatial;
render_mode cull_disabled,depth_draw_opaque;
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 float a=sin(world.x*.72+world.z*.43+TIME*.5);
 float b=sin(world.x*1.6-world.z*1.22-TIME*.7);
 float depth=smoothstep(0.,.85,COLOR.r);
 ALBEDO=mix(vec3(.075,.135,.095),vec3(.016,.055,.064),depth);
 ROUGHNESS=.14+(a+b)*.016;METALLIC=.0;SPECULAR=.75;
 vec3 dx=normalize((VIEW_MATRIX*vec4(1,0,0,0)).xyz);
 vec3 dz=normalize((VIEW_MATRIX*vec4(0,0,1,0)).xyz);
 NORMAL=normalize(NORMAL+dx*a*.026+dz*b*.025);
 ALPHA=mix(.60,.91,depth);
}
