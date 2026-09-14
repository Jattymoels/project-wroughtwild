class_name G1Materials
extends RefCounted
## Production construction materials use the repaired R3 family projection.
static func material_for(family: String, role: String) -> Material:
	return R3Materials.material_for(family, role)
