// Lab material: understated joinery lines, stable in world space after reload.
shader_type spatial;
render_mode specular_disabled;
uniform vec4 timber : source_color = vec4(0.43, 0.30, 0.17, 1.0);
// Board width in metres; seam width controls how strongly joints read at eye level.
uniform float board_width = 0.28;
uniform float seam_width = 0.012;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}
void fragment() {
	vec3 n = abs(normalize(world_normal));
	float across = n.y > 0.7 ? world_position.x : world_position.y;
	float along = n.y > 0.7 ? world_position.z : world_position.x + world_position.z;
	float joint = min(fract(across/board_width),1.0-fract(across/board_width))*board_width;
	float seam = smoothstep(0.0,seam_width,joint);
	float board = floor(across/board_width);
	float variation = 0.03*sin(board*2.399) + 0.015*sin(along*9.0 + sin(across*38.0));
	ALBEDO = timber.rgb * (0.84 + variation) * mix(0.7,1.0,seam);
	ROUGHNESS = 1.0;
}
