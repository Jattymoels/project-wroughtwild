shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_map : filter_linear_mipmap_anisotropic;
uniform bool textured = false;
uniform bool has_orm = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform float roughness = 0.9;
uniform float metallic = 0.0;
uniform bool scarred = false;
uniform bool light_enabled = true;
uniform float clock_seconds = 0.0;
uniform float period_s = 4.5;
uniform float peak = 1.6;
void fragment() {
    if (!FRONT_FACING) NORMAL = -NORMAL;
    vec3 base = textured ? texture(albedo_map, UV).rgb * tint.rgb : tint.rgb;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    if (has_orm) {vec3 mr = texture(orm_map, UV).rgb; ROUGHNESS = max(0.65, mr.g); METALLIC = mr.b;}
    float damage = scarred ? clamp(COLOR.r, 0.0, 1.0) : 0.0;
    base = mix(base, vec3(0.008, 0.013, 0.014), damage);
    float phase = fract(clock_seconds / period_s - COLOR.b * 0.35);
    float crest = exp(-pow(min(phase, 1.0-phase)/0.17, 2.0));
    EMISSION = scarred && light_enabled ? vec3(0.68,0.88,1.0)*pow(damage,5.0)*peak*mix(0.12,1.0,crest) : vec3(0.0);
    ALBEDO = base;
}
