"""Verify fresh handoff execution and retained canonical/source bytes."""
import json,sys
from pathlib import Path
from prerequisites import sha
package,copy,audit,out=[Path(p).resolve() for p in sys.argv[1:]]
manifest=json.loads((package/'manifest.json').read_text())
for rel,item in manifest.items():
    assert sha(package/rel)==item['sha256'],rel
    # Imports may rewrite .import metadata; executable recipes and asset data must not change.
    if rel.startswith(('models/','native/game/','native/data/')) and not rel.endswith('.import'):
        assert sha(copy/rel)==item['sha256'],rel
reopened=json.loads(audit.read_text())
selected=json.loads((package/'evidence/audit-v06-rays.json').read_text())
assert reopened==selected,'packed model/export audit changed in fresh copy'
checks={}
for renderer in ['forward_plus','gl_compatibility']:
    for mode in ['check','capture']:
        report=json.loads((copy/'native/evidence'/renderer/(mode+'-77')/'report.json').read_text())
        original=json.loads((package/'evidence/native'/renderer/(mode+'-77')/'report.json').read_text())
        assert report['failures']==0 and report['checks']==original['checks'],(renderer,mode)
        assert report['native_before']==original['native_before'],(renderer,mode)
        if mode=='capture':assert len(list((copy/'native/evidence'/renderer/'capture-77').glob('*.png')))==77
        checks[renderer+'/'+mode]={'checks':report['checks'],'failures':report['failures']}
record={'package':str(package),'copy':str(copy),'manifest_sha256':sha(package/'manifest.json'),'canonical_files':len(manifest),'canonical_unchanged':True,'fresh_model_audit_identical':True,'fresh_checks':checks}
out.write_text(json.dumps(record,indent=2)+'\n');print(json.dumps(record,indent=2))
