shader_type spatial;
uniform vec4 base : source_color = vec4(0.4,0.3,0.2,1.0);
uniform vec4 accent : source_color = vec4(0.25,0.2,0.15,1.0);
uniform int pattern = 0;
uniform float spacing = 0.28;
uniform float grain = 38.0;
uniform float roughness = 0.9;
uniform float joint_width = 0.012;
uniform float frame_shade = 1.0;
uniform bool roof = false;
uniform bool object_space = false;
varying vec3 p;
varying vec3 n;
float hash21(vec2 v) { return fract(sin(dot(v,vec2(127.1,311.7)))*43758.5453); }
float noise21(vec2 v) {
	vec2 cell = floor(v);
	vec2 t = fract(v); t = t*t*(3.0-2.0*t);
	return mix(mix(hash21(cell),hash21(cell+vec2(1.0,0.0)),t.x),mix(hash21(cell+vec2(0.0,1.0)),hash21(cell+vec2(1.0)),t.x),t.y);
}
void vertex() {
	p = object_space ? VERTEX : (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	n = object_space ? NORMAL : MODEL_NORMAL_MATRIX*NORMAL;
}
void fragment() {
	vec3 an = abs(normalize(n));
	vec2 uv = an.y>0.7 ? p.xz : (an.x>an.z ? p.zy : p.xy);
	float course = roof ? 0.1666667 : spacing;
	float row = floor(uv.y/course);
	float seam = min(fract(uv.y/course),1.0-fract(uv.y/course))*course;
	float tone = 0.90;
	float mix_amount = 0.0;
	if (pattern==0) {
		float wave = noise21(vec2(uv.x*0.7,row))*2.0;
		float fibre = noise21(vec2(uv.x*1.8,uv.y*grain+wave));
		float fine = noise21(vec2(uv.x*8.0,uv.y*grain*2.4+wave*2.0));
		float knot = exp(-pow(length(vec2(fract(uv.x*0.47+row*0.37)-0.5,(fract(uv.y/course)-0.48)*0.42))*17.0,2.0));
		tone += 0.10*(fibre-0.5)+0.025*(fine-0.5)+0.05*sin(row*2.399)-0.08*knot;
		mix_amount = 0.16*(1.0-fibre)+0.15*knot;
	} else if (pattern==1) {
		vec2 tile = vec2(floor(uv.x/(spacing*2.2)+mod(row,2.0)*0.5),row);
		float cleft = noise21(vec2(uv.x*11.0,uv.y*grain));
		tone = 0.84+0.13*hash21(tile)+0.04*cleft;
		mix_amount = smoothstep(0.70,0.87,cleft)*0.08;
	} else if (pattern==6) {
		vec2 courses = vec2(uv.x/(spacing*2.2)+mod(row,2.0)*0.5,uv.y/course);
		float xjoint = min(fract(courses.x),1.0-fract(courses.x))*spacing*2.2;
		seam = min(seam,xjoint);
		float heat = noise21(uv*3.8);
		tone = 0.83+0.15*hash21(floor(courses))+0.035*noise21(uv*grain);
		mix_amount = smoothstep(0.63,0.89,heat)*0.17;
	} else if (pattern==2 || pattern==3) {
		float xjoint = min(fract(uv.x/(spacing*2.0)+mod(row,2.0)*0.5),1.0-fract(uv.x/(spacing*2.0)+mod(row,2.0)*0.5))*spacing*2.0;
		seam = min(seam,xjoint);
		vec2 tile = floor(vec2(uv.x/(spacing*2.0)+mod(row,2.0)*0.5,uv.y/spacing));
		tone = 0.85+0.18*hash21(tile)+0.02*sin(uv.x*97.0)*sin(uv.y*83.0);
		vec2 shell = fract(uv/spacing)-vec2(0.52,0.47);
		float ring = abs(sin(length(shell)*56.0+atan(shell.y,shell.x)*2.0));
		mix_amount = pattern==2 ? (1.0-smoothstep(0.13,0.28,length(shell)))*pow(ring,5.0)*0.24*step(0.83,hash21(tile)) : 0.08;
	} else if (pattern==4) {
		vec2 weave = uv*grain;
		float over = mod(floor(weave.x)+floor(weave.y),2.0);
		float strand = over>0.5 ? sin(weave.x*6.283) : sin(weave.y*6.283);
		tone = 0.83+strand*0.14;
		mix_amount = over*0.22;
	} else if (pattern==5) {
		float crack = noise21(vec2(uv.x*grain,uv.y*4.0));
		tone = 0.86+0.09*noise21(uv*19.0);
		mix_amount = smoothstep(0.66,0.88,crack)*0.48;
	} else {
		tone = 0.90+0.04*sin(uv.x*18.0+sin(uv.y*13.0));
		mix_amount = 0.12+0.08*sin(uv.x*2.0+uv.y*4.0);
	}
	float joint = joint_width>0.0 ? smoothstep(0.0,max(joint_width,fwidth(seam)),seam) : 1.0;
	ALBEDO = mix(base.rgb,accent.rgb,mix_amount)*tone*mix(0.65,1.0,joint)*frame_shade;
	if (n.y < -0.7) ALBEDO *= 0.77;
	if (roof) ALBEDO *= 0.78+0.13*smoothstep(0.0,0.035,seam);
	ROUGHNESS = roughness;
	SPECULAR = pattern==7 ? 0.7 : 0.25;
}
