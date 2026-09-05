shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;
uniform vec4 shot_colour : source_color = vec4(1.0);
uniform float glow_energy = 1.0;

void fragment() {
	// A soft falloff and a hotter centre read as energy in space, rather
	// than a flat, opaque disc hiding the creature's face during its tell.
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float core = pow(facing, 4.0);
	ALBEDO = shot_colour.rgb * mix(0.25, 1.0, core);
	EMISSION = shot_colour.rgb * glow_energy * core;
	ALPHA = smoothstep(0.0, 0.75, facing) * 0.9;
}
