"""Attach C3 presentation only to an isolated current-game copy."""
import shutil,sys
from pathlib import Path
review,game=map(lambda p:Path(p).resolve(),sys.argv[1:])
out=game/'c3';assert not out.exists();out.mkdir()
for folder in ['assets','textures']:shutil.copytree(review/folder,out/folder)
for name in ['kit.json','asset_view.gd','surface.gdshader']:shutil.copy2(review/name,out/name)
for name in ['native_resource.gd','native_review.gd']:shutil.copy2(Path(__file__).parent/name,out/name)
(out/'native_review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://c3/native_review.gd" id="1"]\n[node name="C3Native" type="Node3D"]\nscript=ExtResource("1")\n')
# Cooked glTF geometry references adjacent ../textures; only import paths change.
for path in out.rglob('*.import'):
    path.write_text(path.read_text().replace('res://assets/','res://c3/assets/').replace('res://textures/','res://c3/textures/'))
print('C3_NATIVE_ADAPTER_READY')
