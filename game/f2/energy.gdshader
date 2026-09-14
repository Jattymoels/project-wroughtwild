shader_type spatial;
// Deliberately no TIME: native paid progress is the only travelling-light clock.
uniform vec4 bark_colour : source_color = vec4(0.045,0.07,0.035,1.0);
uniform float winding = 0.0;
uniform float paid_phase = 0.0;
uniform bool travelling = false;
uniform bool emission_off = false;
void fragment() {
	ALBEDO = bark_colour.rgb;
	ROUGHNESS = 0.85;
	float distance_to_pulse = abs(fract(UV.y - paid_phase*3.0)-0.5);
	float pulse = travelling ? (1.0-smoothstep(0.025,0.12,distance_to_pulse))*0.3 : 0.0;
	EMISSION = emission_off ? vec3(0.0) : vec3(0.18,0.26,0.12)*(0.04+winding*0.25+pulse);
}
