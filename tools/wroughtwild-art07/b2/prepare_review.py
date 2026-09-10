import sys,shutil,json
from pathlib import Path
kit,depot,out=map(Path,sys.argv[1:]);assert not out.exists();out.mkdir(parents=True)
src=Path(__file__).parent
shutil.copytree(kit/'assets',out/'assets')
for name in ['kit.json','plant.gdshader','floor.gdshader','review.gd']:shutil.copy2(src/name,out/name)
for name in ['layout.json','kit-report.json']:shutil.copy2(kit/name,out/name)
shutil.copy2(depot/'docs/art/leyline-studies/2026-09-09/grove-art02/forest-floor.png',out/'forest-floor.png')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="ART07B2 Groundcover review"\nrun/main_scene="res://review.tscn"\n[display]\nwindow/size/viewport_width=1280\nwindow/size/viewport_height=900\n[rendering]\nrenderer/rendering_method="gl_compatibility"\ntextures/default_filters/use_nearest_mipmap_filter=false\n')
(out/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://review.gd" id="1"]\n[node name="Groundcover" type="Node3D"]\nscript=ExtResource("1")\n')
