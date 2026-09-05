shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never;

uniform vec4 tint : source_color = vec4(0.65, 0.74, 0.72, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.16;

void fragment() {
	// Feather the silhouette of a smooth shell to suggest dilute vapour.
	float facing = max(dot(normalize(NORMAL), normalize(VIEW)), 0.0);
	ALBEDO = tint.rgb;
	ALPHA = opacity * pow(facing, 1.6);
}
