// Original image maps, metric directional projection, no displaced vertices.
uniform sampler2D face_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D edge_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D face_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D edge_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D face_orm : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D edge_orm : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 face_repeat;
uniform vec2 edge_repeat;
uniform int family_kind = 0;
uniform vec3 grain_axis = vec3(0,1,0);
uniform vec3 half_size;
uniform bool slab = false;
uniform bool broad_sides = false;
uniform bool roof = false;
uniform int roof_topology = 0;
uniform bool moving_member = false;
uniform bool integral_frame = false;
uniform bool all_edge = false;
uniform bool door = false;
uniform float rail_width = 0.0;
uniform float frame_width;
uniform float shade = 1.0;
uniform float normal_strength;
uniform float frame_shade;
uniform float end_normal_threshold;
uniform float board_width_m;
uniform float board_phase_texels;
uniform float face_resolution_px;
uniform float recess_min_m;
uniform float seam_roughness_add;
uniform float recess_edge_guard_m;
uniform vec2 door_rails_y;
uniform float door_rail_half_width_m;
uniform vec3 seam_tint;
uniform float seam_metallic;
uniform float pane_opacity = 1.0;
uniform float projection_axis_threshold;
uniform float roof_face_min_up;
uniform float alternate_axis_threshold;
uniform float recess_face_threshold;
uniform float inspection_grid_m;
uniform float inspection_line_fraction;
uniform int inspection = 0;
varying vec3 local_p;
varying vec3 local_n;
varying vec3 run_p;

void vertex() {
	local_p = VERTEX;
	local_n = NORMAL;
	// Rotate phase with the actual part while sharing a metric origin along a run.
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 phase = vec3(dot(origin,normalize(MODEL_MATRIX[0].xyz)),dot(origin,normalize(MODEL_MATRIX[1].xyz)),dot(origin,normalize(MODEL_MATRIX[2].xyz)));
	run_p = VERTEX + (moving_member ? vec3(0.0) : phase);
}

void fragment() {
	vec3 n = normalize(local_n);
	vec3 an = abs(n);
	vec3 g = grain_axis;
	vec3 roof_run = vec3(0,0,1);
	if (roof) {
		vec2 along=(local_p.xz/half_size.xz+vec2(1.0))*0.5;
		bool use_x=(roof_topology==1 && along.x<along.y) || (roof_topology==2 && along.x>along.y);
		roof_run=use_x ? vec3(1,0,0) : vec3(0,0,1);
		g=normalize(roof_run+vec3(0,half_size.y/(use_x ? half_size.x : half_size.z),0));
	}
	bool rail = false;
	if (family_kind == 0) {
		if (rail_width > 0.0 && abs(local_p.y) > half_size.y-rail_width) rail=true;
		if (door && min(abs(local_p.y-door_rails_y.x),abs(local_p.y-door_rails_y.y)) < door_rail_half_width_m) rail=true;
		if (integral_frame && abs(local_p.y) > half_size.y-frame_width && abs(local_p.x) < half_size.x-frame_width) rail=true;
		if (rail) g=vec3(1,0,0);
	}
	vec3 plane_n=n;
	// Stable broad planes: normal microrelief never chooses another texture role.
	if (an.y > projection_axis_threshold) plane_n=vec3(0,sign(n.y),0);
	else if (an.z > projection_axis_threshold) plane_n=vec3(0,0,sign(n.z));
	else if (an.x > projection_axis_threshold) plane_n=vec3(sign(n.x),0,0);
	if (roof && n.y > roof_face_min_up) {
		// UVs use the unchanged ideal plane, not each small relief triangle.
		plane_n=normalize(an.z>=an.x ? vec3(0,1,sign(n.z)*half_size.y/half_size.z) : vec3(sign(n.x)*half_size.y/half_size.x,1,0));
		g = normalize(vec3(0,1,0)-plane_n*plane_n.y);
	}
	bool cut=all_edge;
	if (family_kind==0) {
		cut=cut || (roof && n.y<=roof_face_min_up ? abs(dot(plane_n,roof_run)) : abs(dot(plane_n,g))) > end_normal_threshold;
	}
	else if (!all_edge) {
		if (roof) cut=n.y < roof_face_min_up;
		else if (slab) cut=an.y < end_normal_threshold;
		else if (broad_sides) cut=an.y > end_normal_threshold;
		else cut=an.z < end_normal_threshold;
	}
	vec3 v=g;
	if (family_kind!=0) {
		v=vec3(0,1,0);
		if (slab && an.y > end_normal_threshold) v=vec3(0,0,1);
		if (roof && n.y > roof_face_min_up) v=g;
	}
	if (abs(dot(v,plane_n)) > end_normal_threshold) {
		v=abs(plane_n.z)<alternate_axis_threshold ? vec3(0,0,1) : vec3(0,1,0);
	}
	v=normalize(v-plane_n*dot(v,plane_n));
	vec3 u=normalize(cross(v,plane_n));
	vec2 metres=vec2(dot(run_p,u),dot(run_p,v));
	vec2 repeat_m=cut ? edge_repeat : face_repeat;
	vec2 tex_uv=metres/repeat_m;
	// One phase per quarter-metre board, stable across full/half pieces and joins.
	if (family_kind==0 && !cut && !rail && grain_axis.x<0.5) {
		tex_uv.y += mod(floor(metres.x/board_width_m)*board_phase_texels,face_resolution_px)/face_resolution_px;
	}
	vec3 colour;
	vec3 bump;
	vec3 orm;
	if (cut) {
		colour=texture(edge_albedo,tex_uv).rgb;
		bump=texture(edge_normal,tex_uv).rgb*2.0-1.0;
		orm=texture(edge_orm,tex_uv).rgb;
	} else {
		colour=texture(face_albedo,tex_uv).rgb;
		bump=texture(face_normal,tex_uv).rgb*2.0-1.0;
		orm=texture(face_orm,tex_uv).rgb;
	}
	float protected_seam=0.0;
	if (family_kind==2 && !roof) {
		float recess=half_size.z-abs(local_p.z);
		float margin=min(half_size.x-abs(local_p.x),half_size.y-abs(local_p.y));
		protected_seam=step(recess_min_m,recess)*step(recess_edge_guard_m,margin)*step(recess_face_threshold,an.z);
	}
	ALBEDO=colour*shade*(rail && !integral_frame ? frame_shade : 1.0)*mix(vec3(1.0),seam_tint,protected_seam);
	ROUGHNESS=clamp(orm.g+protected_seam*seam_roughness_add,0.0,1.0);
	METALLIC=family_kind==2 ? orm.b*mix(1.0,seam_metallic,protected_seam) : 0.0;
	// Right-handed U/V frame on both sides, transformed with the retained mesh.
	vec3 mapped=normalize(n*bump.z+u*bump.x*normal_strength+v*bump.y*normal_strength);
	NORMAL=normalize(mat3(VIEW_MATRIX)*MODEL_NORMAL_MATRIX*mapped);
	if (inspection==1) {
		vec2 grid=abs(fract(metres/inspection_grid_m+0.5)-0.5);
		ALBEDO=mix(cut ? vec3(0.1,0.5,0.8) : vec3(0.65,0.35,0.12),vec3(0.9),1.0-step(inspection_line_fraction,min(grid.x,grid.y)));
	}
#ifdef GLASS_PANE
	ALPHA=pane_opacity;
#endif
}
