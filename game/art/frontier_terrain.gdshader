// Codex comparison material. World coordinates keep colour continuous
// across blocks/chunks and stable after excavation. Geometry is unchanged.
shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform vec4 top_colour : source_color;
uniform vec4 side_colour : source_color;
uniform float patch_metres = 12.0;
uniform float detail_metres = 0.8;
uniform float colour_variation = 0.12;
uniform float grass_edge_depth = 0.18;
uniform float cell_metres = 1.0;
uniform bool grassy = false;
uniform bool world_mesh = false;
uniform bool soft_terrain = false;
uniform float turf_slope_start = 0.25;
uniform float turf_slope_end = 0.8;
varying vec3 world_position;
varying vec3 world_normal;
varying float block_height;

float hash_point(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise_at(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash_point(i), hash_point(i + vec3(1,0,0)), f.x),
		mix(hash_point(i + vec3(0,1,0)), hash_point(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash_point(i + vec3(0,0,1)), hash_point(i + vec3(1,0,1)), f.x),
		mix(hash_point(i + vec3(0,1,1)), hash_point(i + vec3(1,1,1)), f.x), f.y), f.z);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
	block_height = VERTEX.y / cell_metres + 0.5;
	if (world_mesh) {
		block_height = fract(world_position.y / cell_metres - 0.0001);
	}
}

void fragment() {
	float broad = noise_at(world_position / patch_metres);
	float grain = noise_at(world_position / detail_metres);
	float variation = (broad - 0.5) * 2.0 * colour_variation;
	variation += (grain - 0.5) * colour_variation * 0.3;
	float edge = smoothstep(1.0 - grass_edge_depth - grain * 0.08, 1.0 - grain * 0.04, block_height);
	float turf = max(step(0.5, world_normal.y), edge);
	if (soft_terrain) {
		// A continuous slope mask; no per-voxel grass stripe on curved ground.
		turf = smoothstep(turf_slope_start, turf_slope_end, normalize(world_normal).y + (broad - 0.5) * 0.12);
	}
	vec3 base = grassy ? mix(side_colour.rgb, top_colour.rgb, turf) : top_colour.rgb;
	ALBEDO = base * (1.0 + variation);
	ROUGHNESS = 1.0;
}
