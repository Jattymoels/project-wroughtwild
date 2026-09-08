shader_type spatial;
render_mode blend_add, depth_draw_never, unshaded, cull_disabled;
uniform sampler2D scar_mask : source_color;
uniform vec4 scar_colour : source_color = vec4(1.0, 0.2, 0.04, 1.0);
uniform float strength = 0.5;
void fragment() {
    vec3 sample_value = texture(scar_mask, UV).rgb;
    float mask = max(sample_value.r, max(sample_value.g, sample_value.b));
    ALBEDO = scar_colour.rgb * strength;
    ALPHA = mask;
}
