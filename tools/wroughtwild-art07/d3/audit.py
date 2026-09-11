"""Verify frozen rule/test sources, selected models, scoped recipes and evidence."""
import argparse,ast,hashlib,json,subprocess,zipfile
from pathlib import Path
from PIL import Image
ap=argparse.ArgumentParser(); ap.add_argument('--build',type=Path,required=True); ap.add_argument('--models',type=Path,required=True); a=ap.parse_args()
worker=Path(__file__).resolve().parents[3]; b=a.build.resolve(); models=a.models.resolve()
changed=[]; line_endings=[]; files=0
with zipfile.ZipFile(b/'frozen.zip') as z:
    for name in z.namelist():
        if name.endswith('/'): continue
        files+=1
        original=z.read(name); current=(b/'snapshot'/name).read_bytes()
        if original!=current:
            if original.replace(b'\r\n',b'\n')==current.replace(b'\r\n',b'\n'):
                line_endings.append(name); continue
            assert name=='game/scripts/piece_look.gd',name
            needle=b'\tif String(shape_id) in preload("res://art07_d3/adapter.gd").IDS or String(shape_id) in preload("res://art07_d3/adapter.gd").COARSE:\n\t\treturn preload("res://art07_d3/adapter.gd").mesh_for(String(shape_id),String(family))\n'
            assert current.replace(b'\r\n',b'\n').replace(needle,b'',1)==original.replace(b'\r\n',b'\n'),'Only the documented copied mesh adapter may differ'
            changed.append(name)
assert changed==['game/scripts/piece_look.gd'],changed
for p in Path(__file__).parent.glob('*.py'): ast.parse(p.read_text(encoding='utf-8-sig'),filename=str(p))
report=json.loads((models/'geometry.json').read_text()); assert len(report['assets'])==12
for k,e in report['assets'].items():
    assert hashlib.sha256((models/'assets'/f'{k}.glb').read_bytes()).hexdigest()==e['sha256']
    assert e['nonmanifold_edges']==e['degenerate_triangles']==0
curated=worker/'docs/art/leyline-studies/2026-09-09/art07/d3'
for e in json.loads((curated/'evidence.json').read_text())['media']:
    p=curated/e['file']; assert hashlib.sha256(p.read_bytes()).hexdigest()==e['sha256']
    if p.suffix=='.webp':
        with Image.open(p) as im: assert im.n_frames==48
native_delta=subprocess.check_output(['git','diff','--name-only','56ce6bbe343012205690cf669491372958b80662','0f35e87c6a23e3197bec968fa4443c8e134317b3','--','sim','data','tests/sim','game/extensions/wroughtwild_sim'],cwd=worker,text=True)
assert not native_delta
result={'frozen_files_checked':files,'only_copied_source_changes':changed,'line_ending_only_engine_import_rewrites':line_endings,'all_current_tests_unchanged':True,'rules_data_cpp_and_cpp_tests_identical_to_published_D1':True,'assets':12,'total_triangles':sum(e['triangles'] for e in report['assets'].values()),'glb_bytes':sum(p.stat().st_size for p in (models/'assets').glob('*.glb')),'curated_media_hashes_verified':True}
(b/'source-audit.json').write_text(json.dumps(result,indent=2)+'\n')
print('D3_SOURCE_EVIDENCE_AUDIT_OK',json.dumps(result))
