"""Reviewable text-only overlap resolutions, each against its named source."""
import difflib
from pathlib import Path
from inspect_inputs import ROOT,read,inputs,payload,sha
from compose import write
pins,ds=inputs();out=ROOT/'build/art07-repairs/r8/v01';game=out/'runtime';doc=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r8';diff=[];records=[]
for name,owner in [('game/g1/art.gd','g1'),('game/g1/materials.gd','g1'),('game/scripts/player.gd','g1'),('game/r3/materials.gd','r3'),('game/r6/surface.gd','r6'),('game/r7/cover.gd','r7')]:
    before=Path(pins['runtime_source']['path'])/name if owner=='g1' else payload(owner,Path(ds[owner]['package']['path']))/name
    after=game/name
    diff.extend(difflib.unified_diff(before.read_text(encoding='utf-8-sig').splitlines(True),after.read_text(encoding='utf-8-sig').splitlines(True),fromfile=owner+':'+name,tofile='r8:'+name))
    records.append({'path':name,'comparison_owner':owner,'before':str(before),'before_sha256':sha(before),'after_sha256':sha(after)})
write(doc/'overlap-resolutions.diff',''.join(diff));write(doc/'overlap-resolutions.json',records)
print('R8_TEXT_OVERLAPS_REVIEWABLE',len(records))
