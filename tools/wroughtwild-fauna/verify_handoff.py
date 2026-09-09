"""Write or check the clean local package manifest: PACKAGE [--write-manifest]."""
import hashlib,json,sys
from pathlib import Path

root=Path(sys.argv[1]).resolve()
manifest=root/'manifest.json'
if '--write-manifest' in sys.argv:
    assert not manifest.exists()
    entries=[]
    for file in sorted(p for p in root.rglob('*') if p.is_file()):
        relative=file.relative_to(root)
        assert not any(part in ('.godot','user','__pycache__') for part in relative.parts)
        assert file.suffix not in ('.pyc','.uid','.log','.err')
        entries.append({'path':relative.as_posix(),'bytes':file.stat().st_size,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()})
    manifest.write_text(json.dumps({'files':entries,'note':'Clean local ART-03 handoff. Generated meshes/blends remain local; the manifest and selected evidence are versioned. Manifest excludes itself.'},indent=2)+'\n',encoding='utf-8')
data=json.loads(manifest.read_text(encoding='utf-8'))
for entry in data['files']:
    file=(root/entry['path']).resolve()
    assert file.is_relative_to(root) and file.is_file(),entry['path']
    assert file.stat().st_size==entry['bytes'],entry['path']
    assert hashlib.sha256(file.read_bytes()).hexdigest()==entry['sha256'],entry['path']
print('FAUNA_MANIFEST_OK',len(data['files']))
