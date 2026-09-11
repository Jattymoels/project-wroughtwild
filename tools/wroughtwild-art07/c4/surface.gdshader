shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_map:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D orm_map:filter_linear_mipmap_anisotropic;
uniform bool textured=false;
uniform bool has_orm=false;
uniform bool vertex_colour=false;
uniform bool plant=false;
uniform bool altered=false;
uniform bool floor_surface=false;
uniform vec4 base_colour:source_color=vec4(0.3,0.25,0.18,1.0);
uniform float clock_seconds=0.0;
uniform bool light_enabled=true;
uniform float wind_period_s=5.5;
uniform float plant_bend=0.018;
uniform float pulse_period_s=4.0;
varying vec3 wp;
float analytic(vec2 p){return .10*sin(p.x*.4)+.07*cos(p.y*.3)+max(0.0,abs(p.x)-9.0)*.10+1.8*exp(-pow((p.y-46.0)/9.0,2.0));}
float ground(vec2 p){vec2 a=floor(p*2.0)*.5;vec2 f=(p-a)*2.0;float h00=analytic(a);float h10=analytic(a+vec2(.5,0));float h01=analytic(a+vec2(0,.5));float h11=analytic(a+vec2(.5,.5));return f.x+f.y<=1.0?h00+f.x*(h10-h00)+f.y*(h01-h00):h11+(1.0-f.x)*(h01-h11)+(1.0-f.y)*(h10-h11);}
vec2 mirror_uv(vec2 p){return abs(fract(p*.5)*2.0-1.0);}
void vertex(){
 vec3 origin=MODEL_MATRIX[3].xyz;
 if(plant){
  float phase=clock_seconds*6.283185/wind_period_s+origin.x*.7+origin.z*.3;
  VERTEX+=vec3(1,0,.35)*sin(phase)*plant_bend*max(VERTEX.y,0.0);
 }
 vec4 w=MODEL_MATRIX*vec4(VERTEX,1);
 if(plant){w.y+=ground(w.xz)-ground(origin.xz);VERTEX=(inverse(MODEL_MATRIX)*w).xyz;}
 wp=w.xyz;
}
void fragment(){
 if(!FRONT_FACING)NORMAL=-NORMAL;
 vec3 base=textured?texture(albedo_map,UV).rgb:(vertex_colour?COLOR.rgb:base_colour.rgb);
 ROUGHNESS=.9;METALLIC=0.0;
 if(has_orm){vec3 orm=texture(orm_map,UV).rgb;ROUGHNESS=max(.7,orm.g);METALLIC=orm.b;}
 float injury=altered?clamp(UV2.x,0,1):0.0;
 base=mix(base,vec3(.012,.008,.004),smoothstep(.02,.55,injury)*.92);
 float phase=fract(clock_seconds/pulse_period_s-UV2.y*.8);
 float crest=exp(-pow(min(phase,1.0-phase)/.16,2.0));
 EMISSION=light_enabled?vec3(1.0,.16,.015)*smoothstep(.45,.9,injury)*mix(.12,2.3,crest):vec3(0);
 if(floor_surface){
  vec2 p=wp.xz/2.4;
  vec3 a=texture(albedo_map,mirror_uv(p)).rgb;
  vec3 b=texture(albedo_map,mirror_uv(vec2(-p.y,p.x)*.73+vec2(.37,.61))).rgb;
  vec3 c=mix(a,b,.5+.32*sin(p.x*.77+sin(p.y*.61)));
  float edge=smoothstep(.7,1.6,abs(wp.x));
  float grey=dot(c,vec3(.3,.5,.2));
  c=mix(c,vec3(grey*.88,grey*.85,grey*.79),.72);
  base=mix(vec3(.085,.073,.057),c,edge*.8+.2);
 }
 ALBEDO=base;
}
