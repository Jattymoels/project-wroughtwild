extends "res://scripts/sandpit.gd"
func _ready():
    world_seed=77
    world_profile="living_frontier_wave3"
    _build_world(world_seed)
    player.class_panel.choose("warden")
    for a in [player,player.placement,player.combat,mob_packs]: a.set_physics_process(false)
    mob_packs.set_process(false)
    probe.call_deferred()
func probe():
    var h:Dictionary=terrain.map.frontier_hosts[0]
    var route:PackedVector3Array=h.source_route
    for i in range(0,route.size(),20): terrain.ensure_area(route[i],30)
    await get_tree().physics_frame
    await get_tree().physics_frame
    var out={"source":_sim().leyline_sources()[0],"host":{},"route":[],"resources":[],"ruins":[],"collider":{}}
    for k in ["id","enemy_id","position"]:out.host[k]=h[k]
    for p in route: out.route.append([p.x,p.y,p.z])
    for n in get_tree().get_nodes_in_group("resources"):
        var d=99999.0
        for p in route:d=minf(d,Vector2(p.x,p.z).distance_to(Vector2(n.global_position.x,n.global_position.z)))
        if d>24:continue
        var mesh=n.get_node_or_null("MeshInstance3D")
        var col=n.get_node_or_null("CollisionShape3D")
        out.resources.append({"id":n.resource_id,"visual":n.visual,"pos":n.global_position,"distance":d,"aabb":str(mesh.get_aabb()) if mesh else "none","mesh_transform":str(mesh.transform) if mesh else "none","collider":str(col.shape) if col else "none"})
    for r in terrain.map.ruins:out.ruins.append({"id":r.id,"pos":[r.x,r.y,r.z],"kind":r.kind})
    var f=FileAccess.open("res://../footprint.json",FileAccess.WRITE)
    f.store_string(JSON.stringify(out,"  "))
    print("ART05_FOOTPRINT_OK ",out.resources.size())
    get_tree().quit()
