shader_type spatial;
uniform float scar_clock=0.0;
varying vec3 pos;
void vertex(){pos=VERTEX;}
void fragment(){
    float wave=sin(pos.x*4.5+pos.z*7.0+scar_clock*.55)*.5+sin(pos.z*13.0-pos.x*3.0+scar_clock*.8)*.22;
    ALBEDO=mix(vec3(.045,.095,.105),vec3(.13,.20,.22),wave*.15+.2);
    ROUGHNESS=.19;
    METALLIC=.35;
    NORMAL_MAP=vec3(.5+cos(pos.z*7.0+scar_clock*.55)*.045,.5+sin(pos.x*5.0+scar_clock*.7)*.04,1.0);
}
