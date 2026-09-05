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
uniform float surface_contrast = 0.0;
uniform float strata_metres = 0.32;
uniform float grain_metres = 0.065;
uniform bool stony = false;
uniform bool blend_materials = false;
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

// Irregular mineral plates; the nearest-two distance gap marks their joins.
float plate_edge(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	float first = 8.0;
	float second = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 offset = vec2(float(x),float(y));
			vec2 id = cell + offset;
			vec2 jitter = vec2(hash_point(vec3(id,13.0)),hash_point(vec3(id,37.0)));
			vec2 delta = offset + 0.15 + jitter * 0.7 - local;
			float distance = dot(delta,delta);
			second = min(second,max(first,distance));
			first = min(first,distance);
		}
	}
	return second-first;
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
	float stone_weight = stony ? 1.0 : 0.0;
	if (blend_materials && world_mesh) {
		base = COLOR.rgb;
		stone_weight = COLOR.a;
	}
	ALBEDO = base * (1.0 + variation);
	if (surface_contrast > 0.0) {
		// World-space detail survives chunk joins and digging. Distinct scales:
		// metre-wide weathering, broken bedding, then centimetre-scale grit.
		vec3 p = world_position;
		float weather = noise_at(p * vec3(0.7, 1.4, 0.7));
		float chips = noise_at(p * 4.5 + vec3(weather * 1.3));
		float footprint = max(length(dFdx(p)), length(dFdy(p)));
		float fine_fade = 1.0 - smoothstep(grain_metres * 0.3, grain_metres, footprint);
		// Rotated, incommensurate octaves avoid a visible square grain lattice.
		vec3 grain_point = mat3(vec3(0.8,0.0,0.6),vec3(0.18,0.95,-0.24),vec3(-0.57,0.3,0.76)) * p / grain_metres;
		float grit = (noise_at(grain_point)*0.65 + noise_at(grain_point*2.03)*0.35 - 0.5) * fine_fade;
		float slope = 1.0 - smoothstep(0.35, 0.9, normalize(world_normal).y);
		float layer = abs(sin((p.y / strata_metres + weather * 2.2 + chips * 0.14) * 3.14159));
		float bedding = 1.0 - smoothstep(0.04, 0.21, layer);
		// Intersecting irregular fracture lines break up otherwise blank rock tops.
		float fracture = 0.0;
		if (stone_weight > 0.01) {
			vec3 weights = pow(abs(normalize(world_normal)),vec3(4.0));
			weights /= dot(weights,vec3(1.0));
			vec3 plate = p * 1.8 + vec3(weather * 0.2);
			float edge_x = 1.0-smoothstep(0.008,0.035,plate_edge(plate.yz));
			float edge_y = 1.0-smoothstep(0.008,0.035,plate_edge(plate.xz));
			float edge_z = 1.0-smoothstep(0.008,0.035,plate_edge(plate.xy));
			fracture = dot(weights,vec3(edge_x,edge_y,edge_z)) * (1.0-smoothstep(0.025,0.12,footprint));
		}
		float mineral = smoothstep(0.52, 0.74, weather);
		float bare = smoothstep(0.43, 0.69, weather + (chips - 0.5) * 0.25);
		if (grassy && !blend_materials) {
				ALBEDO = mix(ALBEDO, side_colour.rgb, bare * turf * surface_contrast * 0.5);
		}
		float rock_detail = (weather-0.5)*0.65 + grit*0.45 - bedding*slope*0.2 - fracture*smoothstep(0.25,0.6,chips)*0.2;
		float earth_detail = (chips-0.5)*0.3 + grit*0.6 - bare*0.12;
		ALBEDO *= 1.0 + surface_contrast * mix(earth_detail,rock_detail,stone_weight);
		ALBEDO = mix(ALBEDO, ALBEDO * vec3(1.14,1.08,0.91),mineral*0.3*stone_weight);
	}
	ROUGHNESS = 1.0;
}
