"""Run after first Godot import and before reimport. Configure actual 3D maps.
Import metadata is generated only in a disposable review; never tracked in Git.
"""
import re
import sys
from pathlib import Path
review=Path(sys.argv[1]).resolve()
count=0
for path in sorted((review/'textures').glob('*.png.import')):
    value=path.read_text()
    value=re.sub(r'mipmaps/generate=\w+','mipmaps/generate=true',value)
    value=re.sub(r'compress/mode=\d+','compress/mode=0',value)
    value=re.sub(r'compress/normal_map=\d+','compress/normal_map='+('1' if '_normal.png' in path.name else '2'),value)
    value=re.sub(r'detect_3d/compress_to=\d+','detect_3d/compress_to=0',value)
    path.write_text(value)
    count+=1
assert count==42,count
print('D4_3D_IMPORT_SETTINGS_OK',count,'lossless, mipmapped, explicit normal maps')
