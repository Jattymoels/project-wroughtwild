// Frontier v3: continuous natural materials. These fields affect only colour,
// surface relief and roughness; editable geometry and collision stay intact.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 top_colour : source_color;
uniform vec4 side_colour : source_color;
uniform vec4 loam_colour : source_color = vec4(0.30, 0.25, 0.17, 1.0);
uniform vec4 moss_colour : source_color = vec4(0.25, 0.31, 0.17, 1.0);
uniform vec4 dry_colour : source_color = vec4(0.40, 0.38, 0.25, 1.0);
uniform float patch_metres = 21.0;
uniform float colour_variation = 0.48;
uniform float soil_exposure = 0.70;
uniform float stone_moss = 0.24;
uniform float grain_metres = 0.075;
uniform float bump_height_m = 0.018;
uniform float rock_bump_m = 0.04;
uniform float rock_roughness = 0.78;
uniform bool grassy = false;
uniform bool stony = false;
uniform bool world_mesh = false;
uniform bool blend_materials = true;
// Native v4 influence only; older profiles leave this disabled.
uniform bool augmentation_enabled = false;
uniform sampler2D augmentation_map : filter_linear, repeat_disable;
uniform vec2 augmentation_extent = vec2(512.0);
uniform float augmentation_tint = 0.22;
varying vec3 world_position;
varying vec3 world_normal;

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

// Analytic derivatives of the continuous world-space noise. Screen-space
// height derivatives form seams at the editable mesh's tiny triangle edges;
// this gradient stays identical on both sides of a shared world position.
vec4 noise_gradient_at(vec3 p) {
	vec3 i = floor(p);
	vec3 t = fract(p);
	vec3 f = t * t * (3.0 - 2.0 * t);
	vec3 df = 6.0 * t * (1.0 - t);
	float a = hash_point(i);
	float b = hash_point(i + vec3(1,0,0));
	float c = hash_point(i + vec3(0,1,0));
	float d = hash_point(i + vec3(1,1,0));
	float e = hash_point(i + vec3(0,0,1));
	float f1 = hash_point(i + vec3(1,0,1));
	float g = hash_point(i + vec3(0,1,1));
	float h = hash_point(i + vec3(1,1,1));
	float x00 = mix(a,b,f.x);
	float x10 = mix(c,d,f.x);
	float x01 = mix(e,f1,f.x);
	float x11 = mix(g,h,f.x);
	float lower = mix(x00,x10,f.y);
	float upper = mix(x01,x11,f.y);
	vec3 gradient = vec3(
		mix(mix(b-a,d-c,f.y),mix(f1-e,h-g,f.y),f.z),
		mix(x10-x00,x11-x01,f.z), upper-lower) * df;
	return vec4(mix(lower,upper,f.z),gradient);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
	vec3 p = world_position;
	vec3 n = normalize(world_normal);
	vec3 dpdx = dFdx(p);
	vec3 dpdy = dFdy(p);
	float footprint = max(length(dpdx), length(dpdy));
	float up = smoothstep(0.35, 0.92, n.y);
	float stone = stony ? 1.0 : 0.0;
	vec3 base = grassy ? mix(side_colour.rgb, top_colour.rgb, up) : top_colour.rgb;
	if (world_mesh && blend_materials) {
		base = COLOR.rgb;
		stone = COLOR.a;
	}
	// Incommensurate rotated scales make weathering belong to the landscape,
	// rather than repeating a noisy tile on each metre of ground.
	mat3 rotation = mat3(vec3(0.8,0.0,0.6),vec3(0.18,0.95,-0.24),vec3(-0.57,0.3,0.76));
	vec3 rotated = rotation * p;
	float broad = noise_at(rotated / patch_metres);
	float meadow = noise_at(rotated / (patch_metres * 0.34) + vec3(13.4,6.2,9.1));
	vec4 wear_sample = noise_gradient_at(rotated * 0.62 + vec3(19.3,2.7,3.4));
	float wear = wear_sample.x;
	vec3 wear_gradient = transpose(rotation) * wear_sample.yzw * 0.62;
	vec4 chips_sample = noise_gradient_at(rotated * 3.4 + vec3(wear * 0.35));
	float chips = chips_sample.x;
	vec3 chips_gradient = transpose(rotation) * chips_sample.yzw * 3.4 + wear_gradient * dot(chips_sample.yzw,vec3(0.35));
	float fine_fade = 1.0 - smoothstep(grain_metres * 0.28, grain_metres * 1.25, footprint);
	float grit = 0.0;
	vec3 grit_gradient = vec3(0.0);
	// Distant pixels already contribute exactly zero fine grain. Skip its
	// eight corner hashes and derivative arithmetic once that fade completes.
	if (fine_fade > 0.0) {
		vec4 grit_sample = noise_gradient_at(rotated / grain_metres);
		grit = (grit_sample.x - 0.5) * fine_fade;
		grit_gradient = transpose(rotation) * grit_sample.yzw / grain_metres * fine_fade;
	}
	float patch = smoothstep(0.32, 0.72, broad * 0.68 + meadow * 0.32);
	base *= 1.0 + (patch - 0.5) * colour_variation;
	float exposed = smoothstep(0.48, 0.71, meadow + (wear - 0.5) * 0.26);
	if (grassy) {
		base = mix(base, loam_colour.rgb, exposed * soil_exposure * up);
		float dry = smoothstep(0.57, 0.79, broad + (chips - 0.5) * 0.10);
		base = mix(base, dry_colour.rgb, dry * 0.22 * up);
	}
	// Soft moss collects on upward stone shelves. Bedding is broad, broken
	// weathering, not a dark drawn fracture network or a per-voxel stripe.
	float damp = smoothstep(0.39, 0.65, wear + (meadow - 0.5) * 0.25);
	base = mix(base, moss_colour.rgb, damp * up * stone * stone_moss);
	vec4 bedding_sample = noise_gradient_at(p * vec3(0.7, 4.6, 0.7) + vec3(wear));
	float bedding = bedding_sample.x;
	vec3 bedding_gradient = bedding_sample.yzw * vec3(0.7,4.6,0.7) + wear_gradient * dot(bedding_sample.yzw,vec3(1.0));
	float weather = (wear - 0.5) * 0.28 + (bedding - 0.5) * (1.0 - up) * 0.19;
	float earth_grain = (chips - 0.5) * 0.13 + grit * 0.22;
	base *= 1.0 + mix(earth_grain, weather + grit * 0.15, stone);
	if (augmentation_enabled) {
		float influence = texture(augmentation_map, p.xz / augmentation_extent).r;
		// Host material still carries the biome: mineral flecks and exhausted
		// soil grow near native fractures rather than recolouring whole regions.
		float exposed_trace = influence * smoothstep(0.38, 0.70, wear);
		base = mix(base, base * vec3(0.69, 0.74, 0.68), influence * augmentation_tint);
		base = mix(base, vec3(0.40, 0.40, 0.31), exposed_trace * augmentation_tint * stone);
	}
	ALBEDO = max(base, vec3(0.0));
	ROUGHNESS = clamp(mix(0.96 - damp * 0.07, rock_roughness + (wear - 0.5) * 0.14, stone), 0.58, 1.0);
	SPECULAR = 0.20;
	AO = 1.0 - smoothstep(0.15, 0.54, 1.0 - chips) * 0.12;
	AO_LIGHT_AFFECT = 0.08;
	// Project the continuous relief gradient onto the surface's tangent plane.
	// Pixel derivatives are used only for the distant grain filter above.
	vec3 gradient = (chips_gradient + grit_gradient * 0.65) * bump_height_m;
	gradient += stone * (wear_gradient + bedding_gradient * 0.15) * rock_bump_m;
	vec3 bumped = normalize(n - (gradient - n * dot(n,gradient)));
	NORMAL = normalize((VIEW_MATRIX * vec4(bumped, 0.0)).xyz);
}
