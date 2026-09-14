"""Install bounded R8 automation comfort checks and initial guarded jobs."""
import json
from inspect_inputs import ROOT,read
from compose import write
out=ROOT/'build/art07-repairs/r8/v01';game=out/'runtime/game'
write(game/'r8/comfort.gd','''extends Node
var frames:=0
func _enter_tree():
    assert("--r8-no-mouse-capture" in OS.get_cmdline_user_args())
    if DisplayServer.get_name()!="headless":
        assert(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS))
        assert(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
    print("R8_COMFORT startup_no_focus=true capture_opt_out=true")
func _ready():
    set_process("--r8-comfort-check" in OS.get_cmdline_user_args())
func _process(_delta):
    assert(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
    frames+=1
    if frames==120:
        print("R8_COMFORT 120 live frames mouse_visible=true")
        set_process(false)
''')
write(game/'override.cfg','''; Disposable R8 test launch settings; excluded from playable sealed runtime.
[display]
window/size/no_focus=true
[autoload]
R8Comfort="*res://r8/comfort.gd"
''')
jobs=read(out/'import-smoke.json')
for j in jobs:
    if '--' not in j['arguments']:j['arguments']+=['--']
    j['arguments']+=['--r8-no-mouse-capture']
    if 'smoke' in j['id']:j['arguments']+=['--r8-comfort-check']
write(out/'jobs-import-comfort-01.json',jobs)
print('R8_IMPORT_COMFORT_READY')
