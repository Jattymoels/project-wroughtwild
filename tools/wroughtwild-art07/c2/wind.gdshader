shader_type spatial;
render_mode cull_disabled;
uniform float clock_seconds=0.0;
uniform float period=5.5;
uniform float tip=0.018;
void vertex(){
 float root=clamp(VERTEX.y/.32,0.0,1.0);
 VERTEX.x+=sin(clock_seconds*6.283185/period+VERTEX.x*2.0)*tip*root*root;
}
void fragment(){ALBEDO=COLOR.rgb;ROUGHNESS=.94;}
