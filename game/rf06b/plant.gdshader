shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;
uniform float clock_seconds=0.0;
uniform float plant_bend=0.017;
uniform float leaf_normal_up_mix=0.64;
uniform float leaf_backlight=0.10;
// Linear GLTF vertex colours retain authored root/tip and leaf/stem variation.
// Local reflectance/wrapped diffuse keep shaded leaves readable without emission.
uniform float leaf_colour_gain=1.90;
void vertex(){
 float h=max(VERTEX.y,0.0);
 vec3 origin=MODEL_MATRIX[3].xyz;
 float phase=clock_seconds*1.1424+origin.x*.71+origin.z*.33;
 VERTEX+=vec3(1.0,0.0,.35)*sin(phase)*plant_bend*h;
}
void fragment(){
 if(!FRONT_FACING)NORMAL=-NORMAL;
 vec3 up=normalize((VIEW_MATRIX*vec4(0.0,1.0,0.0,0.0)).xyz);
 NORMAL=normalize(mix(NORMAL,up,leaf_normal_up_mix));
 ALBEDO=COLOR.rgb*leaf_colour_gain;
 BACKLIGHT=ALBEDO*leaf_backlight;
 ROUGHNESS=.94;
 SPECULAR=.12;
}
