shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;
uniform int channel=0;
uniform float plant_bend=0.0;
uniform float pulse_strength=0.55;
varying vec3 object_position;
void vertex(){
 object_position=VERTEX;
 float foliage=step(.28,VERTEX.y);
 VERTEX.x+=sin(TIME*1.05+MODEL_MATRIX[3].x*.27+MODEL_MATRIX[3].z*.17)*plant_bend*max(VERTEX.y,0.0)*foliage;
}
void fragment(){
 if(!FRONT_FACING)NORMAL=-NORMAL;
 float grain=sin(object_position.x*39.0+sin(object_position.z*18.0))*sin(object_position.z*43.0+object_position.y*12.0);
 ALBEDO=COLOR.rgb*(1.58+grain*.065);
 ROUGHNESS=.89;SPECULAR=.17;
 float marker=0.0;vec3 light=vec3(0.0);float pulse=0.0;
 float branch_distance=1.0-UV.y;
 if(channel==1){
  marker=step(.54,min(COLOR.r,min(COLOR.g,COLOR.b)));
  light=vec3(.65,.76,.67);
  float cursor=fract(TIME*.22);
  pulse=pow(max(0.0,1.0-abs(fract(branch_distance*.44)-cursor)*6.0),3.0);
 }else if(channel==2){
  marker=step(.40,COLOR.b)*step(1.5,COLOR.b/max(COLOR.g,.01));
  light=vec3(.05,.30,.66);
  pulse=.24+.50*smoothstep(-.6,.7,sin(TIME*.58+UV.y*.5));
 }else if(channel==3){
  marker=step(.40,COLOR.g)*step(2.0,COLOR.g/max(max(COLOR.r,COLOR.b),.01));
  light=vec3(.08,.49,.20);
  float distance_from_fork=fract(branch_distance*.35);
  float cursor=fract(TIME*.18);
  pulse=.06+.94*pow(max(0.0,1.0-abs(distance_from_fork-cursor)*8.0),3.0);
 }
 EMISSION=light*marker*pulse*pulse_strength;
 BACKLIGHT=ALBEDO*.025*step(.12,COLOR.g-COLOR.r);
}
