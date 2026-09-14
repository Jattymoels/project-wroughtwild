import shutil
from common import *
guard()
r=GAME/'r7';r.mkdir(exist_ok=False)
shutil.copy2(TOOLS/'source_probe.gd',r/'source_probe.gd')
(r/'source_probe.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://r7/source_probe.gd" id="1"]\n[node name="SourceProbe" type="Node"]\nscript = ExtResource("1")\n')
write(OUT/'source-probe-jobs.json',[job('source-probe-01','source_probe')])
