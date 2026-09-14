shader_type spatial;
render_mode cull_back;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D orm_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform float burned = 0.0;
uniform float normal_strength = 0.45;
void fragment() {
 vec3 base = texture(albedo_map,UV).rgb;
 float soot = smoothstep(0.03,0.78,burned);
 ALBEDO = mix(base,vec3(0.022,0.017,0.013),soot*0.94);
 ALBEDO = mix(ALBEDO,vec3(0.24,0.225,0.205),smoothstep(0.78,1.0,burned)*0.65);
 NORMAL_MAP = texture(normal_map,UV).rgb;
 NORMAL_MAP_DEPTH = normal_strength;
 ROUGHNESS = max(texture(orm_map,UV).g,soot*0.90);
}
