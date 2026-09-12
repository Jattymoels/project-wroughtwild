shader_type spatial;
render_mode cull_back;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D orm_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 energy_colour = vec3(1.0,.56,.16);
uniform float work = 0.0;
uniform float phase = 0.0;
uniform vec3 tint = vec3(1.0);
uniform vec3 state_emission = vec3(0.0);
void fragment() {
 vec4 base = texture(albedo_map, UV);
 vec3 orm = texture(orm_map, UV).rgb;
 ALBEDO = base.rgb * mix(vec3(1.0), vec3(.10,.075,.055), COLOR.r) * tint;
 ROUGHNESS = max(.32, orm.g);
 METALLIC = orm.b;
 float travel = .30 + .70 * pow(.5 + .5 * cos(COLOR.b * 12.0 - phase * 8.0), 3.0);
 EMISSION = energy_colour * COLOR.g * work * travel + state_emission * .10;
}
