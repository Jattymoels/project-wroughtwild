// Shared V10 mineral PBR. Large joints are geometry, never painted bands.
uniform bool land02b_enabled=false;
uniform bool land02b_distant=false;
varying flat vec2 land02b_owner_uv;
uniform sampler2D land02b_detail_mask:filter_nearest,repeat_disable;
uniform vec2 land02b_world_size=vec2(1024.0);
uniform vec3 land02b_scar=vec3(0);
uniform vec2 land02b_direction=vec2(1,0);
uniform float land02b_emission=1.0;
uniform sampler2D land02b_rock_albedo:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
vec4 land02b_sample(vec2 uv){
 vec3 c=texture(land02b_rock_albedo,uv).rgb;
 return vec4(c,dot(c,vec3(.333)));
}
void land02b_surface(vec3 p,vec3 n,float stone,inout vec3 colour,inout vec3 gradient,inout float roughness,inout vec3 emission){
 if(!land02b_enabled)return;
 if(land02b_distant && texture(land02b_detail_mask,land02b_owner_uv).r>.5)discard;
 vec3 w=pow(abs(n),vec3(5));w/=max(dot(w,vec3(1)),.001);
 vec2 ux=p.zy*.115,uy=p.xz*.115,uz=p.xy*.115;
 vec4 tx=land02b_sample(ux),ty=land02b_sample(uy),tz=land02b_sample(uz);
 vec3 mineral=tx.rgb*w.x+ty.rgb*w.y+tz.rgb*w.z;
 float face=1.-smoothstep(.65,.88,n.y);
 float rock=max(stone,face*.88);
 float macro=sin(p.x*.11+sin(p.z*.08))*sin(p.y*.21+p.z*.063)*.5+.5;
 mineral=mix(vec3(.28,.30,.28),mineral*.65,.55)*mix(.66,1.04,macro);
 colour=mix(colour,mineral,rock*.93);
 // Small mineral relief from neutral surface values; one texel-scale finite
 // difference is filtered by the same mip selection as the colour.
 vec2 ex=vec2(.002,0),ey=vec2(0,.002);
 vec2 gx=vec2(land02b_sample(ux+ex).a-tx.a,land02b_sample(ux+ey).a-tx.a);
 vec2 gy=vec2(land02b_sample(uy+ex).a-ty.a,land02b_sample(uy+ey).a-ty.a);
 vec2 gz=vec2(land02b_sample(uz+ex).a-tz.a,land02b_sample(uz+ey).a-tz.a);
 gradient=mix(gradient,vec3(0),rock*.85);
 gradient+=rock*.55*(vec3(0,gx.y,gx.x)*w.x+vec3(gy.x,0,gy.y)*w.y+vec3(gz.x,gz.y,0)*w.z);
 roughness=mix(roughness,.79+macro*.12,rock);
 vec2 q=p.xz-land02b_scar.xz;
 float v=dot(q,vec2(-land02b_direction.y,land02b_direction.x));
 float u=dot(q,land02b_direction);
 float line=.24*sin(v*1.2)+.38*sin(v*.43)+.22*sin(v*1.07);
 float edge=smoothstep(.20,.42,abs(u-line))*(1.-smoothstep(.73,.94,abs(u-line)));
 float pockets=smoothstep(.30,.72,sin(v*2.6+sin(v*.7)));
 float deep=edge*pockets*(1.-smoothstep(5.2,6.5,abs(v)))*(1.-smoothstep(land02b_scar.y+.25,land02b_scar.y+.75,p.y));
 float pulse=.28+.72*pow(.5+.5*sin(v*.8-TIME*1.3),5.);
 emission+=vec3(.66,.83,1.)*deep*pulse*land02b_emission*.38;
}
