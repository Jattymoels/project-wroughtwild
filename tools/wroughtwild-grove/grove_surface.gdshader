shader_type spatial;
render_mode cull_disabled;
uniform int host = 0; // 0 bark, 1 mineral, 2 soil, 3 leaf
uniform float scar_clock = 0.0;
uniform float period_seconds = 4.0;
uniform float peak_emission = 2.8;
uniform float minimum_light = 0.22;
uniform bool light_enabled = true;
uniform sampler2D floor_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 place;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
    vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
    return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() { place=VERTEX; }
void fragment() {
    if(!FRONT_FACING){ NORMAL=-NORMAL; }
    float coarse=noise(place*5.0),fine=noise(place*65.0);
    float relief=coarse*.5+fine*.5;
    vec3 base=COLOR.rgb*(.74+relief*.52);
    if(host==0) {
        float grain=sin(UV.x*65.0+sin(UV.y*60.0)*.6)*.5+.5;
        base*=.78+.22*grain;
    }
    if(host==2) {
        vec2 uv=place.xz*.5;
        vec3 litter=texture(floor_texture,uv).rgb;
        vec3 offset_litter=texture(floor_texture,vec2(-uv.y,uv.x)+vec2(.37,.61)).rgb;
        litter=mix(litter,offset_litter,smoothstep(.30,.70,noise(place*.31)));
        float trail=smoothstep(.14,.18,COLOR.r);
        base=litter*mix(vec3(.73,1.02,.50),vec3(1.08,1.02,.92),trail);
    }
    if(host==3) {
        float midrib=1.0-smoothstep(.008,.035,abs(UV.x-.5));
        float veins=pow(max(0.0,cos((UV.y+abs(UV.x-.5)*.65)*75.0)),18.0);
        base*=.96+.14*midrib+.06*veins;
        BACKLIGHT=base*.35;
    }
    float damage=UV2.y;
    ALBEDO=mix(base,vec3(.017,.012,.008),damage*.92);
    ROUGHNESS=host==3 ? .69 : .93;
    METALLIC=0.0;
    float phase=fract(scar_clock/period_seconds-UV.y*.55);
    float distance_to_crest=min(phase,1.0-phase);
    float crest=exp(-pow(distance_to_crest/.17,2.0));
    EMISSION=light_enabled ? vec3(1.0,.12,.012)*UV2.x*peak_emission*mix(minimum_light,1.0,crest) : vec3(0.0);
}
