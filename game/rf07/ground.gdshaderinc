// Exact native biome and original top height scope highland surface recovery.
uniform bool rf07_enabled=false;
uniform sampler2D rf07_mask : filter_linear, repeat_disable;
uniform float rf07_ground_mix=.96;
// Fixed palette: worn stone range, restrained lichen and accumulated pocket soil.
uniform vec4 rf07_stone_dark : source_color=vec4(.24,.265,.24,1.0);
uniform vec4 rf07_stone_light : source_color=vec4(.39,.41,.36,1.0);
uniform vec4 rf07_lichen : source_color=vec4(.33,.36,.20,1.0);
uniform vec4 rf07_soil : source_color=vec4(.22,.255,.13,1.0);
void rf07_surface(vec3 p,vec3 n,float broad,float wear,inout vec3 colour,inout vec3 gradient,inout float roughness) {
 if(!rf07_enabled){return;}
 ivec2 size=textureSize(rf07_mask,0);
 ivec2 cell=ivec2(clamp(floor(p.xz),vec2(0.0),vec2(size-ivec2(1))));
 vec4 context=texelFetch(rf07_mask,cell,0);
 float weight=context.r*(1.0-smoothstep(.45,1.35,abs(p.y-context.g*255.0)));
 float up=smoothstep(.55,.94,n.y);
 vec4 soft=texture(rf07_mask,p.xz/vec2(size));
 float pocket=soft.b*up;
 vec3 rock=mix(rf07_stone_dark.rgb,rf07_stone_light.rgb,broad*.65+wear*.35);
 float lichen=smoothstep(.47,.67,wear+soft.a*.12)*up;
 rock=mix(rock,rf07_lichen.rgb,lichen*.35);
 vec3 soil=rf07_soil.rgb*(.83+wear*.3);
 vec3 recovered=mix(rock,soil,pocket*.88);
 colour=mix(colour,recovered,weight*rf07_ground_mix);
 roughness=mix(roughness,.95,weight);
 gradient*=1.0-weight*.6;
}
