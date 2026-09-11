"""Prepare a fresh diagnostic copy replacing D3 meshes with native PieceMesh forms.

Used to attribute the single dummy-backend diagnostic independently of the art.
This is a diagnostic control, never a qualifying source/import test.
"""
import argparse,shutil
from pathlib import Path
ap=argparse.ArgumentParser(); ap.add_argument('--game',type=Path,required=True); ap.add_argument('--output',type=Path,required=True); a=ap.parse_args()
worker=Path(__file__).resolve().parents[3]; out=a.output.resolve()
assert out.is_relative_to(worker/'build/art07/d3') and not out.exists()
shutil.copytree(a.game,out,ignore=shutil.ignore_patterns('.godot','*.import','*.log'))
p=out/'art07_d3/adapter.gd'; s=p.read_text()
start=s.index('\tvar packed:=load('); end=s.index('\nstatic func _collect',start)
s=s[:start]+'''\tvar sim=load("res://scripts/sim.gd").shared()
\tvar shape:Dictionary=sim.shape(id)
\tvar original:Mesh=PieceMesh.mesh_for(shape.get("form","box"),shape.size)
\tcache[key]=original
\treturn original
'''+s[end:]
p.write_text(s)
print('D3_NATIVE_PRIMITIVE_DIAGNOSTIC_COPY',out,'fresh-import then run art07_d3/checks.tscn; isolate APPDATA')
