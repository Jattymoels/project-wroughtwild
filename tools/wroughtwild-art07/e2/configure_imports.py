"""Explicit 3D linear-normal/ORM imports; never run in the canonical package."""
import re,sys
from pathlib import Path
folder=Path(sys.argv[1]).resolve();count=0
for p in (folder/'e2/textures').glob('*.png.import'):
    s=p.read_text();s=re.sub(r'mipmaps/generate=\w+','mipmaps/generate=true',s)
    s=re.sub(r'compress/mode=\d+','compress/mode=0',s)
    s=re.sub(r'compress/normal_map=\d+','compress/normal_map='+('1' if '_normal.png' in p.name else '2'),s)
    s=re.sub(r'detect_3d/compress_to=\d+','detect_3d/compress_to=0',s)
    p.write_text(s);count+=1
assert count==9,count
print('E2_IMPORT_SETTINGS_OK',count)
