"""Verify immutable published prerequisites before copying the selected maps."""
import hashlib, json, shutil, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
DEPOT = Path('C:/Users/Matty/Dev/project-wroughtwild')
BASE = '0f35e87c6a23e3197bec968fa4443c8e134317b3'
PACKAGES = {
    'd5': ('build/art07/d5/worktree/build/art07/d5/v03/d5-handoff', '79532aa924414715fbbde0bf714280fd75d40c9f21cc62cb44c0ce12c3834844', '68b7ca1152fc543449316c8187efb1ce3abd0382'),
    'd6': ('build/art07/d6/worktree/build/art07/d6/v04/handoff', '8d82eb36775959f41905e579e36d737caa4a8512ed504d679ab49652301338a7', '3bc4f6844fc0adf7b9cb00c93852b9dd81de4222'),
}
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def verify():
    result = {'base': BASE, 'dependencies': {}, 'sources': {}}
    for key,(rel,expected,commit) in PACKAGES.items():
        package=DEPOT/rel
        assert sha(package/'manifest.json') == expected, key
        subprocess.run(['git','-C',str(ROOT),'merge-base','--is-ancestor',commit,BASE],check=True)
        rows=json.loads((package/'manifest.json').read_text())['files']
        for row in rows:
            p=(package/row['path']).resolve()
            assert p.is_relative_to(package.resolve())
            assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],str(p)
        result['dependencies'][key]={'path':str(package),'manifest_sha256':expected,'published_commit':commit,'verified_files':len(rows)}
    for rel in ['docs/art/concepts/environment/2026-09-09-frontier/04-stations-and-home.png','game/assets/authored/forge_basic.glb','game/assets/authored/forge_improved.glb','game/assets/authored/cataclysm_augmentation_inlay.glb','game/scenes/station_body.tres','game/scripts/station_site.gd','game/art/station_look.gd','game/art/workshop_feedback_look.tres','game/scripts/contraption_site.gd','data/tuning/crafting.json','data/tuning/contraptions.json','data/tuning/construction.json']:
        result['sources'][rel]=sha(ROOT/rel)
    for rel in ['build/blender-tool/blender-4.5.9-windows-x64/blender.exe','build/trellis-local/runtime/trellis-cli.exe','tools/wroughtwild-trellis/install-manifest.json']:
        result['sources'][str(DEPOT/rel)]=sha(DEPOT/rel)
    result['sources']['C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe']=sha('C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe')
    return result
if __name__=='__main__':
    out=Path(sys.argv[1]).resolve(); assert out.is_relative_to(ROOT/'build/art07/e2')
    audit=verify(); out.mkdir(parents=True,exist_ok=False)
    maps=out/'textures'; maps.mkdir()
    for key,stem in [('d5','d5_stone_edge'),('d5','d5_charcoal_face'),('d6','d6_iron')]:
        for channel in ['albedo','normal','orm']:
            src=DEPOT/PACKAGES[key][0]/'review/textures'/f'{stem}_{channel}.png'
            shutil.copy2(src,maps/src.name)
            audit['sources'][str(src)]=sha(src)
    (out/'provenance.json').write_text(json.dumps(audit,indent=2)+'\n')
    print('E2_INPUTS_OK', {k:v['verified_files'] for k,v in audit['dependencies'].items()})
