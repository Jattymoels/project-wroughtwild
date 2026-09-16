shader_type spatial;
render_mode cull_disabled;
uniform vec3 seam_color:source_color=vec3(.55,.69,.64);
varying vec3 p;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;}
void fragment(){
 float front=fract(TIME*.12-p.y*.08-p.x*.07-p.z*.06);
 float pulse=smoothstep(.82,.93,front)*(1.0-smoothstep(.95,1.0,front));
 ALBEDO=seam_color*.20;EMISSION=seam_color*(.08+pulse*.65);ROUGHNESS=.7;
}
