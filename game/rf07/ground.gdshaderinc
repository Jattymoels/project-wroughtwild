// Exact native biome and original top height scope highland surface recovery.
#include "res://rf07/mineral.gdshaderinc"
uniform bool rf07_enabled=false;
uniform sampler2D rf07_mask : filter_linear, repeat_disable;
uniform sampler2D rf07_turf : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rf07_litter : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rf07_turf_detail : filter_linear_mipmap_anisotropic, repeat_enable;
uniform float rf07_ground_mix=.96;
uniform float rf07_ground_mineral_gain=.76;
uniform float rf07_pocket_fringe=.10;
void rf07_surface(vec3 p,vec3 n,float broad,float wear,inout vec3 colour,inout vec3 gradient,inout float roughness) {
 if(!rf07_enabled){return;}
 ivec2 size=textureSize(rf07_mask,0);
 ivec2 cell=ivec2(clamp(floor(p.xz),vec2(0.0),vec2(size-ivec2(1))));
 vec4 context=texelFetch(rf07_mask,cell,0);
 float weight=context.r*(1.0-smoothstep(.45,1.35,abs(p.y-context.g*255.0)));
 if(weight<.001){return;}
 float up=smoothstep(.55,.94,n.y);
 vec4 soft=texture(rf07_mask,p.xz/vec2(size));
 // Existing pockets feather through low turf/litter even where upright plants
 // cannot fit a protected work area or an abrupt native terrace.
 float pocket=smoothstep(rf07_pocket_fringe,.70,soft.b+(wear-.5)*.16)*up;
 vec2 uv=p.xz/2.4;
 vec2 rotated=vec2(-uv.y,uv.x)*.731+.37;
 vec3 turf=mix(texture(rf07_turf,uv).rgb,texture(rf07_turf,rotated).rgb,.38);
 vec3 litter=texture(rf07_litter,rotated).rgb;
 vec3 growth=mix(litter*vec3(.88,.85,.76),turf*vec3(.92,1.02,.83),smoothstep(.12,.60,soft.b));
 vec3 relief;float mineral_roughness;
 vec3 rock=rf07_mineral(p,n,relief,mineral_roughness)*rf07_ground_mineral_gain;
 vec3 recovered=mix(rock,growth,pocket*.97);
 colour=mix(colour,recovered,weight*rf07_ground_mix);
 vec2 slope=texture(rf07_turf_detail,uv).rg*2.0-1.0;
 vec3 ground_relief=mix(relief,vec3(-slope.x,0,-slope.y)*.24,pocket);
 gradient=mix(gradient,ground_relief,weight);
 roughness=mix(roughness,mix(mineral_roughness,.96,pocket),weight);
}
