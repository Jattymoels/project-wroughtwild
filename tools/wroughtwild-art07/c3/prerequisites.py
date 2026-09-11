"""C3 read-only published prerequisite verification. No model generation needed."""
import hashlib, json, sys
from pathlib import Path

DEPOT = Path('C:/Users/Matty/Dev/project-wroughtwild')
REVISION = 'f5e481a28fb032a7d4d7ebec1e3e01cc1aca0bc9'
PACKAGES = {
    'b1': (Path('C:/Users/Matty/Dev/project-wroughtwild-art07-b1/build/art07/b1/v01/canopy-handoff-v02'), '00a244253614b8c58213a15f929e48fd65c9aec0bb3489600646497bfcbaf7d0'),
    'b2': (DEPOT/'build/art07/b2/worktree/build/art07/b2/v10/handoff', 'bb4a50ea353a1fdb964542e46afc3f1549f7e45b3b004ab7b4130ae1a7d50e62'),
}

def sha(path):
    with open(path, 'rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def verify():
    result = {}
    for key, (root, expected) in PACKAGES.items():
        manifest = root/'manifest.json'
        assert sha(manifest) == expected, (key, 'manifest')
        records = json.loads(manifest.read_text())
        for relative, entry in records.items():
            path = (root/relative).resolve()
            assert path.is_relative_to(root.resolve())
            assert path.stat().st_size == entry['bytes'] and sha(path) == entry['sha256'], path
        result[key] = {'path': str(root), 'manifest_sha256': expected, 'verified_files': len(records)}
    return result

if __name__ == '__main__':
    result = verify()
    Path(sys.argv[1]).write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(result, indent=2))
