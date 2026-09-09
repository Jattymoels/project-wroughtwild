"""Consolidate current measured evidence; keep historical and failed attempts explicit."""
import sys,json,subprocess,shutil,re
from pathlib import Path
from audit import DEPOT,read,sha
work,game=map(lambda x:Path(x).resolve(),sys.argv[1:3]);build=work.parent
out=work/'conformance.json';assert not out.exists()
subprocess.run([sys.executable,str(Path(__file__).with_name('material_manifest.py')),str(work),str(out)],check=True)
report=read(out);report['native']=read(build/'native/provenance.json')
report['historical_native_baseline']='f7253d20ed1dbeee743219190bdaccac60921c1c'
report['native_difference_summary']=(build/'native-baseline-differences.txt').read_text(encoding='utf-8-sig')
report['install_manifest']=read(DEPOT/'tools/wroughtwild-trellis/install-manifest.json')
recipes=read(build/'native/snapshot/data/tuning/crafting.json')['recipes']
report['current_data_sha256']={p.relative_to(build/'native/snapshot').as_posix():sha(p) for p in sorted((build/'native/snapshot/data').rglob('*')) if p.is_file()}
report['performance_conditions']={'device':'NVIDIA GeForce RTX 5090','driver':'591.86','godot':'4.5.stable.official.876b29033','resolution':[1600,1000],'msaa':'4x','bloom':False,'warmup_frames':60,'sample_frames':150,'lod':'near','vsync_mode':1,'wall_timing_limit':'VSync enabled; approximately 7 ms includes presentation pacing, not uncapped throughput.','scope':'Six fixed source/device/overview day/shade cases per family and renderer; original backdrop retained. Independent benchmark batch, no capture/generation/encoding/compiler load.'}
for c,f in report['families'].items():
    recipe=next(r for r in recipes if r['id']==f['device']['recipe_id'])
    assert recipe['inputs']==f['device']['recipe_inputs'] and recipe['outputs']=={f['device']['kit']:1}
    f['current_paid_recipe']=recipe
    f['fresh_blender']=read(work/c/'evidence/blender-audit.json')
    f['native_checks']=read(work/c/'evidence/native-checks.json')
    f['native_restart']=read(work/c/'evidence/native-restart.json')
    f['motion']=read(work/c/'evidence/f5-motion-checks.json')
    f['renderers']={}
    for label,folder in [('forward_plus','evidence'),('gl_compatibility','evidence-compat')]:
        path=work/c/'review'/folder
        states=read(path/('capture-checks.json' if c=='red' else 'visual-checks.json'));assert not states['failures']
        performance=read(path/'performance.json');assert performance['renderer']==label and len(performance['cases'])==6
        for row in performance['cases']:assert row['frame_p50_ms']>0 and row['frame_p95_ms']>=row['frame_p50_ms'] and row['frame_worst_ms']>=row['frame_p95_ms']
        f['renderers'][label]={'visual_checks':states.get('visual_checks',states.get('checks')),'performance':performance}
    for key in ['native_checks','native_restart','fresh_blender']:assert not f[key]['failures']
    assert f['fresh_blender']['master_sha256']==sha(work/c/f'editable/{c}-workshop.blend')
report['current_game']=read(game/'receipt.json')
report['current_game']['historical_failed_attempts']=[r for r in report['current_game']['runs'] if r['exit_code']!=0]
report['current_game']['failure_explanation']='First weathered_save invocation lacked its expected private build/codex-aesthetic directory (2 file-I/O failures); unchanged test rerun passed 21/21 after setup correction. Initial F5 placement adapter forgot the half-metre cell offset and physics-space settle after restore; corrected only F5 test, all 47+25 assertions passed. Initial Red benchmark had long Windows shader-cache paths; shortened private APPDATA and reran measurements. Failed logs retained.'
report['placement_commands']=read(game/'f5-placement-v03/commands.json')
assert all(r['exit_code']==0 for r in report['placement_commands'])
report['placement_lineage']=read(game/'game/art07f5/lineage.json')
report['scope_limits']=['No normal game integration or owner visual acceptance','Original exterior meshes are not certified watertight; only recovered solids are','No source regeneration or scar redesign; actual approximately 3 mm approved cuts retained','RTX 5090 only; no low-end, populated-world, streaming or automatic LOD certification','Current full-world source/work/save checks separate from historical compact paid review checkpoints','Transaction test grants two labelled kits per colour; not evidence of paid first-hour progression']
for name in ['logs','f5-placement-v01','f5-placement-v02','f5-placement-v03']:
    shutil.copytree(game/name,work/'audit/current-game'/name)
shutil.copy2(game/'receipt.json',work/'audit/current-game/receipt.json')
shutil.copy2(game/'game/art07f5/lineage.json',work/'audit/current-game/placement-lineage.json')
# Keep exact expected placement ownership and source ledgers local, not in Git.
for name in ['art07-f5-placement.json','art07-f5-placement-expected.json']:
    shutil.copy2(game/'appdata/Godot/app_userdata/Wroughtwild'/name,work/'audit/current-game'/name)
shutil.copy2(build/'native/provenance.json',work/'audit/current-native-provenance.json')
shutil.copy2(build/'native-baseline-differences.txt',work/'audit/native-baseline-differences.txt')
out.write_text(json.dumps(report,indent=2),encoding='utf-8')
shutil.copy2(out,Path(__file__).with_name('manifest.json'))
print('F5_CONFORMANCE_COLLECTED')
