"""Verify every canonical hash, then prepare a fresh copy and explicit reopen jobs."""
import argparse, hashlib, json, shutil
from pathlib import Path

ap=argparse.ArgumentParser(); ap.add_argument('--package',type=Path,required=True); ap.add_argument('--output',type=Path); a=ap.parse_args()
package=a.package.resolve(); manifest=json.loads((package/'manifest.json').read_text())
for rel, expected in manifest['files'].items():
    p=package/rel
    assert p.resolve().is_relative_to(package) and p.stat().st_size==expected['bytes'],rel
    with p.open('rb') as f: assert hashlib.file_digest(f,'sha256').hexdigest()==expected['sha256'],rel
print('D1_CANONICAL_HASHES_OK',len(manifest['files']))
if a.output:
    root=Path(__file__).resolve().parents[3]; out=a.output.resolve()
    assert out.is_relative_to(root/'build/art07/d1') and not out.exists()
    out.mkdir(parents=True)
    shutil.copytree(package/'review',out/'review')
    source=out/'source'; source.mkdir()
    shutil.copy2(package/'editable/core-lattice.blend',source/'core-lattice.blend')
    shutil.copy2(package/'geometry.json',source/'geometry.json')
    shutil.copytree(package/'review/game/art07_d1/assets',source/'assets')
    jobs=out/'jobs'; jobs.mkdir()
    godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
    blender='C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
    def job(name,args,exe=godot):
        # Hold the cooperative slot for engine and CPU Blender reopen so these
        # cannot overlap another worker's benchmark or an existing playtest.
        (jobs/(name+'.json')).write_text(json.dumps({'executable':exe,'arguments':args,'cwd':str(root),'output':str(out/'logs'/name),'gpu':True,'timeout_seconds':600,'appdata':str(out/'isolated-appdata')},indent=2)+'\n')
    base=['--path',str(out/'review/game'),'--audio-driver','Dummy']
    job('import',base+['--headless','--import'])
    job('placement',base+['--headless','res://art07_d1/checks.tscn'])
    job('restart',base+['--headless','res://art07_d1/checks.tscn','--','--d1-restore'])
    for renderer in ['forward_plus','gl_compatibility']:
        job(renderer,base+['--rendering-method',renderer,'--resolution','1440x900','--position','-9999,-9999','res://art07_d1/gallery.tscn','--','--capture'])
    job('blender',['--background','--threads','8','--python-exit-code','1','--python',str(root/'tools/wroughtwild-art07/d1/reopen.py'),'--',str(source),str(out/'blender-reopen')],blender)
    (out/'canonical-hashes.json').write_text(json.dumps({'files_checked':len(manifest['files']),'manifest_sha256':hashlib.sha256((package/'manifest.json').read_bytes()).hexdigest(),'before_import':True},indent=2)+'\n')
    print('D1_FRESH_VERIFY_COPY_READY',out)
