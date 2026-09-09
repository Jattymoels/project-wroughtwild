shader_type spatial;
render_mode cull_disabled;
uniform int role=0; // bark 0, foliage 1, twig 2
uniform sampler2D base_texture:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D orm_texture:filter_linear_mipmap_anisotropic;
uniform float clock_seconds=0.0;
uniform bool light_enabled=true;
uniform float peak_emission=2.8;
uniform float period_seconds=4.0;
uniform float minimum_light=.22;
uniform float wind_tip_m=.055;
uniform float wind_period_seconds=4.8;
varying vec3 local_position;
void vertex(){
 local_position=VERTEX;
 if(role==1){
  // Root has UV2.x=0: leaf petioles stay on the actual rigid branchlet.
  float wave=sin(clock_seconds*6.283185/wind_period_seconds+VERTEX.x*.7+VERTEX.z*.3);
  VERTEX+=vec3(.75,.25,.40)*wave*wind_tip_m*UV2.x;
 }
}
void fragment(){
 if(!FRONT_FACING){NORMAL=-NORMAL;}
 vec3 base=texture(base_texture,UV).rgb;
 ROUGHNESS=max(.65,texture(orm_texture,UV).g);METALLIC=0.0;
 if(role==1){
  float rib=1.0-smoothstep(.01,.04,abs(UV.x-.5));
  base=COLOR.rgb*(.88+.12*rib);ROUGHNESS=.79;BACKLIGHT=base*.3;
 }else if(role==2){base=vec3(.14,.105,.065);ROUGHNESS=.92;}
 // glTF inverts Blender UV V on export; decode the authored damage explicitly.
 float damage=role==0 ? clamp(1.0-UV2.y,0.0,1.0):0.0;
 float core=role==0 ? clamp(UV2.x,0.0,1.0):0.0;
 ALBEDO=mix(base,vec3(.010,.007,.004),damage*.94);
 float phase=fract(clock_seconds/period_seconds-local_position.y*.11);
 float crest=exp(-pow(min(phase,1.0-phase)/.16,2.0));
 EMISSION=light_enabled ? vec3(1.0,.09,.004)*core*peak_emission*mix(minimum_light,1.0,crest):vec3(0);
}
