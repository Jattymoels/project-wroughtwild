shader_type spatial;
render_mode cull_disabled;
uniform float clock_seconds = 0.0;
uniform float wind_tip_m = 0.018;
uniform float wind_period_seconds = 5.5;
uniform bool textured = false;
uniform bool rooted_wind = true;
uniform int surface_role = 0; // 1 moss, 2 lichen, 4 retained deadfall bark
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic;
varying vec3 local_position;
float hash3(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise3(vec3 p){
    vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
    return mix(mix(mix(hash3(i),hash3(i+vec3(1,0,0)),f.x),mix(hash3(i+vec3(0,1,0)),hash3(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash3(i+vec3(0,0,1)),hash3(i+vec3(1,0,1)),f.x),mix(hash3(i+vec3(0,1,1)),hash3(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex(){
    local_position=VERTEX;
    if(rooted_wind){
        float h=max(VERTEX.y,0.0);
        vec3 origin=MODEL_MATRIX[3].xyz;
        float wave=sin(clock_seconds*6.283185/wind_period_seconds+origin.x*.7+origin.z*.3);
        VERTEX.x+=wind_tip_m*h*wave;
        VERTEX.z+=wind_tip_m*h*.35*cos(clock_seconds*6.283185/wind_period_seconds+origin.x*.7+origin.z*.3);
    }
}
void fragment(){
    if(!FRONT_FACING){NORMAL=-NORMAL;}
    vec3 c=textured ? texture(base_texture,UV).rgb : COLOR.rgb;
    if(!textured){
        float rib=1.0-smoothstep(.005,.032,abs(UV.x-.5));
        float vein=pow(max(0.0,cos((UV.y+abs(UV.x-.5)*.6)*92.0)),16.0);
        c*=.93+.12*rib+.035*vein;
    }
    if(surface_role==1 || surface_role==2){
        float detail=noise3(local_position*380.0);
        float broad=noise3(local_position*38.0);
        c*=.28+.48*broad+.24*detail;
        NORMAL=normalize(NORMAL+vec3(dFdx(detail)*.22,0.0,dFdy(detail)*.22));
    }
    if(surface_role==4){
        float grain=.5+.5*sin(UV.x*68.0+sin(UV.y*62.0)*.6);
        c*=.44+.20*grain+.20*noise3(local_position*60.0);
    }
    ALBEDO=c;ROUGHNESS=.84;METALLIC=0.0;
}
