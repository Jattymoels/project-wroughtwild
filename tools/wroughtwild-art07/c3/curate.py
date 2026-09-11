"""Copy a compact selection of actual media/reports for the scoped Git receipt."""
import sys,json,shutil
from pathlib import Path
from prerequisites import sha
run=Path(sys.argv[1]).resolve()
out=Path(__file__).resolve().parents[3]/'docs/art/leyline-studies/2026-09-09/art07/c3'
out.mkdir(parents=True,exist_ok=True)
names=['blender-hero.png','blender-hero-incision-off.png','blender-cork-full.png','blender-amber-cut.png']
for renderer in ['forward_plus','gl_compatibility']:
    names += [renderer+'-'+name for name in ['day.png','dusk.png','incision-off.png','incision-on.png','cork-worked.png','native-partial.png','native-cork-depleting.png','pulse.webp','wind.webp','walk.webp','native-fall.webp']]
for name in names:shutil.copy2(run/'media-v02'/name,out/name)
for name in ['environment.json','prerequisites.json','audit-v05.json','validation.json','powershell-parse.json']:
    shutil.copy2(run/name,out/name)
shutil.copy2(run/'media-v02/media-verification.json',out/'media-verification.json')
shutil.copy2(run/'kit-v08/models.json',out/'models.json')
shutil.copy2(run/'review-v03/cook.json',out/'texture-cook.json')
for renderer in ['forward_plus','gl_compatibility']:
    shutil.copy2(run/'review-v03/evidence'/renderer/'benchmark.json',out/(renderer+'-benchmark.json'))
manifest={name:{'bytes':(out/name).stat().st_size,'sha256':sha(out/name)} for name in names}
(out/'media-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('C3_CURATED_MEDIA',len(names),sum(e['bytes'] for e in manifest.values()))
