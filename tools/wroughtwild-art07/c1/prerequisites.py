"""Read-only complete manifest verification of C1's published source packages."""
import hashlib, json, sys
from pathlib import Path

DEPOT = Path('C:/Users/Matty/Dev/project-wroughtwild')
PACKAGES = {
    'b4_context': (DEPOT/'build/art07/b4/worktree/build/art07/b4/v01/handoff-v01', '60392ada2fd8eedb52ee091cfead2c7afa1da200f47d0994bafaef7404bace71'),
    'b1': (Path('C:/Users/Matty/Dev/project-wroughtwild-art07-b1/build/art07/b1/v01/canopy-handoff-v02'), '00a244253614b8c58213a15f929e48fd65c9aec0bb3489600646497bfcbaf7d0'),
    'b2': (DEPOT/'build/art07/b2/worktree/build/art07/b2/v10/handoff', 'bb4a50ea353a1fdb964542e46afc3f1549f7e45b3b004ab7b4130ae1a7d50e62'),
    'b3': (DEPOT/'build/art07/b3/worktree/build/art07/b3/v01/handoff-v02', 'b53961b58ddf4720ec51f77adfe1e87860890f4c3d9b68ec3f6de27102b39321'),
    'art02': (DEPOT/'build/grove-art02/emberroot-handoff', '0a4f26a74335bcceddd2d31f9df3774d415f5aca6d982e9cc5305faf6ac9bba8'),
}
def sha(path):
    with open(path,'rb') as f:
        return hashlib.file_digest(f,'sha256').hexdigest()
def verify():
    result={}
    for key,(root,expected) in PACKAGES.items():
        manifest=root/'manifest.json'
        assert sha(manifest)==expected, (key,'manifest')
        records=json.loads(manifest.read_text())
        for rel,entry in records.items():
            path=(root/rel).resolve()
            assert path.is_relative_to(root.resolve())
            assert path.stat().st_size==entry['bytes'] and sha(path)==entry['sha256'],path
        result[key]={'path':str(root),'manifest_sha256':expected,'verified_files':len(records),'bytes':sum(e['bytes'] for e in records.values())}
    return result
if __name__=='__main__':
    result=verify()
    Path(sys.argv[1]).write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))
