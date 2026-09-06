shader_type spatial;
render_mode cull_disabled;
uniform vec4 water_colour : source_color = vec4(0.13,0.18,0.15,1.0);
uniform float pool_radius = 4.3;
varying vec3 local;
void vertex() { local = VERTEX; }
void fragment() {
    float wave=sin(local.x*2.3+TIME*0.32)*sin(local.z*1.8-TIME*0.19);
    float edge=length(local.xz)/pool_radius;
    float bank=smoothstep(0.77,0.94,edge);
    float ripples=pow(max(0.0,sin(local.x*4.1+local.z*2.7+TIME*0.38)),16.0)*0.09;
    ALBEDO=mix(water_colour.rgb*(0.64+wave*0.08+ripples),vec3(0.085,0.095,0.061),bank);
    ROUGHNESS=mix(0.18+wave*0.035,0.89,bank);
    METALLIC=0.22*(1.0-bank);
    NORMAL=normalize(NORMAL+vec3(cos(local.x*2.3+TIME*0.32)*0.08,0,sin(local.z*1.8-TIME*0.19)*0.06));
}
