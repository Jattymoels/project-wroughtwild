shader_type spatial;
render_mode cull_disabled;
uniform float wind_metres = 0.035;
uniform float wind_rate = 0.85;
uniform float root_height = 1.0;
uniform bool linear_colours = false;
uniform vec4 tint : source_color = vec4(1.0);
// The same gathering state as the non-moving resource material.
uniform vec3 state_emission = vec3(0.0);
// Leaves transmit a small amount of skylight rather than showing black backs.
varying float leaf_weight;
void vertex() {
	vec3 world = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	float weight = smoothstep(root_height,root_height+1.8,VERTEX.y);
	leaf_weight = weight;
	VERTEX.x += sin(TIME*wind_rate+world.x*0.73+world.z*0.42)*wind_metres*weight;
}
void fragment() {
	vec3 colour = COLOR.rgb;
	if (!linear_colours) colour = mix(colour/12.92,pow((colour+0.055)/1.055,vec3(2.4)),step(vec3(0.04045),colour));
	ALBEDO = colour*tint.rgb;
	if (!FRONT_FACING) NORMAL = -NORMAL;
	ROUGHNESS = 0.94;
	EMISSION = state_emission+colour*tint.rgb*leaf_weight*0.20;
}
