shader_type spatial;
render_mode cull_disabled;
uniform int role=0;
uniform bool textured=true;
uniform bool altered=false;
uniform sampler2D albedo_map:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D orm_map:filter_linear_mipmap_anisotropic;
uniform bool has_orm=false;
uniform vec4 base_colour:source_color=vec4(1);
uniform float clock_seconds=0.0;
uniform bool light_enabled=true;
uniform float wind_tip_m=.035;
uniform float wind_period_s=5.5;
uniform float pulse_period_s=4.0;
uniform float peak_emission=2.4;
uniform float minimum_light=.22;
uniform vec3 tint=vec3(1);
uniform vec3 state_emission=vec3(0);
varying vec3 local_pos;
varying vec3 world_pos;
void vertex(){
 local_pos=VERTEX;
 if(role==1)VERTEX+=vec3(.75,.12,.4)*sin(clock_seconds*6.283185/wind_period_s+VERTEX.x*.7+VERTEX.z*.3)*wind_tip_m*UV2.x;
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;
}
void fragment(){
 if(!FRONT_FACING)NORMAL=-NORMAL;
 vec3 base=textured?texture(albedo_map,UV).rgb:base_colour.rgb;
 ROUGHNESS=.9;METALLIC=0.0;
 if(has_orm){vec3 orm=texture(orm_map,UV).rgb;ROUGHNESS=max(.65,orm.g);METALLIC=orm.b;}
 if(role==0)base*=vec3(1,.79,.52);
 if(role==1){base=COLOR.rgb*vec3(.95,.84,.67);BACKLIGHT=base*.25;ROUGHNESS=.8;}
 if(role==2)base=vec3(.14,.09,.045);
 if(role==3 && !textured)base=COLOR.rgb;
 float core=altered?clamp(UV2.x,0.0,1.0):0.0;
 float damage=altered?clamp(1.0-UV2.y,0.0,1.0):0.0;
 base=mix(base,vec3(.011,.006,.003),damage*.94);
 float phase=fract(clock_seconds/pulse_period_s-local_pos.y*.11);
 float crest=exp(-pow(min(phase,1.0-phase)/.16,2.0));
 EMISSION=state_emission+(light_enabled?vec3(1,.16,.015)*core*peak_emission*mix(minimum_light,1.0,crest):vec3(0));
 if(role==5){
  vec2 p=world_pos.xz*.42;
  vec2 a=abs(fract(p*.5)*2.0-1.0);
  vec2 b=abs(fract((vec2(-p.y,p.x)*.73+vec2(.37,.61))*.5)*2.0-1.0);
  base=mix(texture(albedo_map,a).rgb,texture(albedo_map,b).rgb,.5+.25*sin(p.x+.7*sin(p.y)));
  base=mix(vec3(.055,.032,.016),base,smoothstep(.5,1.4,abs(world_pos.x))*.55+.3);
 }
 ALBEDO=base*tint;
}
