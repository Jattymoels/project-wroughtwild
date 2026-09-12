shader_type spatial;
render_mode cull_back;
uniform float remaining = 0.0;
uniform float native_seconds = 0.0;
uniform float heat = 1.0;
uniform float gain = 2.0;
void fragment() {
 float alive = step(0.00001,remaining);
 float wave = 0.73+0.27*sin(native_seconds*4.0+UV.x*14.0+UV.y*5.0);
 float fade = smoothstep(0.0,0.18,remaining);
 vec3 colour = mix(vec3(1.0,0.16,0.018),vec3(1.0,0.40,0.07),clamp(heat-1.0,0.0,1.0));
 ALBEDO = vec3(0.035,0.013,0.006);
 EMISSION = colour*gain*wave*fade*alive;
 ROUGHNESS = 0.93;
}
