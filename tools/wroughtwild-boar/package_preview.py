"""Encode engine frame sequences, and build a portable local art handoff.

Uses the existing workspace Python/Pillow runtime; does not generate new imagery.
-- SURFACE RIG FAR REVIEW NEW_PACKAGE
"""
import hashlib,json,shutil,sys
from pathlib import Path
from PIL import Image

surface,rig,far,review,output=[Path(p).resolve() for p in sys.argv[1:]]
assert not output.exists();output.mkdir(parents=True)
editable=output/'editable';editable.mkdir()
shutil.copy2(far/'boar-candidate.blend',editable/'boar-candidate.blend')
project=output/'review';project.mkdir()
for name in ['project.godot','review.gd','review.tscn','boar_scar.gdshader','boar-study.json',
             'base.png','orm.png','scar-mask.png','normal.png','boar-near.glb','boar-mid.glb','boar-far.glb',
             'far-base.png','far-orm.png','far-scar.png','far-normal.png','surface-report.json','rig-report.json','far-report.json']:
    shutil.copy2(review/name,project/name)
# Import settings, not generated Godot caches. Remove generated IDs and paths.
for file in project.glob('*.glb'):
    (project/(file.name+'.import')).write_text('[remap]\nimporter="scene"\ntype="PackedScene"\n[params]\nmeshes/generate_lods=false\nanimation/fps=100\n')
for file in project.glob('*.png'):
    (project/(file.name+'.import')).write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n[params]\ncompress/mode=0\nmipmaps/generate=true\ndetect_3d/compress_to=0\n')
evidence=output/'evidence';evidence.mkdir()
for file in (review/'evidence').iterdir():
    if '-frame-' not in file.name:shutil.copy2(file,evidence/file.name)
for lighting in ['day','shade']:
    frames=[Image.open(file).convert('RGB').resize((800,600),Image.Resampling.LANCZOS) for file in sorted((review/'evidence').glob(lighting+'-frame-*.png'))]
    assert len(frames)==192
    # One palette across the sequence prevents frame-to-frame palette flicker.
    contact=Image.new('RGB',(960,960))
    for i,frame in enumerate(frames):contact.paste(frame.resize((80,60)),((i%12)*80,(i//12)*60))
    palette=contact.quantize(colors=256)
    frames=[frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in frames]
    # GIF has centisecond timing; six frames per 250 ms gives exactly 24 fps.
    durations=[40,40,40,40,40,50]*32
    frames[0].save(evidence/(lighting+'-loop.gif'),save_all=True,append_images=frames[1:],duration=durations,loop=0,optimize=True)
    assert sum(durations)==8000
manifest={'purpose':'ART-01 isolated editable boar and importable Godot material/movement review. Not installed in the game.',
          'source_sha256':json.loads((surface/'surface-report.json').read_text())['source_sha256'],
          'local_source':str(surface),'local_rig':str(rig),'local_far':str(far),
          'files':{str(file.relative_to(output)).replace('\\','/'):{'bytes':file.stat().st_size,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()} for file in output.rglob('*') if file.is_file()}}
(output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('BOAR_PACKAGE_OK '+str(output))
