"""Read-only final recheck of the approved source packages and inspected inputs."""
import argparse,hashlib,json
from pathlib import Path
ap=argparse.ArgumentParser(); ap.add_argument('--provenance',type=Path,required=True); ap.add_argument('--depot',type=Path,required=True); ap.add_argument('--output',type=Path,required=True); a=ap.parse_args()
data=json.loads(a.provenance.read_text()); checked={}
def check(p,expected):
    with p.open('rb') as f: actual=hashlib.file_digest(f,'sha256').hexdigest()
    assert actual==expected,str(p)
    checked[str(p)]=actual
for package in data['packages']:
    base=Path(package['path']); check(base/'manifest.json',package['manifest_sha256'])
    for entry in package['verified_sources']: check(base/entry['path'],entry['sha256'])
for rel,expected in data['inputs'].items(): check(a.depot/rel,expected)
for name,expected in data['binaries'].items(): check(Path(name),expected)
check(a.depot/'tools/wroughtwild-trellis/install-manifest.json',data['install_manifest_sha256'])
assert not a.output.exists()
a.output.write_text(json.dumps({'source_files_reverified':len(checked),'unchanged':checked,'weights':'All ten fully hashed at initial preparation; generator not invoked.'},indent=2)+'\n')
print('D1_ORIGINAL_INPUTS_UNCHANGED',len(checked))
