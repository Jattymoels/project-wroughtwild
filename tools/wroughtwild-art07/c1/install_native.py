import shutil,sys
from pathlib import Path
review,game=map(lambda p:Path(p).resolve(),sys.argv[1:]);out=game/'c1';out.mkdir(exist_ok=True)
for n in ['assets','textures']:
    assert not (out/n).exists();shutil.copytree(review/n,out/n)
for n in ['kit.json','present.gd','surface.gdshader','forest-floor.png']:shutil.copy2(review/n,out/n)
for n in ['native_resource.gd','native_review.gd']:shutil.copy2(Path(__file__).parent/n,out/n)
(out/'native_review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://c1/native_review.gd" id="1"]\n[node name="C1Native" type="Node3D"]\nscript=ExtResource("1")\n')
print('C1_NATIVE_ART_INSTALLED',out)
