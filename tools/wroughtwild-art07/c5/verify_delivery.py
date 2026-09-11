"""Post-seal checks: canonical bytes, fresh independent results and original sources."""
import sys,json,hashlib,re
from pathlib import Path
root,out=map(lambda p:Path(p).resolve(),sys.argv[1:3]);assert not out.exists()
require_fresh_renders='--fresh-renders' in sys.argv[3:]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def manifest(folder):
    rows=json.loads((folder/'manifest.json').read_text())
    for name,entry in rows.items():
        p=(folder/name).resolve();assert p.is_relative_to(folder)
        assert p.stat().st_size==entry['bytes'] and sha(p)==entry['sha256'],p
    return {'files':len(rows),'sha256':sha(folder/'manifest.json')}
result={'canonical':manifest(root/'handoff-v01')}
prov=json.loads((root/'prerequisites.json').read_text())
for name,h in prov['files'].items():assert sha(Path(name))==h,name
result['original_inputs_unchanged']=len(prov['files']);result['b3']=manifest(Path(prov['b3_package']))
assert json.loads((root/'audit-v08.json').read_text())==json.loads((root/'fresh-audit.json').read_text())
result['fresh_glbs']=90
fresh=root/'fresh-v01/review/game/c5/evidence';selected=root/'review-v03/game/c5/evidence'
runtime_files=0
for p in sorted((root/'handoff-v01/review').rglob('*')):
    if not p.is_file() or p.suffix=='.import':continue
    relative=p.relative_to(root/'handoff-v01/review')
    assert sha(p)==sha(root/'fresh-v01/review'/relative),relative
    assert sha(p)==sha(root/'review-v03'/relative),relative
    runtime_files+=1
result['identical_runtime_source_files']=runtime_files
result['fresh_renderer_recapture']=require_fresh_renders
result['render_scope']='Actual selected runtime captured in both renderers before sealing. Fresh import/native reloads plus exact runtime byte identity verified after sealing.'
for mode,checks in [('flow',121),('partial',66),('final',52)]:
    row=json.loads((fresh/'native-headless'/('native-'+mode+'.json')).read_text());assert row['checks']==checks and row['failures']==0
    result['native_'+mode]=row
for renderer in ['forward_plus','gl_compatibility']:
    names=['day','shade','dusk','scar-off','lod-0','lod-1','lod-2']
    names += [i+'-'+kind for i in ['iron_vein','copper_vein','tin_vein','ember_iron_vein','silver_vein'] for kind in ['material','clay']]
    for name in names:assert (selected/renderer/(name+'.png')).is_file(),(renderer,name)
    if require_fresh_renders:
        for name in names:assert sha(fresh/renderer/(name+'.png'))==sha(selected/renderer/(name+'.png')),(renderer,name)
    captures=fresh if require_fresh_renders else selected
    assert len(list((captures/renderer).glob('heat-motion-*.png')))==42
    assert len({sha(captures/renderer/f'paused-{i}.png') for i in range(3)})==1
    row=json.loads((captures/('native-'+renderer)/'native-flow.json').read_text());assert row['checks']==148 and row['failures']==0
    result[renderer]={'selected_static_pngs':len(names),'paused_identical':True,'native':row}
checks=[]
for log in sorted((root/'current-checks').glob('*.log')):
    matches=re.findall(r'(\d+) checks, (\d+) failures',log.read_text())
    assert matches and all(int(b)==0 for a,b in matches),log
    checks.extend(int(a) for a,b in matches)
assert sum(checks)==8225
result['current_unmodified_checks']=sum(checks)
for name in ['fresh-import','fresh-native']+(['fresh-capture'] if require_fresh_renders else ['capture-v03']):
    for p in (root/name).glob('*.job.json'):
        assert json.loads(p.read_text(encoding='utf-8-sig'))['exit']==0,p
    for p in (root/name).glob('*.log*'):
        if p.suffix=='.json':continue
        assert not re.search(r'SCRIPT ERROR|SHADER ERROR|Parse Error|Traceback',p.read_text(errors='replace')),p
assert 'C5_INTERACTIVE_PAUSE_OK 90' in (root/'fresh-native/pause.log').read_text()
out.write_text(json.dumps(result,indent=2)+'\n');print('C5_DELIVERY_VERIFIED',result['canonical'])
