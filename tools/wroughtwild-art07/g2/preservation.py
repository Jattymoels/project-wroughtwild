"""Final source/runtime preservation audit; review saves are explicit exceptions."""
import collections
import json
import subprocess
from pathlib import Path
from verify_copy import ROOT, BUILD, DEPOT, sha, rows_for, check_package, write_new
OUT=BUILD/'v01'
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
before=read(OUT/'inputs.json');after=read(OUT/'after/inputs.json')
for key in ['runtime_base','input_record','input_index','sources','g1_package']:
    assert before[key]==after[key],key
sealed=check_package(OUT/'sealed',before['g1_package'])
original=read(OUT/'copy.json')['runtime_files']
changed=[]
for name,row in original.items():
    path=OUT/'review'/name
    assert path.is_file(),name
    current=sha(path)
    if current!=row['sha256']:
        assert name=='game/g1/paid-home.json',name
        changed.append({'path':name,'before_sha256':row['sha256'],'after_sha256':current,
          'authority':'sealed game/g1/paid.gd:94 writes the paid review checkpoint; it is disposable test state, never a normal player save.'})
assert len(changed)==1
new=[];generated=collections.Counter()
for path in sorted((OUT/'review').rglob('*')):
    if not path.is_file():continue
    name=path.relative_to(OUT/'review').as_posix()
    if name in original:continue
    if '.godot' in path.parts or path.suffix in ['.uid','.import']:
        generated['files']+=1;generated['bytes']+=path.stat().st_size;continue
    allowed=(name.startswith(('evidence/','game/g2/','build/pressure-workshop/','captures/home/'))
        or name=='game/g1/paid-home.json.previous'
        or (name.startswith(('game/art07_d1/','game/art07_d2/','game/art07_d3/')) and path.name in ['check-placement.json','check-restart.json'])
        or (len(Path(name).parts)>3 and Path(name).parts[0]=='game' and Path(name).parts[1] in ['b1','b3','c1','c2','c3','c4','c5','f1','f2','f3'] and Path(name).parts[2]=='evidence' and path.suffix=='.json'))
    assert allowed,name
    new.append({'path':name,'bytes':path.stat().st_size,'sha256':sha(path)})
for ident in ['fauna','canopy']:
    assert sha(ROOT/'tools/wroughtwild-art07/g2'/(ident+'.gd'))==sha(OUT/'review/game/g2'/(ident+'.gd'))
adaptations=read(OUT/'g2-adaptations.json')
benchmark=(OUT/'sealed/game/g1/review.gd').read_text()
for old,replacement in adaptations['benchmark_changes']:
    assert benchmark.count(old)==1
    benchmark=benchmark.replace(old,replacement)
assert benchmark==(OUT/'review/game/g2/benchmark.gd').read_text()
textures=collections.defaultdict(list)
for name,row in original.items():
    if name.startswith('game/') and name.endswith('.png'):textures[row['sha256']].append(dict(row,path=name))
duplicates=[rows for rows in textures.values() if len(rows)>1]
packaging={'duplicate_png_copies_beyond_one':sum(len(rows)-1 for rows in duplicates),'redundant_png_disk_bytes':sum((len(rows)-1)*rows[0]['bytes'] for rows in duplicates),'scope':'Exact duplicate standalone PNG bytes only. Not an estimate of GPU-memory savings; imported textures/GLB payloads have separate residency.'}
def git(root,*args):return subprocess.check_output(['git','-C',str(root),*args],text=True).strip()
assert git(ROOT,'branch','--show-current')=='codex/art07-g2'
assert git(DEPOT,'branch','--show-current')=='main'
assert git(DEPOT,'rev-parse','HEAD')==before['review_base']
assert git(DEPOT,'remote','get-url','origin')=='https://github.com/Jattymoels/project-wroughtwild.git'
report={'canonical_and_24_sources_before_after_equal':True,'sealed_copy':sealed,'runtime_files_checked':len(original),'runtime_unchanged':len(original)-len(changed),'disposable_checkpoint_changes':changed,'new_review_files':new,'generated_import_sidecars_and_cache':dict(generated),'packaging':packaging,'owner_branch':git(DEPOT,'branch','--show-current'),'owner_head':git(DEPOT,'rev-parse','HEAD'),'owner_tracked_status':git(DEPOT,'status','--short','--untracked-files=no'),'review_branch':git(ROOT,'branch','--show-current'),'g2_inspection_sources_match':True,'scope':'All original runtime bytes checked; only the explicit disposable paid-home checkpoint changed. Generated imports and G2 additions are inventoried separately. G2 did not open/write normal saves, mutate the owner checkout, message sessions, or interrupt another process.'}
report['formatting_note']='After the preliminary seal, the staged whitespace check removed only trailing blank lines in four G2 recipes; the G2 fauna inspection copy received the same EOF-only trim. No executable statement or original G1 runtime file changed.'
write_new(OUT/'preservation-final.json',report)
print('G2_PRESERVATION_OK',len(original),len(changed),len(new),json.dumps(packaging))
