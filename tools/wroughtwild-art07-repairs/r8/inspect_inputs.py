"""Read-only R8 input delta and overlap inspection."""
import collections, difflib, hashlib, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
DOCS=ROOT/'docs/prototype/art07-repairs/2026-09-14'
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):
    with p.open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()
def inputs():
    return read(DOCS/'inputs.json'),read(DOCS/'deliveries.json')['deliveries']
def payload(ident,pkg): return pkg/('runtime' if ident in ['r3','r5'] else 'changed-source' if ident=='r4' else '')
if __name__=='__main__':
    pins,deliveries=inputs(); base=Path(pins['runtime_source']['path']); paths=collections.defaultdict(list)
    for ident in sorted(deliveries):
        pkg=Path(deliveries[ident]['package']['path']); c=read(pkg/'changes.json')
        print(ident,'declared',len(c['files']),'extra fixtures',len(c.get('fixture_only_files',[])))
        for row in c['files']:
            name=row['path']; paths[name].append((ident,row,payload(ident,pkg)/name))
        if ident=='r5':print('r5 fixtures',c.get('fixture_only_files'))
    for name,rows in paths.items():
        if len(rows)<2: continue
        print('OVERLAP',name,','.join(x[0] for x in rows))
        if name.endswith('.gd'):
            for ident,row,path in rows:
                print(ident,''.join(difflib.unified_diff((base/name).read_text(encoding='utf-8-sig').splitlines(True),path.read_text(encoding='utf-8-sig').splitlines(True),fromfile='G1',tofile=ident)))
