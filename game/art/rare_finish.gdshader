shader_type spatial;
render_mode cull_disabled;

uniform vec4 host_colour : source_color = vec4(0.4, 0.36, 0.28, 1.0);
uniform vec4 tint : source_color = vec4(1.0);
uniform vec3 state_emission = vec3(0.0);
uniform float grain_scale = 18.0;
uniform float grain_strength = 0.22;
uniform float host_roughness = 0.9;
uniform int host_mode = 0;
uniform float movement = 0.0;
uniform float movement_rate = 0.55;
uniform bool cavity_open = false;
uniform float cavity_half_width = 0.7;
uniform float cavity_height = 1.25;
uniform float cavity_front_start = 0.05;
uniform float cavity_raggedness = 0.14;
varying vec3 local_position;

float hash3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise3(vec3 p) {
    vec3 cell = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash3(cell), hash3(cell + vec3(1,0,0)), f.x),
                   mix(hash3(cell + vec3(0,1,0)), hash3(cell + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash3(cell + vec3(0,0,1)), hash3(cell + vec3(1,0,1)), f.x),
                   mix(hash3(cell + vec3(0,1,1)), hash3(cell + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() {
    local_position = VERTEX;
    float phase = TIME * movement_rate + MODEL_MATRIX[3].x * 0.31 + MODEL_MATRIX[3].z * 0.43;
    VERTEX.xz += NORMAL.xz * sin(phase + VERTEX.y * 2.0) * movement * smoothstep(0.05, 0.7, VERTEX.y);
}
void fragment() {
    vec3 p = local_position;
    if (cavity_open) {
        float ragged = (noise3(p * 7.0) - 0.5) * cavity_raggedness;
        float mouth_width = cavity_half_width * (1.0 - 0.24 * smoothstep(0.5, cavity_height, p.y)) + ragged;
        float mouth_top = cavity_height - pow(abs(p.x) / cavity_half_width, 1.7) * 0.25 + ragged;
        if (p.z > cavity_front_start + ragged && abs(p.x) < mouth_width && p.y > 0.06 && p.y < mouth_top) discard;
    }
    vec3 grain_position = p * grain_scale;
    if (host_mode == 0) grain_position *= vec3(0.18, 1.0, 1.0);
    if (host_mode == 3 || host_mode == 4) grain_position *= vec3(1.0, 0.24, 1.0);
    float coarse = noise3(grain_position * 0.27);
    float fine = noise3(grain_position);
    float furrow = smoothstep(0.58, 0.78, fine * 0.7 + coarse * 0.3);
    float bedding = sin(p.y * grain_scale * 0.8 + coarse * 3.5) * 0.045;
    vec3 authored = clamp(COLOR.rgb, vec3(0.0), vec3(1.0));
    float authored_value = dot(authored, vec3(0.2126,0.7152,0.0722));
    vec3 colour = host_colour.rgb * (0.72 + authored_value * 0.48);
    colour *= 0.96 + grain_strength * (fine - 0.5) - furrow * grain_strength + bedding;
    ALBEDO = colour * tint.rgb;
    ROUGHNESS = clamp(host_roughness + fine * 0.12, 0.3, 1.0);
    METALLIC = host_mode == 2 ? 0.28 : 0.0;
    if (!FRONT_FACING) NORMAL = -NORMAL;
    // Smooth analytic noise supplies close grain without screen-space speckling.
    vec3 slope = vec3(dFdx(fine), dFdy(fine), 0.0);
    NORMAL = normalize(NORMAL - slope * grain_strength * 0.28);
    EMISSION = state_emission;
}
