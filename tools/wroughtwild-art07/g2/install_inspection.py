"""Install only G2 inspection additions into the verified disposable runtime."""
import json
import shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'build/art07/g2/v01'
TOOLS=ROOT/'tools/wroughtwild-art07/g2'
TARGET=OUT/'review/game/g2'
TARGET.mkdir(exist_ok=False)
for ident in ['fauna','canopy']:
    shutil.copy2(TOOLS/(ident+'.gd'),TARGET/(ident+'.gd'))
    base='[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://g2/fauna.gd" id="1"]\n[node name="G2Fauna" type="Node3D"]\nscript = ExtResource("1")\n' if ident=='fauna' else '[gd_scene load_steps=3 format=3]\n[ext_resource type="PackedScene" path="res://scenes/sandpit.tscn" id="1"]\n[ext_resource type="Script" path="res://g2/canopy.gd" id="2"]\n[node name="G2Canopy" instance=ExtResource("1")]\nscript = ExtResource("2")\n'
    (TARGET/(ident+'.tscn')).write_text(base)
fauna=json.loads((ROOT/'docs/art/concepts/environment/2026-09-09-frontier/asset-catalogue.json').read_text())['fauna_presentation']
(TARGET/'fauna.json').write_text(json.dumps(fauna,indent=2))
source=(OUT/'sealed/game/g1/review.gd').read_text()
# Same sealed camera/settling/sample loop; add the missing maximum and own the output path.
changes=[('"benchmark-" if','"g2-benchmark-" if'),('"frame_p95_ms":wall[285]','"frame_p95_ms":wall[285],"frame_worst_ms":wall[-1]'),('"gpu_p95_ms":gpu[285]','"gpu_p95_ms":gpu[285],"gpu_worst_ms":gpu[-1]'), ('\tvar interior:=player.position','\tvar setup_elapsed_ms:=Time.get_ticks_msec()\n\tvar interior:=player.position'), ('{"base":"6bb2e044dcd0bf1788896aa2c19cdf56fee93522"','{"setup_elapsed_ms":setup_elapsed_ms,"base":"6bb2e044dcd0bf1788896aa2c19cdf56fee93522"')]
for old,new in changes:
    assert source.count(old)==1,old
    source=source.replace(old,new)
(TARGET/'benchmark.gd').write_text(source)
scene=(OUT/'sealed/game/g1/review.tscn').read_text().replace('res://g1/review.gd','res://g2/benchmark.gd')
(TARGET/'benchmark.tscn').write_text(scene)
(OUT/'g2-adaptations.json').write_text(json.dumps({'benchmark_source':'sealed/game/g1/review.gd','benchmark_changes':changes,'purpose':'Add maximum-frame cost evidence; no timings, samples, cameras, shaders, gameplay, or G1 source changed.','inspection_additions':['fauna','canopy'],'runtime_addition':'review/game/g2'},indent=2))
core=json.loads((OUT/'core-jobs.json').read_text())
engine=core[0]['program']
jobs=[]
for ident,renderer in [('canopy',None),('fauna','forward_plus'),('fauna','gl_compatibility')]:
    name=ident+('-'+renderer if renderer else '')
    args=(['--rendering-method',renderer] if renderer else ['--headless','--fixed-fps','60'])+['--path',str(OUT/'review/game'),'res://g2/'+ident+'.tscn']
    jobs.append({'id':name,'program':engine,'arguments':args,'log':str(OUT/'logs'/(name+'.log')),'state':str(OUT/'users'/name)})
(OUT/'supplement-jobs.json').write_text(json.dumps(jobs,indent=2))
bench=json.loads((OUT/'benchmark-jobs.json').read_text())
for job in bench:job['arguments']=['res://g2/benchmark.tscn' if a=='res://g1/review.tscn' else a for a in job['arguments']]
(OUT/'g2-benchmark-jobs.json').write_text(json.dumps(bench,indent=2))
print('G2_INSPECTION_ADDITIONS_READY',len(jobs),len(bench))
