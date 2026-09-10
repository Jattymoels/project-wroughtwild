"""Verify immutable inputs/tools without launching or installing the generator."""
import sys,json,hashlib,struct
from pathlib import Path
depot,out=[Path(p).resolve() for p in sys.argv[1:]]
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(4*1024*1024),b''):h.update(b)
 return h.hexdigest()
package=depot/'build/grove-art02/emberroot-handoff';manifest=json.loads((package/'manifest.json').read_text());files={}
for rel in ['editable/rock-finished.blend','review/root-bank.glb','review/rock-base.png','review/rock-orm.png','review/forest-floor.png']:
 p=package/rel;h=sha(p);assert h==manifest[rel]['sha256'];files[str(p)]={'sha256':h,'bytes':p.stat().st_size}
for rel in ['build/grove-art02/rock-source-v01/rock.glb','build/grove-art02/rock-source-v01/rock_cutout.png','build/grove-art02/rock-source-v01/generation.json','docs/art/leyline-studies/2026-09-09/grove-art02/rock-input-v01.png','docs/art/references/environment/env-002-dense-frontier-original.png','build/trellis-local/runtime/trellis-cli.exe','build/blender-tool/blender-4.5.9-windows-x64/blender.exe','tools/wroughtwild-trellis/install-manifest.json']:
 p=depot/rel;files[str(p)]={'sha256':sha(p),'bytes':p.stat().st_size}
pinned=json.loads((depot/'tools/wroughtwild-trellis/install-manifest.json').read_text());weights={}
for w in pinned['weights']:
 p=depot/'build/trellis-local/models'/w['name'];h=sha(p);assert h==w['sha256'];weights[w['name']]=h
data=(depot/'build/grove-art02/rock-source-v01/rock.glb').read_bytes();size=struct.unpack_from('<I',data,12)[0];asset=json.loads(data[20:20+size])['asset']
out.write_text(json.dumps({'files':files,'pinned_runtime':pinned['version'],'pinned_model_revision':pinned['model_revision'],'weights':weights,'raw_asset_metadata':asset,'original_generation':json.loads((depot/'build/grove-art02/rock-source-v01/generation.json').read_text()),'new_generation':'None: inspected approved source reused.'},indent=2))
print('B3_PROVENANCE_OK',len(files),len(weights))
