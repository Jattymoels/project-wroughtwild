"""Read-only R2 package accounting from the checked original runtime entries."""
import collections
import hashlib
import json
from pathlib import Path
from measure import BUILD, write

p=BUILD/'v01/prepared.json'
d=json.loads(p.read_text());root=Path(d['runtime']);rows=d['original_files']
groups=collections.defaultdict(list)
for name,entry in rows.items():
    if name.endswith('.png'):groups[(entry['sha256'],entry['bytes'])].append(name)
dup=[{'sha256':h,'bytes_each':size,'paths':names,'redundant_bytes':size*(len(names)-1)} for (h,size),names in groups.items() if len(names)>1]
params=collections.defaultdict(list)
for group in dup:
    for name in group['paths']:
        descriptor=root/(name+'.import')
        body=descriptor.read_text() if descriptor.exists() else ''
        settings=body.split('[params]',1)[-1].strip() if body else '<absent>'
        params[(group['sha256'],hashlib.sha256(settings.encode()).hexdigest())].append(name)
report={'source_manifest_sha256':d['source']['manifest_sha256'],'runtime_files':d['files'],'runtime_bytes':d['bytes'],'png_files':sum(len(n) for n in groups.values()),'unique_png_byte_groups':len(groups),'redundant_png_copies':sum(len(g['paths'])-1 for g in dup),'redundant_png_disk_bytes':sum(g['redundant_bytes'] for g in dup),'duplicate_groups':dup,'identical_bytes_and_import_params':[{'sha256':h,'import_params_sha256':s,'paths':n} for (h,s),n in params.items() if len(n)>1],'scope':'Disk identities only. Neither identical PNG copies nor their import descriptors prove loaded GPU savings. Engine allocation evidence is separate.'}
write(BUILD/'v01/disk-audit.json',report)
print(json.dumps({k:v for k,v in report.items() if k not in ['duplicate_groups','identical_bytes_and_import_params']},indent=2))
print('GLB_FILES',sum(n.endswith('.glb') for n in rows),'GLTF_FILES',sum(n.endswith('.gltf') for n in rows))
