import shutil,sys
from pathlib import Path
review,game=map(Path,sys.argv[1:]);out=game/'b1';assert not out.exists();out.mkdir()
shutil.copytree(review/'assets',out/'assets');shutil.copy2(review/'kit.json',out/'kit.json')
for name in ['native_tree.gd','native_review.gd']:shutil.copy2(Path(__file__).parent/name,out/name)
(out/'native_review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://b1/native_review.gd" id="1"]\n[node name="B1Native" type="Node3D"]\nscript=ExtResource("1")\n')
