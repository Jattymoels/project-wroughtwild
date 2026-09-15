// Exact biome/bank eligibility and original top height prevent cave/side tint.
uniform bool rf06_enabled = false;
uniform sampler2D rf06_mask : filter_nearest, repeat_disable;
uniform sampler2D rf06_litter : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float rf06_mix = 0.42;
void rf06_surface(vec3 p, vec3 n, float stone, float broad, inout vec3 colour, inout float roughness) {
 if (!rf06_enabled) { return; }
 ivec2 size = textureSize(rf06_mask,0);
 ivec2 cell = ivec2(clamp(floor(p.xz),vec2(0.0),vec2(size-ivec2(1))));
 vec2 context = texelFetch(rf06_mask,cell,0).rg;
 float weight = context.r * (1.0-stone) * smoothstep(0.65,0.95,n.y);
 weight *= 1.0-smoothstep(0.35,0.8,abs(p.y-context.g*255.0));
 vec2 uv = p.xz / 2.4;
 vec3 litter = mix(texture(rf06_litter,uv).rgb,texture(rf06_litter,vec2(-uv.y,uv.x)*0.731+0.37).rgb,0.42);
 vec3 damp = litter * vec3(0.83,0.91,0.80);
 colour = mix(colour,damp,weight*rf06_mix*(0.75+broad*0.25));
 roughness = mix(roughness,0.92,weight*rf06_mix);
}
