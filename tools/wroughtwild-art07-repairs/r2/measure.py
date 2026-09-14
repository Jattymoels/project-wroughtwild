"""R2 measurement derivative. All engine execution remains in the shared run.ps1."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BUILD = ROOT / 'build/art07-repairs/r2'
TOOLS = Path(__file__).resolve().parent


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8', newline='\n') as stream:
        stream.write(value if isinstance(value, str) else json.dumps(value, indent=2))


def replace(source, old, new):
    assert source.count(old) == 1, (old, source.count(old))
    return source.replace(old, new)


def install(version):
    base = BUILD / version
    game = base / 'runtime/game'
    source = (game / 'g1/review.gd').read_text(encoding='utf-8')
    source = replace(source, 'var camera:Camera3D', 'const R2Profile=preload("res://r2/profile.gd")\nvar world_build_ms:=0.0\nvar camera:Camera3D')
    source = replace(source, 'func execute():', 'func _build_world(seed_value: int) -> void:\n\tvar started:=Time.get_ticks_usec()\n\tsuper._build_world(seed_value)\n\tworld_build_ms=float(Time.get_ticks_usec()-started)/1000.0\nfunc execute():')
    source = replace(source, '\tDirAccess.make_dir_recursive_absolute', '\tfor arg in OS.get_cmdline_user_args():\n\t\tif arg.begins_with("--run-id="):output+="-"+arg.get_slice("=",1)\n\tDirAccess.make_dir_recursive_absolute')
    source = replace(source, '\tcheck(SaveManager.new().read', '\tvar restore_started:=Time.get_ticks_usec()\n\tcheck(SaveManager.new().read')
    source = replace(source, '\tfreeze_fixtures();refresh_stations()', '\tvar restore_ms:=float(Time.get_ticks_usec()-restore_started)/1000.0\n\tfreeze_fixtures();refresh_stations()')
    source = replace(source, '\tvar interior:=player.position', '\tvar setup_elapsed_ms:=Time.get_ticks_msec()\n\tvar interior:=player.position')
    source = replace(source, '\t\tterrain.ensure_area(view.at,64);', '\t\tvar focus_started:=Time.get_ticks_usec()\n\t\tterrain.ensure_area(view.at,64);')
    source = replace(source, '\t\tcamera.position=view.eye;', '\t\tvar focus_ms:=float(Time.get_ticks_usec()-focus_started)/1000.0\n\t\tcamera.position=view.eye;')
    source = replace(source, '\t\t\tfor frame in 120 if "--benchmark" in OS.get_cmdline_user_args() else 12:await get_tree().process_frame', '\t\t\tvar warmup:Array[float]=[]\n\t\t\tvar first_tick:=Time.get_ticks_usec()\n\t\t\tfor frame in 120 if "--benchmark" in OS.get_cmdline_user_args() else 12:\n\t\t\t\tawait get_tree().process_frame\n\t\t\t\tvar next_tick:=Time.get_ticks_usec();warmup.append(float(next_tick-first_tick)/1000.0);first_tick=next_tick')
    source = replace(source, '\t\t\t\twall.sort();', '\t\t\t\tvar raw_wall:=wall.duplicate()\n\t\t\t\twall.sort();')
    source = replace(source, '"frame_p95_ms":wall[285]', '"frame_p95_ms":wall[285],"frame_worst_ms":wall[-1],"wall_samples_ms":raw_wall,"warmup_samples_ms":warmup,"focus_ms":focus_ms')
    source = replace(source, '"gpu_p95_ms":gpu[285]', '"gpu_p95_ms":gpu[285],"gpu_worst_ms":gpu[-1]')
    source = replace(source, '{"base":"6bb2e044dcd0bf1788896aa2c19cdf56fee93522"', '{"setup_elapsed_ms":setup_elapsed_ms,"world_build_ms":world_build_ms,"restore_ms":restore_ms,"engine":Engine.get_version_info(),"cpu":OS.get_processor_name(),"os":OS.get_name()+" "+OS.get_version(),"gpu_vendor":RenderingServer.get_video_adapter_vendor(),"gpu_api":RenderingServer.get_video_adapter_api_version(),"msaa":get_viewport().msaa_3d,"max_fps":Engine.max_fps,"profile":R2Profile.spans,"base":"6bb2e044dcd0bf1788896aa2c19cdf56fee93522"')
    source = replace(source, chr(34)+"profile"+chr(34)+":R2Profile.spans", chr(34)+"textures"+chr(34)+":texture_inventory(),"+chr(34)+"profile"+chr(34)+":R2Profile.spans")
    source += (TOOLS / "texture_inventory.gd.txt").read_text(encoding="utf-8-sig")
    # The body of costs() stays the same G1/G2 scene-geometry accounting.
    write(game / 'r2/benchmark.gd', source)
    write(game / 'r2/benchmark.tscn', (game/'g1/review.tscn').read_text().replace('res://g1/review.gd', 'res://r2/benchmark.gd'))
    write(game / 'r2/profile.gd', (TOOLS/'profile.gd').read_text())
    write(base/'measurement-derivative.json', {'source':'game/g1/review.gd','source_sha256':hashlib.sha256((game/'g1/review.gd').read_bytes()).hexdigest(),'purpose':'Unique output, maximum and raw wall frames, first-focus/warmup, world/restore spans and actual device identifiers. Same checkpoint, cameras, settings and 120/300 loops. Production source unchanged.'})


def jobs(version, kind, count=3):
    base = BUILD / version
    runtime = base/'runtime'
    result=[]
    for n in range(1, count+1):
        for renderer in ['forward_plus','gl_compatibility']:
            for mode in ['baseline','art'] if kind=='benchmark' else ['art']:
                ident=f'{kind}-{mode}-{renderer}-{n:02d}'
                args=['--rendering-method',renderer,'--path',str(runtime/'game'),'res://r2/benchmark.tscn','--','--run-id='+ident]
                if kind=='benchmark':args.append('--benchmark')
                if mode=='baseline':args.append('--baseline')
                result.append({'id':ident,'program':str(runtime/'engine/Godot_v4.5-stable_win64.exe'),'arguments':args,'log':str(base/'logs'/f'{ident}.log'),'state':str(base/'users'/ident)})
    write(base/(kind+'-jobs.json'),result)
    print('R2_MEASUREMENT_JOBS',len(result))


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('command',choices=['install','benchmark','views']);p.add_argument('--version',required=True);p.add_argument('--count',type=int,default=3);a=p.parse_args()
    assert ROOT.as_posix().lower()=='d:/project-wroughtwild-art07-r2'
    if a.command=='install':install(a.version)
    else:jobs(a.version,a.command,a.count)
