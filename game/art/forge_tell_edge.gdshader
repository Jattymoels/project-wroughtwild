shader_type spatial;
render_mode unshaded, cull_disabled;

// The whole boundary stays visible. Only its warm progress colour advances;
// no expanding shape suggests that part of the warned footprint is safe.
uniform vec4 warning_colour : source_color;
uniform vec4 progress_colour : source_color;
uniform vec4 active_colour : source_color;
uniform float warning_progress : hint_range(0.0, 1.0) = 0.0;
uniform bool active = false;

void fragment() {
	vec3 ink = UV.x <= warning_progress ? progress_colour.rgb : warning_colour.rgb;
	ALBEDO = active ? active_colour.rgb : ink;
}
