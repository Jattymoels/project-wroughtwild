shader_type spatial;
render_mode cull_disabled;
// No TIME. Only a paid local completion or the actual reserved feeder clock.
uniform float work_amount = 0.0;
uniform float native_phase = 0.0;
uniform float scar_gain = 3.0;
uniform float scar_wave_per_m = 17.0;
varying float height;
void vertex() { height = VERTEX.y; }
void fragment() {
    ALBEDO = vec3(.025,.013,.006);
    ROUGHNESS = .94;
    float front = .65 + .35 * sin(height * scar_wave_per_m - native_phase * 6.283185);
    EMISSION = vec3(1.0,.23,.025) * (scar_gain * work_amount * front);
}
