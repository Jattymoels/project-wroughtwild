"""C6 read-only package verification, adapted from B4's published verifier."""
import hashlib, json, sys
from pathlib import Path

DEPOT = Path('C:/Users/Matty/Dev/project-wroughtwild')
REVISION = '4b5d89b376765fbf4d46049aa099e0bb154a82da'
PACKAGES = {
    'b3': (DEPOT/'build/art07/b3/worktree/build/art07/b3/v01/handoff-v02', 'b53961b58ddf4720ec51f77adfe1e87860890f4c3d9b68ec3f6de27102b39321'),
    'b4': (DEPOT/'build/art07/b4/worktree/build/art07/b4/v01/handoff-v01', '60392ada2fd8eedb52ee091cfead2c7afa1da200f47d0994bafaef7404bace71'),
}

def sha(path):
    with open(path, 'rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def verify():
    result = {}
    for key, (root, expected) in PACKAGES.items():
        assert sha(root/'manifest.json') == expected, key
        records = json.loads((root/'manifest.json').read_text())
        for relative, entry in records.items():
            path = (root/relative).resolve()
            assert path.is_relative_to(root.resolve())
            assert path.stat().st_size == entry['bytes'] and sha(path) == entry['sha256'], path
        result[key] = {'path': str(root), 'manifest_sha256': expected, 'files': len(records), 'bytes': sum(e['bytes'] for e in records.values())}
    return result

if __name__ == '__main__':
    output = Path(sys.argv[1]); output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(verify(), indent=2)+'\n')
    print(output.read_text())
