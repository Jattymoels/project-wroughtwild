"""Copy the published editable masters, preserving their exact bytes and lineage."""
import json
import shutil
import sys
from pathlib import Path
from verify_inputs import ROOT, INDEX, digest

out=Path(sys.argv[1]).resolve()
assert out.is_relative_to(ROOT/'build/art07/g1')
out.mkdir(parents=True,exist_ok=False)
index=json.loads(INDEX.read_text())
rows=[]
for ident,record in index['inputs'].items():
    package=Path(record['path'])
    masters=[p for p in package.rglob('*.blend') if not {'inspection','evidence'}.intersection(p.relative_to(package).parts)]
    assert masters,ident
    for source in masters:
        relative=Path(ident)/source.relative_to(package)
        target=out/relative
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(source,target)
        sha=digest(source)
        assert digest(target)==sha
        rows.append({'slice':ident,'source':str(source),'copy':relative.as_posix(),'sha256':sha,'bytes':source.stat().st_size})
(out/'masters.json').write_text(json.dumps(rows,indent=2))
print('G1_MASTERS_STAGED',len(rows),sum(r['bytes'] for r in rows))
