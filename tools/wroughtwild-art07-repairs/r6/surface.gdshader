shader_type spatial;
render_mode cull_back;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_map : filter_linear_mipmap_anisotropic;
uniform sampler2D source_fields : filter_linear, repeat_disable;
uniform vec3 host_tint = vec3(1.0);
uniform vec3 mineral_colour = vec3(0.5);
uniform float mineral_roughness = 0.8;
uniform float mineral_metallic = 0.1;
uniform vec3 state_emission = vec3(0.0);
uniform vec3 tint = vec3(1.0);
uniform float remaining_fraction = 1.0;
uniform bool native_cracked = false;
uniform bool heat_active = false;
uniform bool along_x = true;
uniform int ore_kind = 0;
uniform float clock_seconds = 0.0;
uniform float grain_repeats_m;
uniform float normal_detail_m;
uniform float stock_transition_m;
uniform float spent_tint;
uniform float pulse_period_s;
varying vec3 local_position;
varying vec3 local_normal;
void vertex() { local_position = VERTEX; local_normal = NORMAL; }
void fragment() {
    vec3 axis = pow(abs(normalize(local_normal)), vec3(4.0));
    axis /= max(axis.x + axis.y + axis.z, 0.001);
    vec3 p = local_position * grain_repeats_m;
    vec3 stone = texture(albedo_map,p.zy).rgb*axis.x + texture(albedo_map,p.xz).rgb*axis.y + texture(albedo_map,p.xy).rgb*axis.z;
    vec3 orm = texture(orm_map,p.zy).rgb*axis.x + texture(orm_map,p.xz).rgb*axis.y + texture(orm_map,p.xy).rgb*axis.z;
    float u = along_x ? local_position.x : -local_position.z;
    float v = along_x ? local_position.z : local_position.x;
    // Original C5 mesh fields projected vertically in source space. Texture
    // coordinates only adapt the material; the native ribbon is never displaced.
    float row = float(ore_kind*2)+(native_cracked ? 1.0 : 0.0);
    vec2 field_uv = vec2(clamp(u/3.0+0.5,0.001,0.999),(row+clamp(v/0.48+0.5,0.004,0.996))/10.0);
    vec4 source = texture(source_fields,field_uv);
    float mineral = source.r*source.a;
    float boundary = -1.5+3.0*remaining_fraction;
    float stock = 1.0-smoothstep(boundary-stock_transition_m,boundary,u);
    if (remaining_fraction >= 1.0) stock = 1.0;
    if (remaining_fraction <= 0.0) stock = 0.0;
    mineral *= stock;
    vec3 rock = stone*host_tint*mix(spent_tint,1.0,stock);
    float fracture = source.g*source.a;
    ALBEDO = mix(rock,mineral_colour*(0.55+stone.r*1.8),mineral*0.88)*tint*(1.0-fracture*0.72);
    ROUGHNESS = mix(clamp(orm.g,0.7,1.0),mineral_roughness,mineral);
    METALLIC = mineral_metallic*mineral;
    vec3 dp1 = dFdx(VERTEX), dp2 = dFdy(VERTEX);
    vec3 r1 = cross(dp2,NORMAL), r2 = cross(NORMAL,dp1);
    float det = dot(dp1,r1);
    vec3 gradient = (r1*dFdx(stone.r)+r2*dFdy(stone.r))*sign(det)/max(abs(det),0.00000001);
    NORMAL = normalize(NORMAL-normal_detail_m*gradient);
    EMISSION = state_emission*mix(0.10,0.40,mineral);
    if (heat_active) EMISSION += vec3(1.0,0.18,0.018)*fracture*stock*(0.65+0.35*sin(clock_seconds/pulse_period_s*6.2831853-u*0.35))*0.65;
}
