shader_type spatial;
render_mode cull_disabled;
// Roles: bark, leaf, twig, rooted plant, rock, ground, water.
uniform int role=0;
uniform bool textured=true;
uniform bool altered=false;
uniform bool ground_conform=false;
uniform bool has_orm=false;
uniform sampler2D albedo_map:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D orm_map:filter_linear_mipmap_anisotropic;
uniform float clock_seconds=0.0;
uniform bool light_enabled=true;
uniform float wind_period_s=5.5;
uniform float leaf_tip_m=.055;
uniform vec3 leaf_colour_gain=vec3(.85,.72,.60);
uniform float plant_bend=.018;
uniform float pulse_period_s=4.0;
uniform float water_flow=.12;
uniform vec3 haze_color:source_color=vec3(.35,.43,.43);
varying vec3 wp;
varying vec3 local_pos;
float river(float z){return -5.8+sin(z*.12)+.35*sin(z*.31);}
float analytic_ground(vec2 p){float r=abs(p.x-river(p.y));return 1.25*(1.0-exp(-pow(r/3.0,4.0)))-.8+.13*sin(p.x*.31+p.y*.19)+.10*cos(p.y*.34-p.x*.22)+max(0.0,abs(p.x)-9.0)*.035+3.4*exp(-pow((p.y-34.0)/10.0,2.0));}
float ground(vec2 p){vec2 a=floor(p*2.0)*.5;vec2 f=(p-a)*2.0;float h00=analytic_ground(a);float h10=analytic_ground(a+vec2(.5,0));float h01=analytic_ground(a+vec2(0,.5));float h11=analytic_ground(a+vec2(.5,.5));return f.x+f.y<=1.0?h00+f.x*(h10-h00)+f.y*(h01-h00):h11+(1.0-f.x)*(h01-h11)+(1.0-f.y)*(h10-h11);}
vec2 mirror_uv(vec2 p){return abs(fract(p*.5)*2.0-1.0);}
void vertex(){
 local_pos=VERTEX;
 vec3 origin=MODEL_MATRIX[3].xyz;
 float phase=clock_seconds*6.283185/wind_period_s+origin.x*.7+origin.z*.3;
 if(role==1)VERTEX+=vec3(.75,.12,.40)*sin(phase)*leaf_tip_m*UV2.x;
 if(role==3){float h=max(VERTEX.y,0.0);VERTEX+=vec3(1.0,0.0,.35)*sin(phase)*plant_bend*h;}
 vec4 w=MODEL_MATRIX*vec4(VERTEX,1.0);
 if(ground_conform){w.y+=ground(w.xz)-ground(origin.xz);VERTEX=(inverse(MODEL_MATRIX)*w).xyz;}
 wp=w.xyz;
}
void fragment(){
 if(!FRONT_FACING)NORMAL=-NORMAL;
 vec3 base=textured?texture(albedo_map,UV).rgb:COLOR.rgb;
 ROUGHNESS=.86;METALLIC=0.0;
 // glTF metallic/roughness exports can leave R empty; it is not an AO map.
 if(has_orm){vec3 orm=texture(orm_map,UV).rgb;ROUGHNESS=max(.65,orm.g);METALLIC=orm.b;}
 if(role==1){base=COLOR.rgb*leaf_colour_gain;BACKLIGHT=base*.22;}
 if(role==3 && !textured)base*=leaf_colour_gain;
 if(role==2)base=vec3(.14,.105,.065);
 float core=0.0;float damage=0.0;
 if(altered && role==0){core=clamp(UV2.x,0.0,1.0);damage=clamp(1.0-UV2.y,0.0,1.0);}
 if(altered && role==4){core=smoothstep(.55,.92,COLOR.r);damage=smoothstep(.08,.55,COLOR.r)*.8;}
 base=mix(base,vec3(.012,.007,.004),damage*.94);
 float phase=fract(clock_seconds/pulse_period_s-(role==0?local_pos.y*.11:COLOR.b*.8));
 float crest=exp(-pow(min(phase,1.0-phase)/.16,2.0));
 EMISSION=light_enabled?vec3(1.0,.10,.005)*core*2.8*mix(.22,1.0,crest):vec3(0.0);
 if(role==5){
  vec2 p=wp.xz/2.4;
  vec3 a=texture(albedo_map,mirror_uv(p)).rgb;
  vec3 b=texture(albedo_map,mirror_uv(vec2(-p.y,p.x)*.73+vec2(.37,.61))).rgb;
  vec3 c=mix(a,b,.5+.32*sin(p.x*.77+sin(p.y*.61)));
  float route=.9*sin(wp.z*.15)+.35*sin(wp.z*.33);
  float edge=smoothstep(.7,1.5,abs(wp.x-route));
  float wet=1.0-smoothstep(1.3,3.0,abs(wp.x-river(wp.z)));
  base=mix(mix(vec3(.07,.044,.025),c,.35),c,edge)*mix(vec3(1),vec3(.52,.65,.59),wet);
  ROUGHNESS=.96;
 }
 if(role==6){
  float flow=wp.z+clock_seconds*water_flow;
  float broad=sin(flow*.85+sin(wp.x*1.7)*.6);
  float ripple=sin(flow*13.0+sin(wp.x*4.0)*1.2);
  float shore=smoothstep(1.1,1.5,abs(wp.x-river(wp.z)));
  base=mix(vec3(.025,.085,.085),vec3(.15,.24,.19),shore)+vec3(.015,.022,.02)*broad;
  NORMAL=normalize(NORMAL+vec3(broad*.03,0,ripple*.018));
  ROUGHNESS=.23+.18*shore;METALLIC=.3;
 }
 float haze=1.0-exp(-max(0.0,length(VERTEX)-24.0)*.022);
 ALBEDO=mix(base,haze_color,haze*.65);
 EMISSION*=1.0-haze*.65;
}
