"""Post-seal validation sidecar. Never modifies the canonical handoff."""
import hashlib,json,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];BUILD=ROOT/'build/art07/f2'
gallery=ROOT/'docs/art/leyline-studies/2026-09-09/art07/f2'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
package=BUILD/'v04/handoff';manifest=read(package/'manifest.json')
for f in manifest['files']:
    p=package/f['path'];assert sha(p)==f['sha256'] and p.stat().st_size==f['bytes']
checks=BUILD/'v04/fresh-checks'
for mode,expected in [('import',None),('check','F2_CHECKS 50 checks 0 failures'),('restart','F2_RESTART 29 checks 0 failures')]:
    assert read(checks/(mode+'.json'))['exit_code']==0
    if expected:assert expected in (checks/(mode+'.stdout')).read_text()
    errors=(checks/(mode+'.stderr')).read_text();assert 'SCRIPT ERROR' not in errors and '\nERROR:' not in errors
reopen=read(BUILD/'v04/fresh-reopen/reopen.json')
assert len(reopen['imports'])==7 and all(m['degenerate']==0 for m in reopen['imports'].values())
assert all(all(i['packed'] for i in master['images']) for master in reopen['masters'].values())
reopen_command=read(BUILD/'v04/fresh-reopen.log.json');assert reopen_command['exit_code']==0
source=BUILD/'v04/fresh-reopen/reopened-winch-and-basket.png'
shutil.copy2(source,gallery/'blender-reopened-package.png')
report={'package':str(package),'manifest_sha256':sha(package/'manifest.json'),'files':len(manifest['files']),'bytes':sum(f['bytes'] for f in manifest['files']),'validated_copy':str(BUILD/'v04/validation-copy'),'fresh_check_commands':{m:read(checks/(m+'.json')) for m in ['import','check','restart']},'fresh_reopen_command':reopen_command,'fresh_reopen':reopen,'reopened_render_sha256':sha(source),'sealed_package_unchanged_after_copy_import':True,'scope_audit':read(BUILD/'scope-audit.json')}
(gallery/'handoff-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('F2_FINAL_AUDIT_OK',report['manifest_sha256'],report['files'])
