"""Record fresh engine replay and recheck immutable canonical/prerequisite files."""
import sys,json
from pathlib import Path
from prerequisites import sha,verify

root,package,copy,logs=map(lambda p:Path(p).resolve(),sys.argv[1:])
records=json.loads((package/'manifest.json').read_text())
assert {p.relative_to(package).as_posix() for p in package.rglob('*') if p.is_file()}==set(records)|{'manifest.json'}
for rel,r in records.items():
    p=(package/rel).resolve();assert p.is_relative_to(package)
    assert p.stat().st_size==r['bytes'] and sha(p)==r['sha256'],p
original=json.loads((root/'audit-v03.json').read_text())
reopened=json.loads((logs/'audit.json').read_text())
assert original['models']==reopened['models']
assert original['packed_images']==reopened['packed_images']
evidence=json.loads((logs/'verification.json').read_text())
assert set(evidence)=={'forward_plus','gl_compatibility'}
pause=json.loads((copy/'review/input-pause-check.json').read_text())
assert pause['space_input'] and pause['resume'] and pause['paused_frames']==16
jobs={str(p.relative_to(logs)):json.loads(p.read_text()) for p in logs.rglob('*.job.json')}
assert len(jobs)>=10 and all(j['exit']==0 for j in jobs.values())
for p in [copy/'import.job.json',copy/'review.job.json']:
    j=json.loads(p.read_text());assert j['exit']==0;jobs[str(p)]=j
environment=json.loads((root/'environment-final.json').read_text())
for path,r in environment['sources'].items():assert sha(path)==r['sha256'],path
result={'canonical_path':str(package),'manifest_sha256':sha(package/'manifest.json'),'verified_canonical_files_after_replay':len(records),'canonical_bytes':sum(r['bytes'] for r in records.values()),'fresh_copy':str(copy),'fresh_models_equal':True,'fresh_packed_images_equal':True,'space_input':pause,'combined_evidence':evidence,'fresh_job_records':jobs,'prerequisites_unchanged':verify(),'original_source_hashes_unchanged':True,'replay_scope':'Fresh copy reruns packed-source/GLB audit, both-renderer static captures/contact checks, actual Space pause, and native flow/partial/final reloads. Motion/walk sequences and quiet benchmarks were validated before packaging and transferred with exact hashes; those jobs are not repeated or represented as fresh measurements.'}
out=root/'delivery-verification.json';assert not out.exists();out.write_text(json.dumps(result,indent=2)+'\n')
print('C4_DELIVERY_VERIFIED',len(records),sha(package/'manifest.json'))
