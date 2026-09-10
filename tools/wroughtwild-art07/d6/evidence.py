"""Curate unchanged stills and compact camera-motion previews; keep original frames."""
import json,shutil,sys
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[3];version,review=map(Path,sys.argv[1:])
out=root/'docs/art/leyline-studies/2026-09-09/art07/d6';out.mkdir(parents=True,exist_ok=True)
for name in ['blender-overview.png','blender-iron.png','blender-bronze.png','blender-steel.png','blender-silver.png']:shutil.copy2(version/'blender'/name,out/name)
for method in ['forward_plus','gl_compatibility']:
    for name in ['overview','shade','distance-10','distance-24','unlit']:
        shutil.copy2(review/'evidence'/f'{method}-{name}.png',out/f'{method}-{name}.png')
    frames=[Image.open(p).convert('RGB').resize((1000,562),Image.Resampling.LANCZOS) for p in sorted((review/'evidence'/(method+'-motion')).glob('*.png'))]
    assert len(frames)==96
    frames[0].save(out/(method+'-motion.webp'),save_all=True,append_images=frames[1:],duration=65,loop=0,quality=86,method=4)
    for f in frames:f.close()
print('D6_EVIDENCE_OK',out)
