shader_type spatial;
render_mode cull_disabled;
uniform vec4 water_colour : source_color = vec4(0.27,0.35,0.33,1.0);
varying vec3 world;
void vertex() { world = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float ripple = sin(world.x*17.0+TIME*0.8)*sin(world.z*14.0-TIME*0.55);
	ALBEDO = water_colour.rgb*(0.94+0.035*ripple);
	ROUGHNESS = 0.30+0.06*ripple;
	SPECULAR = 0.75;
}
