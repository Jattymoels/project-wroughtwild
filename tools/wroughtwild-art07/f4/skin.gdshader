shader_type spatial;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D orm_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool root_tissue = false;
uniform float stock = 0.0;
uniform float work = 0.0;
uniform float phase = 0.0;
uniform float stored_glow = 0.12;
uniform float working_glow = 0.65;
uniform float wave_per_route = 12.0;
uniform bool emission_off = false;
void fragment() {
 vec3 base = texture(albedo_map, UV).rgb;
 vec3 orm = texture(orm_map, UV).rgb;
 float route = root_tissue ? UV.y : COLOR.b;
 float mask = root_tissue ? 1.0 : COLOR.g;
 ALBEDO = root_tissue ? vec3(.045,.07,.035) : base * mix(vec3(1.0),vec3(.10,.075,.055),COLOR.r);
 ROUGHNESS = root_tissue ? .85 : max(.32,orm.g);
 METALLIC = root_tissue ? 0.0 : orm.b;
 float wave = pow(.5+.5*cos(route*wave_per_route-phase*8.0),3.0);
 EMISSION = emission_off ? vec3(0.0) : vec3(.65,.51,.26)*mask*(stock*stored_glow+work*working_glow*wave);
}
