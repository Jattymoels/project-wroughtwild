"""Fresh diagnostic with identical review cameras but zero C6 render instances."""
import sys,subprocess,json
from pathlib import Path
current,kit,out=[Path(p).resolve() for p in sys.argv[1:]]
subprocess.run([sys.executable,str(Path(__file__).with_name('prepare_review.py')),str(current),str(kit),str(out)],check=True)
path=out/'game/c6/adapter.gd';source=path.read_text()
begin=source.index('func attach(');end=source.index('func tick(',begin)
source=source[:begin]+'''func attach(original: MeshInstance3D, id: String, fit: Vector3) -> void:
\tfor entry in entries:
\t\tif entry.original==original:return
\tentries.append({"original":original,"id":id})

func tick(delta: float, camera: Camera3D) -> void:
\tpass
'''
path.write_text(source)
path=out/'game/c6/native_review.gd';source=path.read_text()
source=source.replace('caption.text="C6 · "+id','caption.text="NATIVE BASELINE · "+id')
path.write_text(source)
(out/'diagnostic.json').write_text(json.dumps({'purpose':'Reproduce native renderer diagnostics with the same camera/lighting/streaming sequence. C6 attach records original references only; no meshes, materials, layers or scene instances change.','not_candidate_evidence':True},indent=2)+'\n')
print('C6_BASELINE_PREPARED')
