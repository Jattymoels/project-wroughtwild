extends "res://scripts/sandpit.gd"
var art:Node
func _ready():
    world_seed=77;world_profile="living_frontier_wave3"
    _build_world(world_seed);player.class_panel.choose("warden")
    art=load("res://art05/route_art.gd").new();add_child(art);art.setup(self)
    var manager:=SaveManager.new()
    var checkpoint:="res://art05/route-checkpoint.json"
    if "--smoke" not in OS.get_cmdline_user_args() and FileAccess.file_exists(SaveManager.default_path()):checkpoint=SaveManager.default_path()
    assert(manager.read(checkpoint,player),manager.last_error)
    player.camera.position=Vector3.ZERO
    player.rotation=Vector3.ZERO
    player.camera.look_at(Vector3(469.5,31.6,438.5))
    player.hud.notify("Red trail art pilot — your paid workshop and the native boar habitat. F5 saves / F9 loads this isolated world.")
    if "--smoke" in OS.get_cmdline_user_args():smoke.call_deferred()
func smoke():
    for frame in 120:await get_tree().physics_frame
    assert(player.is_physics_processing() and player.combat.is_physics_processing())
    assert(_sim().material_count("red_salt")==10)
    assert(not _sim().world_effect_active("host_defeated:lf3_red_rooting"))
    assert(_sim().contraption_ids().size()==1)
    var buffers=get_tree().get_nodes_in_group("contraptions")
    assert(buffers.size()==1 and buffers[0].has_meta("art05"))
    print("ART05_PLAYABLE_SMOKE_OK")
    get_tree().quit()
