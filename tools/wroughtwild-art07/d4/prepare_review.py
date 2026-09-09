"""Copy selected sources to a fresh isolated review. Never modifies the master."""
import json
import shutil
import sys
from pathlib import Path
here=Path(__file__).resolve().parent
textures,blender,out=map(lambda p:Path(p).resolve(),sys.argv[1:])
out.mkdir(parents=True,exist_ok=False)
shutil.copytree(textures,out/'textures')
for src,name in [('review.gd','review.gd'),('review-project.godot','project.godot'),('materials.json','materials.json')]:
    shutil.copy2(here/src,out/name)
shutil.copy2(blender/'d4_proxies.glb',out/'d4_proxies.glb')
(out/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://review.gd" id="1"]\n\n[node name="D4Review" type="Node3D"]\nscript = ExtResource("1")\n')
print('D4_REVIEW_PREPARED',out)
