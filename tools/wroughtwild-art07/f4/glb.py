"""Read-only glTF binary inventory and actual primitive counts."""
import json,struct,sys
from pathlib import Path
def read(path):
 b=Path(path).read_bytes();n=struct.unpack_from('<I',b,12)[0];return json.loads(b[20:20+n])
if __name__=='__main__':
 for p in map(Path,sys.argv[1:]):
  d=read(p);print(p.name,json.dumps(d.get('nodes',[]),indent=2))
