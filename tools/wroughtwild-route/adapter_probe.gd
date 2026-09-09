extends "res://art05/probe.gd"
var art:Node
func probe():
    art=load("res://art05/route_art.gd").new();add_child(art);art.setup(self)
    var h:Dictionary=terrain.map.frontier_hosts[0]
    terrain.ensure_area(h.position,30)
    player.global_position=h.position+Vector3(8,1.2,8)
    for pack in mob_packs.packs:
        if pack.get("frontier_host_id","")==h.id:mob_packs._spawn_pack(pack,mob_packs.pack_position(pack))
    await get_tree().process_frame
    await get_tree().process_frame
    var f=FileAccess.open("res://../art-fits.json",FileAccess.WRITE);f.store_string(JSON.stringify(art.fits,"  "))
    print("ART05_ADAPTER_OK ",art.bindings.size())
    for b in art.bindings:print(b.kind)
    get_tree().quit()
