shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;
uniform float clock_seconds=0.0;
uniform float plant_bend=0.025;
uniform float leaf_normal_up_mix=0.48;
uniform float leaf_backlight=0.07;
uniform bool release_host=false;
varying vec3 local_position;
void vertex(){
 local_position=VERTEX;
 float h=max(VERTEX.y,0.0);
 vec3 origin=MODEL_MATRIX[3].xyz;
 float phase=clock_seconds*1.1424+origin.x*.19+origin.z*.13;
 VERTEX+=vec3(1.0,0.0,.35)*sin(phase)*plant_bend*h;
}
void fragment(){
 if(!FRONT_FACING)NORMAL=-NORMAL;
 vec3 up=normalize((VIEW_MATRIX*vec4(0.0,1.0,0.0,0.0)).xyz);
 NORMAL=normalize(mix(NORMAL,up,leaf_normal_up_mix));
 ALBEDO=COLOR.rgb*1.65;
 BACKLIGHT=ALBEDO*leaf_backlight;
 ROUGHNESS=.92;SPECULAR=.15;
 if(release_host){
  float red=smoothstep(2.5,5.0,COLOR.r/max(COLOR.g,.005))*step(.25,COLOR.r);
  float pulse=.14+.86*pow(.5+.5*sin(TIME*1.6-local_position.x*3.1),7.0);
  EMISSION=vec3(.65,.053,.009)*red*pulse*.5;
 }
}
