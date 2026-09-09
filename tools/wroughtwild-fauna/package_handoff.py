"""Copy a checked fauna handoff, excluding caches and imported engine artefacts.

WOLF_REVIEW STAG_REVIEW WOLF_RIG STAG_RIG GALLERY NEW_OUTPUT
"""
import hashlib,json,shutil,sys
from pathlib import Path

wolf,stag,wolf_rig,stag_rig,gallery,output=map(Path,sys.argv[1:])
assert not output.exists()
output.mkdir(parents=True)
repo=Path(__file__).resolve().parents[2]
for kind,review,rig in [('wolf',wolf,wolf_rig),('stag',stag,stag_rig)]:
    root=output/kind;root.mkdir();dest=root/'review';dest.mkdir()
    names=['project.godot','review.tscn','review.gd','fauna_scar.gdshader',kind+'.json','base.png','orm.png','normal.png','scar-mask.png','rig-report.json','surface-report.json','verification.json']
    names += [kind+'-'+level+'.glb' for level in ['near','mid','far']]
    for name in names:shutil.copy2(review/name,dest/name)
    for name in [kind+'-candidate.blend','source-audit.json']:shutil.copy2(rig/name,root/name)
    shutil.copytree(review/'evidence',root/'evidence',ignore=shutil.ignore_patterns('*-frame-*.png'))
    for file in dest.glob('*.glb'):
        file.with_name(file.name+'.import').write_text('[remap]\nimporter="scene"\ntype="PackedScene"\n[params]\nmeshes/generate_lods=false\nanimation/fps=100\n')
    for file in dest.glob('*.png'):
        file.with_name(file.name+'.import').write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n[params]\ncompress/mode=0\nmipmaps/generate=true\ndetect_3d/compress_to=0\n')
shutil.copytree(repo/'tools/wroughtwild-fauna',output/'recipe',ignore=shutil.ignore_patterns('__pycache__','*.pyc','*.uid','*.import'))
shutil.copytree(repo/'docs/art/leyline-studies/2026-09-09/fauna-art03',output/'published-evidence')
gallery_dest=output/'grove-gallery';gallery_dest.mkdir()
for file in gallery.iterdir():
    if file.is_file() and file.suffix in ('.gd','.gdshader','.godot','.tscn','.glb','.png','.json'):
        shutil.copy2(file,gallery_dest/file.name)
shutil.copytree(gallery/'evidence',gallery_dest/'evidence')
for file in gallery_dest.glob('*.glb'):
    file.with_name(file.name+'.import').write_text('[remap]\nimporter="scene"\ntype="PackedScene"\n[params]\nmeshes/generate_lods=false\nanimation/fps=100\n')
for file in gallery_dest.glob('*.png'):
    file.with_name(file.name+'.import').write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n[params]\ncompress/mode=0\nmipmaps/generate=true\ndetect_3d/compress_to=0\n')
# The final manifest is produced after clean reimport checks, excluding generated caches.
print('FAUNA_HANDOFF_COPIED',output)
