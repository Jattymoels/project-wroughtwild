"""Copy a clean local handoff; encode actual frame sequences for review."""
import hashlib,json,shutil,sys
from pathlib import Path
import numpy as np
from PIL import Image
review,editable,tree,rock,normal,out=map(Path,sys.argv[1:])
assert not out.exists();out.mkdir(parents=True)
deliver=out/'review';deliver.mkdir()
for p in review.iterdir():
    if p.is_file() and p.suffix in ['.glb','.png','.json','.gd','.gdshader','.tscn','.godot','.import']:
        shutil.copy2(p,deliver/p.name)
(out/'editable').mkdir()
for p in [editable/'emberroot-grove.blend',tree/'tree-finished.blend',rock/'rock-finished.blend',normal/'tree-normal-bake.blend']:
    shutil.copy2(p,out/'editable'/p.name)
evidence=out/'evidence';evidence.mkdir()
for p in (review/'evidence').iterdir():
    if p.is_file():shutil.copy2(p,evidence/p.name)
walk=json.loads((review/'evidence/walk-manifest.json').read_text())
for mood in ['day','dusk']:
    paths=sorted((review/'evidence'/('walk-'+mood)).glob('*.png'))
    assert len(paths)==walk['frames_per_mood']
    frames=[Image.open(p).convert('RGB').resize((720,450),Image.Resampling.LANCZOS) for p in paths]
    frames[0].save(evidence/(mood+'-walk.webp'),save_all=True,append_images=frames[1:],duration=83,loop=0,quality=80,method=4)
    # Short GIF preview uses a global palette to avoid palette flicker.
    preview=[f.resize((480,300),Image.Resampling.LANCZOS) for f in frames[70:118]]
    sheet=Image.new('RGB',(480,300*6))
    for i,f in enumerate(preview[::8]):sheet.paste(f,(0,300*i))
    palette=sheet.quantize(colors=192,method=Image.Quantize.MEDIANCUT)
    indexed=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in preview]
    indexed[0].save(evidence/(mood+'-clearing.gif'),save_all=True,append_images=indexed[1:],duration=83,loop=0,disposal=2,optimize=False)
(out/'README.txt').write_text('EMBERROOT GROVE / ART-02\nOpen editable/emberroot-grove.blend for the packed composition. Blender shows steady scar emission; the exact pulse and walking review are in review/project.godot.\nUse the repository run_review.ps1 with this review folder to keep APPDATA isolated. WASD/mouse walk/look, L lighting, M scars, Space pause, R return, Esc release.\nThis is an isolated art setting, with no normal save, native rules, loot, combat or world adoption. Raw tree/rock source hashes and provenance are in the repository report. Do not mistake successful imports for final owner art acceptance.\n')
manifest={str(p.relative_to(out)).replace('\\','/'):{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in out.rglob('*') if p.is_file()}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('GROVE_PACKAGE_OK',out,len(manifest))
