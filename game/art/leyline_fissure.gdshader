shader_type spatial;
render_mode cull_disabled;

uniform float emission_strength = 1.25;
uniform float light_variation = 0.025;
uniform float light_period_seconds = 47.0;
uniform float mineral_roughness = 0.91;
uniform float grain_cells_per_m = 28.0;
uniform float grain_contrast = 0.13;
varying vec3 world_position;

float grain(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Vertex alpha is contained-light strength, never transparency. One opaque
	// surface gives the dark mouth reliable depth and avoids stacked glow cards.
	float fleck = grain(floor(world_position * grain_cells_per_m));
	// Average subpixel flecks to their base colour rather than letting the
	// quantised mineral grain sparkle as the player walks past a distant seam.
	float coverage = length(fwidth(world_position)) * grain_cells_per_m;
	float detail = 1.0 - smoothstep(0.45, 1.1, coverage);
	vec3 mineral = pow(COLOR.rgb, vec3(2.2));
	ALBEDO = mineral * (1.0 + (fleck - 0.5) * 2.0 * grain_contrast * detail);
	ROUGHNESS = mineral_roughness;
	SPECULAR = 0.18;
	float quiet = 1.0 + light_variation * sin(TIME * 6.283185 / light_period_seconds + UV.y);
	EMISSION = mineral * COLOR.a * emission_strength * quiet;
}
