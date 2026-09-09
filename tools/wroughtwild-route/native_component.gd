extends Node3D
## Component regression using the untouched ART-04 paid checkpoint. No grants,
## invented timings or world re-anchoring; this is independent of route selection.
const BUFFER="fixture_1030_62_1040"
const FEEDER="fixture_1034_62_1036"
var checks:=0
func check(ok:bool,label:String):
    assert(ok,label);checks+=1
func _ready():
    var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art05/paid-component-checkpoint.json"))
    var s:=WroughtwildSim.new();check(s.load_tuning(ProjectSettings.globalize_path("res://../data/tuning")),"load pinned native tuning")
    check(s.import_json(saved.sim),"read paid owned inventory")
    check(s.leyline_load_world(saved.leylines,saved.world_profile,saved.world_seed),"preserve source profile/seed")
    check(s.contraption_load_world(saved.contraptions,saved.world_profile,saved.world_seed),"preserve paid fixture records")
    ContraptionSite.restore_all(self,s)
    var n:=ContraptionSite.find_site(get_tree(),BUFFER)
    var art=load("res://art05/route_art.gd").new();add_child(art);art.set_process(false)
    art.index=JSON.parse_string(FileAccess.get_file_as_string("res://art05/assets/asset-index.json"))
    art.bind_buffer(n)
    var b:Dictionary=art.bindings[0]
    art._process(.016)
    check(b.material.get_shader_parameter("state_mode")==1,"restoring paused fractional work never flashes a false working state")
    var c:float=b.work_clock
    var original:=s.contraption_save()
    s.contraption_tick(FEEDER,2.0,true);art._process(.016)
    check(s.contraption_save()==original and b.work_clock==c,"saved pause advances neither native nor visual work")
    check(s.contraption_action(FEEDER,"resume",true).ok,"ordinary native resume")
    s.contraption_tick(FEEDER,.25,true);art._process(.016)
    check(b.material.get_shader_parameter("state_mode")==3 and is_equal_approx(b.work_clock,c+.25),"actual quarter-second advances fitted buffer flow")
    original=s.contraption_save();c=b.work_clock
    s.contraption_tick(FEEDER,2.0,false);art._process(.016)
    check(s.contraption_save()==original and b.work_clock==c and b.material.get_shader_parameter("state_mode")==1,"blocked work holds steady without visual progress")
    s.contraption_tick(FEEDER,5.5,true);art._process(.016)
    check(s.contraption_state(FEEDER).output.rustclay_brick==12 and s.contraption_state(BUFFER).heat==3,"one real completion produces four bricks from reserved paid heat")
    check(is_equal_approx(b.work_clock,c+5.5),"completion wrap preserves exact advanced visual work")
    c=b.work_clock;original=s.contraption_save()
    s.contraption_tick(FEEDER,10,true);art._process(.016)
    check(b.work_clock==c and s.contraption_save()==original,"no replay or invented work after finite completion")
    print("ART05_NATIVE_COMPONENT ",checks," checks")
    var f=FileAccess.open("res://../evidence-art/native-component.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":0,"note":"Original ART-04 LF-1 paid native checkpoint, tested independently of LF-3 route geography."},"  "))
    get_tree().quit()
