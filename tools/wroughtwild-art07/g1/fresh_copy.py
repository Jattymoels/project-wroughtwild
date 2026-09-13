"""Copy the completed runtime sources into a cache-free isolated launch target."""
import json
import shutil
import sys
from pathlib import Path
from verify_inputs import ROOT,digest

source,target,report=map(lambda p:Path(p).resolve(),sys.argv[1:])
assert target.is_relative_to(ROOT/'build/art07/g1') and not target.exists()
target.mkdir(parents=True)
rows=[]
for folder in ['game','data','engine']:
    for file in sorted((source/folder).rglob('*')):
        if not file.is_file() or '.godot' in file.relative_to(source).parts or file.suffix=='.uid':continue
        dest=target/file.relative_to(source);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(file,dest)
        a,b=digest(file),digest(dest);assert a==b
        rows.append({'path':file.relative_to(source).as_posix(),'sha256':a,'bytes':file.stat().st_size})
shutil.copy2(source/'launch.ps1',target/'launch.ps1')
with report.open('x') as f:json.dump({'source':str(source),'fresh_copy':str(target),'files':rows,'scope':'All runtime game/data/engine source bytes copied and compared before first import, with .godot caches and generated UID sidecars omitted. Fresh launch uses a new isolated APPDATA directory.'},f,indent=2)
print('G1_FRESH_COPY_VERIFIED',len(rows),sum(r['bytes'] for r in rows))
