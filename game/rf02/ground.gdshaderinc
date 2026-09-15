// Optional RF02 surface treatment. Disabled defaults preserve earlier profiles.
uniform bool rf02_enabled = false;
uniform bool rf02_soil_only = false;
uniform sampler2D rf02_biome_mask : filter_linear, repeat_disable;
uniform sampler2D rf02_meadow_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rf02_meadow_detail : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rf02_woodland_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rf02_woodland_detail : filter_linear_mipmap_anisotropic, repeat_enable;
uniform float rf02_cell_m = 1.0;
uniform float rf02_tile_metres = 2.4;
uniform float rf02_detail_strength = 0.32;
uniform float rf02_broad_variation = 0.16;

void rf02_surface(vec3 p, vec3 n, float stone, vec3 native_base, vec3 reference,
	vec3 loam, float broad, float influence, inout vec3 albedo,
	inout vec3 gradient, inout float roughness, inout float occlusion) {
	if (!rf02_enabled) { return; }
	ivec2 size = textureSize(rf02_biome_mask, 0);
	ivec2 cell = ivec2(clamp(floor(p.xz / rf02_cell_m), vec2(0.0), vec2(size - ivec2(1))));
	// Exact eligibility prevents even half a texel of tint leaking into fen/rock biomes.
	if (texelFetch(rf02_biome_mask, cell, 0).r < 0.5) { return; }
	vec2 biome = texture(rf02_biome_mask, p.xz / (vec2(size) * rf02_cell_m)).rg;
	float woodland = clamp(biome.g / max(biome.r, 0.001), 0.0, 1.0);
	vec2 a = p.xz / rf02_tile_metres;
	vec2 b = vec2(-a.y, a.x) * 0.731 + vec2(0.371, 0.613);
	float blend = smoothstep(0.28, 0.72, broad) * 0.5 + 0.18;
	vec3 turf = mix(texture(rf02_meadow_albedo, a).rgb, texture(rf02_meadow_albedo, b).rgb, blend);
	vec3 litter = mix(texture(rf02_woodland_albedo, a).rgb, texture(rf02_woodland_albedo, b).rgb, blend);
	vec3 da = mix(texture(rf02_meadow_detail, a).rgb, texture(rf02_woodland_detail, a).rgb, woodland);
	vec3 db = mix(texture(rf02_meadow_detail, b).rgb, texture(rf02_woodland_detail, b).rgb, woodland);
	vec2 slope_a = da.rg * 2.0 - 1.0;
	vec2 slope_b = db.rg * 2.0 - 1.0;
	slope_b = vec2(slope_b.y, -slope_b.x) * 0.731;
	vec2 slope = mix(slope_a, slope_b, blend);
	float up = rf02_soil_only ? 0.0 : smoothstep(0.32, 0.86, n.y);
	vec3 surface = mix(loam * (0.9 + (broad - 0.5) * 0.16), mix(turf, litter, woodland), up);
	// Keep the native interpolated neighbour colours and stone weight at joins.
	vec3 joins = clamp(native_base / max(reference, vec3(0.018)), vec3(0.52), vec3(1.45));
	surface *= mix(vec3(1.0), joins, 0.65);
	surface *= 1.0 + (broad - 0.5) * rf02_broad_variation;
	surface *= mix(vec3(1.0), vec3(0.69, 0.74, 0.68), influence);
	float weight = 1.0 - stone;
	albedo = mix(albedo, surface, weight);
	gradient = mix(gradient, vec3(-slope.x, 0.0, -slope.y) * rf02_detail_strength * mix(0.28, 1.0, up), weight);
	roughness = mix(roughness, mix(da.b, db.b, blend), weight);
	occlusion = mix(occlusion, 0.98, weight);
}
