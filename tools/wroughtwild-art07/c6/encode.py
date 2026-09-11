"""Encode only actual Godot frames, retaining originals; no motion interpolation."""
import sys,json
from pathlib import Path
from PIL import Image
review,out=[Path(p).resolve() for p in sys.argv[1:]];assert not out.exists();out.mkdir(parents=True)
record={}
for renderer in ['forward_plus','gl_compatibility']:
    base=review/'evidence'/renderer
    paths=sorted((base/'motion-77').glob('pulse-*.png'));assert len(paths)==48
    frames=[Image.open(p).convert('RGB').resize((960,600),Image.Resampling.LANCZOS) for p in paths]
    frames[0].save(out/(renderer+'-pulse.gif'),save_all=True,append_images=frames[1:],duration=94,loop=0,optimize=True)
    for name in ['smithy','collection']:
        paths=sorted((base/'walk-77').glob('walk-'+name+'-*.png'));assert len(paths)>8
        frames=[Image.open(p).convert('RGB').resize((960,600),Image.Resampling.LANCZOS) for p in paths]
        frames[0].save(out/(renderer+'-'+name+'-walk.gif'),save_all=True,append_images=frames[1:],duration=167,loop=0,optimize=True)
        record[renderer+'-'+name]={'frames':len(paths),'source':'actual sampled controller views, no synthetic frames','duration_note':'167 ms display per sampled image; capture waits are not a performance measurement'}
(out/'motion.json').write_text(json.dumps(record,indent=2)+'\n');print('C6_MEDIA_OK')
