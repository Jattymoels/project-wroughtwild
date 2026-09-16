shader_type spatial;
// Fracture faces use the same two-sided contact convention as the native trimesh.
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;
#include "res://art/wildland_terrain_body.gdshaderinc"
