shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec3 state_emission = vec3(0.0);
uniform float glow = 0.0;
uniform float movement = 0.0;
uniform float movement_rate = 0.65;
uniform float breathing = 0.0;
varying vec3 local;
float grain(vec3 p) { return fract(sin(dot(p,vec3(17.37,31.19,9.71)))*4177.23); }
void vertex() {
    local = VERTEX;
    float phase = TIME*movement_rate + MODEL_MATRIX[3].x*0.37 + MODEL_MATRIX[3].z*0.53;
    VERTEX.x += sin(phase+VERTEX.y*1.9)*movement*smoothstep(0.1,0.8,VERTEX.y);
    VERTEX.xz *= 1.0+sin(phase)*breathing*smoothstep(0.1,0.6,VERTEX.y);
}
void fragment() {
    float fleck = grain(floor(local*45.0));
    float fibres = sin(local.y*3.3+sin(local.x*49.0+local.z*33.0)*1.4);
    vec3 colour = COLOR.rgb*tint.rgb;
    ALBEDO = colour*(0.94+fleck*0.08+fibres*0.035);
    ROUGHNESS = 0.86+fleck*0.12;
    if (!FRONT_FACING) NORMAL = -NORMAL;
    EMISSION = state_emission+colour*glow*(0.96+0.04*sin(TIME*0.7));
}
