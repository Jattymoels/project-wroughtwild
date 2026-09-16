uniform bool rf08_enabled = false;
uniform sampler2D rf08_mask : filter_linear, repeat_disable;
uniform float rf08_ground_mix = 0.62;
void rf08_surface(vec3 p, vec3 n, inout vec3 albedo, inout float roughness) {
 if (!rf08_enabled) return;
 ivec2 size = textureSize(rf08_mask, 0);
 ivec2 cell = ivec2(clamp(floor(p.xz), vec2(0.0), vec2(size-ivec2(1))));
 vec4 exact = texelFetch(rf08_mask,cell,0);
 if (exact.r<0.01 || abs(p.y-exact.b*255.0)>0.85) return;
 vec4 context = texture(rf08_mask,p.xz/vec2(size));
 float top = smoothstep(0.48,0.90,n.y);
 vec3 turf = texture(rf02_meadow_albedo,p.xz/rf02_tile_metres).rgb;
 vec3 litter = texture(rf02_woodland_albedo,p.xz/rf02_tile_metres).rgb;
 vec3 moss = turf * vec3(0.78,0.94,0.70);
 vec3 growth = mix(turf,mix(litter,moss,smoothstep(0.20,0.70,context.g)*0.96),context.a);
 vec3 loam = mix(albedo*vec3(0.74,0.69,0.60),growth,smoothstep(0.20,0.76,context.g));
 albedo = mix(albedo,loam,context.r*top*rf08_ground_mix);
 roughness = mix(roughness,0.95,context.r*top);
}
