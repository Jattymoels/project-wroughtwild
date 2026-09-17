// Disabled for all prior identities. V11 binds its actual ecological mask.
uniform bool land03_enabled=false;
uniform sampler2D land03_mask:filter_linear,repeat_disable;
uniform vec2 land03_world_size=vec2(1024);
void land03_surface(vec3 p,vec3 n,float stone,float broad,float wear,inout vec3 colour,inout float roughness){
 if(!land03_enabled)return;
 float weight=texture(land03_mask,p.xz/land03_world_size).r;
 if(weight<.001)return;
 float up=smoothstep(.40,.90,n.y);
 float dry=smoothstep(.22,.72,broad);
 vec3 soil=mix(vec3(.19,.145,.067),vec3(.31,.235,.112),dry);
 float blades=.5+.5*sin(p.x*.39+sin(p.z*.20))*sin(p.z*.27);
 soil=mix(soil,vec3(.155,.171,.066),blades*.26*up);
 // Keep the shared mineral texture/relief readable on the physical ribs.
 // Only upward dry soil receives the new habitat response.
 float exposed=max(stone,1.-up);
 colour=mix(colour,soil,weight*.78*up*(1.-stone*.75));
 colour*=mix(vec3(1.0),vec3(1.10,1.02,.85),weight*.35*exposed);
 roughness=mix(roughness,.91,weight);
}
