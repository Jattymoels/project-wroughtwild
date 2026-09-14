import json,shutil,subprocess
from measure import ROOT,OUT,GAME,INPUTS,sha,write
assert subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip()=='codex/art07-r1'
record=json.loads((OUT/'prepared.json').read_text());result=[]
for name,row in record['original_files'].items():
    p=OUT/'runtime'/name
    assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],name
    result.append({'path':name,**row,'verified':True})
write(OUT/'evidence/prepared-runtime-hashes.json',{'files':result,'runtime_base':record['runtime_base']})
copied=[]
for ident in ['b1','c4']:
    package=INPUTS['source_packages'][ident];src=__import__('pathlib').Path(package['path']);manifest=json.loads((src/'manifest.json').read_text());rows=manifest.get('files',manifest)
    if isinstance(rows,list):rows={r['path']:r for r in rows}
    for name,row in rows.items():
        if name.startswith('models/') or (ident=='b1' and name=='recipe/kit.json'):
            a=src/name;b=OUT/'sources'/ident/name
            assert sha(a)==row['sha256'];b.parent.mkdir(parents=True,exist_ok=True);assert not b.exists();shutil.copy2(a,b);assert sha(b)==row['sha256'];copied.append({'source':str(a),'copy':str(b),**row})
write(OUT/'evidence/copied-source-hashes.json',copied)
print('R1_SOURCE_COPIES',len(copied),'RUNTIME_HASHES',len(result))
