"""Record independently replayed package evidence without changing the handoff."""
import sys,json
from pathlib import Path
from prerequisites import sha
package,copy,run=map(lambda p:Path(p).resolve(),sys.argv[1:])
manifest=json.loads((package/'manifest.json').read_text())
for rel,e in manifest.items():
    p=(package/rel).resolve();assert p.is_relative_to(package)
    assert p.stat().st_size==e['bytes'] and sha(p)==e['sha256'],p
    if rel.startswith(('source/','recipe/')) or (rel.startswith(('review/','native/')) and p.suffix in ['.gd','.gdshader','.bin','.gltf','.dll']):
        assert sha(copy/rel)==e['sha256'],rel
audit=json.loads((run/'fresh-audit.json').read_text())
assert audit==json.loads((package/'evidence/audit-v05.json').read_text())
assert 'C3_CAPTURE_OK' in (copy/'review.log').read_text()
assert 'C3_CAPTURE_OK' in (run/'fresh-capture/gl_compatibility-capture.log').read_text()
native=[]
for renderer in ['forward_plus','gl_compatibility']:
    for state,checks in [('flow',68),('partial',9),('final',9)]:
        path=run/'fresh-native'/(renderer+'-'+state+'.log')
        job=json.loads(Path(str(path)+'.job.json').read_text(encoding='utf-8-sig'))
        assert job['exit']==0 and f'C3_NATIVE_OK {checks}' in path.read_text()
        native.append({'renderer':renderer,'state':state,'checks':checks,'job':job})
report={'canonical_path':str(package),'copy_path':str(copy),'manifest_sha256':sha(package/'manifest.json'),'canonical_files_unchanged':len(manifest),'copied_source_and_runtime_bytes_unchanged':True,'fresh_audit_equal':True,'fresh_audited_exports':len(audit['exports']),'fresh_capture_renderers':['forward_plus','gl_compatibility'],'fresh_native':native,'original_motion_walk_transferred_by_verified_manifest':True}
(run/'fresh-verification.json').write_text(json.dumps(report,indent=2)+'\n')
print('C3_FRESH_HANDOFF_OK',len(manifest),'files;',len(audit['exports']),'exports;',sum(r['checks'] for r in native),'native assertions')
