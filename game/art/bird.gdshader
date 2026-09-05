shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform float wingbeat_hz = 1.2;
uniform float wing_lift = 0.22;
instance uniform float phase = 0.0;
void vertex() {
	VERTEX.y += sin(TIME*6.283185*wingbeat_hz+phase) * UV.x * wing_lift;
}
void fragment() {
	ALBEDO = vec3(0.045,0.042,0.035);
	ROUGHNESS = 1.0;
}
