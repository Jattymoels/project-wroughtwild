// Shared weathered mineral for existing highland outcrops and exposed ground.
// Colours are sRGB authoring values; source_color converts them once.
uniform vec4 rf07_mineral_dark : source_color=vec4(.265,.29,.315,1.0);
uniform vec4 rf07_mineral_light : source_color=vec4(.57,.55,.50,1.0);
uniform vec4 rf07_oxide : source_color=vec4(.40,.29,.18,1.0);
uniform vec4 rf07_lichen : source_color=vec4(.36,.39,.22,1.0);
uniform float rf07_mineral_relief=.045;
float rf07_hash(vec3 p) {
 p=fract(p*.1031);p+=dot(p,p.yzx+33.33);return fract((p.x+p.y)*p.z);
}
vec4 rf07_noise(vec3 p) {
 vec3 i=floor(p),t=fract(p),f=t*t*(3.0-2.0*t),df=6.0*t*(1.0-t);
 float a=rf07_hash(i),b=rf07_hash(i+vec3(1,0,0)),c=rf07_hash(i+vec3(0,1,0)),d=rf07_hash(i+vec3(1,1,0));
 float e=rf07_hash(i+vec3(0,0,1)),h=rf07_hash(i+vec3(1,0,1)),g=rf07_hash(i+vec3(0,1,1)),j=rf07_hash(i+vec3(1,1,1));
 float x0=mix(a,b,f.x),x1=mix(c,d,f.x),x2=mix(e,h,f.x),x3=mix(g,j,f.x);
 return vec4(mix(mix(x0,x1,f.y),mix(x2,x3,f.y),f.z),
  vec3(mix(mix(b-a,d-c,f.y),mix(h-e,j-g,f.y),f.z),mix(x1-x0,x3-x2,f.z),mix(x2,x3,f.y)-mix(x0,x1,f.y))*df);
}
vec3 rf07_mineral(vec3 p,vec3 n,out vec3 relief,out float roughness) {
 // Rotated, nonperiodic weathering replaces horizontal sine stripes.
 mat3 turn=mat3(vec3(.8,0,.6),vec3(.18,.95,-.24),vec3(-.57,.3,.76));
 vec3 q=turn*p;
 vec4 wear=rf07_noise(q*.85);
 vec4 chips=rf07_noise(q*6.3+vec3(17.2,3.1,8.7));
 float face=smoothstep(.25,.78,wear.x);
 vec3 stone=mix(rf07_mineral_dark.rgb,rf07_mineral_light.rgb,face);
 stone*=.84+chips.x*.32;
 float oxide=smoothstep(.65,.84,wear.x)*(1.0-smoothstep(.35,.85,n.y));
 stone=mix(stone,rf07_oxide.rgb,oxide*.24);
 float lichen=smoothstep(.57,.79,wear.x)*smoothstep(.64,.95,n.y);
 stone=mix(stone,rf07_lichen.rgb,lichen*.36);
 float pixel=max(length(dFdx(p)),length(dFdy(p)));
 float detail=1.0-smoothstep(.055,.24,pixel);
 relief=transpose(turn)*(wear.yzw*.85+chips.yzw*6.3*detail*.28)*rf07_mineral_relief;
 roughness=mix(.78,.94,wear.x);
 return stone;
}
