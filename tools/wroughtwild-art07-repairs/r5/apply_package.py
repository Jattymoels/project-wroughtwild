"""Apply the sealed R5 visual delta to a fresh prepared R5 runtime."""
import argparse,hashlib,json,shutil
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--package',required=True,type=Path);p.add_argument('--runtime',required=True,type=Path);a=p.parse_args();src=a.package.resolve();dest=a.runtime.resolve();allowed=Path('D:/project-wroughtwild-art07-r5/build/art07-repairs/r5').resolve()
assert dest.is_relative_to(allowed) and dest.name=='runtime' and src!=dest and not dest.is_relative_to(src)
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.file_digest(p.open('rb'),'sha256').hexdigest()
manifest=read(src/'manifest.json')['files'];actual={p.relative_to(src).as_posix() for p in src.rglob('*') if p.is_file() and p!=src/'manifest.json'};assert actual==set(manifest)
for name,row in manifest.items():
 f=(src/name).resolve();assert f.is_relative_to(src) and f.stat().st_size==row['bytes'] and sha(f)==row['sha256'],name
changes=read(src/'changes.json')['files']
for row in changes:
 f=(dest/row['path']).resolve();assert f.is_relative_to(dest) and sha(f)==row['before_sha256'],row['path']
 assert sha(src/'runtime'/row['path'])==row['after_sha256']
for row in changes:
 f=dest/row['path'];shutil.copy2(src/'runtime'/row['path'],f);assert sha(f)==row['after_sha256']
print('R5_SEALED_DELTA_APPLIED',len(changes))
