"""Install C4 presentation only in an isolated frozen current game."""
import shutil,sys
from pathlib import Path
review,game=map(lambda p:Path(p).resolve(),sys.argv[1:]);out=game/'c4';assert not out.exists();out.mkdir()
(out/'evidence').mkdir();(out/'evidence/.gdignore').write_text('')
shutil.copytree(review/'assets',out/'assets',ignore=shutil.ignore_patterns('*.import'))
shutil.copytree(review/'textures',out/'textures',ignore=shutil.ignore_patterns('*.import'))
for name in ['native_tree.gd','native_review.gd']:shutil.copy2(Path(__file__).parent/name,out/name)
(out/'native_review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://c4/native_review.gd" id="1"]\n[node name="C4Native" type="Node3D"]\nscript=ExtResource("1")\n')
print('C4_NATIVE_FIXTURE_PREPARED')
