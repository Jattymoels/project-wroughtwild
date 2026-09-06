shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 core_colour : source_color = vec4(0.68, 0.85, 0.95, 1.0);
uniform float emission_energy = 2.4;
uniform float stock_fraction = 1.0;
uniform float work_fraction = 0.0;
uniform float hover_amount = 0.0;
uniform float movement_m = 0.0;
uniform float movement_rate = 0.6;
varying vec3 local_position;
void vertex() {
    local_position = VERTEX;
    float phase = TIME * movement_rate + MODEL_MATRIX[3].x * 0.27 + MODEL_MATRIX[3].z * 0.39;
    VERTEX += vec3(sin(phase + VERTEX.y * 7.0), cos(phase * 0.73 + VERTEX.x * 5.0), sin(phase * 0.61)) * movement_m;
}
void fragment() {
    // Quiet material motion, never a travelling attack, flicker or hazard pulse.
    float breathe = 0.94 + 0.06 * sin(TIME * movement_rate + local_position.y * 1.4);
    float stock = mix(0.32, 1.0, stock_fraction);
    ALBEDO = core_colour.rgb * 0.32;
    EMISSION = core_colour.rgb * emission_energy * stock * breathe * (1.0 + work_fraction * 0.16 + hover_amount * 0.12);
}
