// Seeded direction aligns bedding between native slopes, distant terrain and kit.
uniform bool land02_enabled=false;
uniform vec2 land02_centre=vec2(0.0);
uniform vec2 land02_direction=vec2(1.0,0.0);
uniform float land02_level=30.0;
uniform vec3 land02_scar=vec3(0.0);
uniform vec2 land02_cut_size=vec2(7.0,26.0);
void land02_surface(vec3 p,vec3 n,inout vec3 colour){
 if(!land02_enabled)return;
 vec2 q=p.xz-land02_centre;
 float u=dot(q,land02_direction);
 float v=dot(q,vec2(-land02_direction.y,land02_direction.x));
 float influence=(1.0-smoothstep(135.0,175.0,length(q)))*smoothstep(25.0,46.0,u);
 float rock=influence*smoothstep(land02_level+7.0,land02_level+12.0,p.y)*(1.0-smoothstep(.66,.94,n.y));
 vec2 cut=p.xz-land02_scar.xz;
 float cut_u=abs(dot(cut,land02_direction));
 float cut_v=abs(dot(cut,vec2(-land02_direction.y,land02_direction.x)));
 float recess=(1.0-smoothstep(land02_cut_size.x*.5,land02_cut_size.x*.5+1.6,cut_u))*(1.0-smoothstep(land02_cut_size.y*.5,land02_cut_size.y*.5+1.6,cut_v));
 rock=max(rock,recess);
 float wave=p.y*.58-u*.13+sin(v*.063)*.16;
 float band=fract(wave);
 float joint=1.0-smoothstep(.02,.10,min(band,1.0-band));
 float speckle=sin(p.x*17.3+p.z*19.7)*sin(p.y*12.0+p.x*9.4);
 vec3 mineral=mix(vec3(.24,.255,.215),vec3(.35,.34,.275),smoothstep(.1,.85,band));
 mineral=mix(mineral,vec3(.10,.135,.125),recess*(1.0-smoothstep(land02_scar.y+.3,land02_scar.y+2.2,p.y)));
 mineral*=1.0-joint*.38+speckle*.06;
 colour=mix(colour,mineral,rock*.92);
}
