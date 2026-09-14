"""Retain declared immutable packed masters and their supporting source files."""
import json,shutil
from pathlib import Path
from inspect_inputs import ROOT,inputs,read,sha
from compose import write
out=ROOT/'build/art07-repairs/r8/v01';pins,ds=inputs();copied=[]
selections=[('g1',pins['runtime_source'],['masters/','lineage/','native/'])]
selections += [(k,ds[k]['package'],prefix) for k,prefix in [
 ('r1',['models/','sources/']),('r3',['masters/']),('r5',['source-candidate/','source-original/']),('r6',['evidence/sources/']),('r7',['sources/'])]]
for ident,pkg,prefixes in selections:
    root=Path(pkg['path']);assert sha(root/'manifest.json')==pkg['manifest_sha256'];m=read(root/'manifest.json');rows=m.get('files',m)
    if isinstance(rows,list):rows={r['path']:r for r in rows}
    total=0
    for name,row in rows.items():
        if not any(name.startswith(prefix) for prefix in prefixes):continue
        src=root/name;dst=out/'sources'/ident/name
        assert src.stat().st_size==row['bytes'] and sha(src)==row['sha256'].lower(),str(src)
        assert not dst.exists();dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
        assert sha(dst)==row['sha256'].lower()
        copied.append({'owner':ident,'source':str(src),'path':dst.relative_to(out).as_posix(),**row});total+=1
    print('R8_SOURCES_RETAINED',ident,total,flush=True)
write(out/'selected-source-hashes.json',copied)
