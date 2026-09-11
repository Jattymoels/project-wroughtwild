"""Evidence gates for B4, independent of renderer assertions."""
import sys,json,hashlib
from pathlib import Path
import numpy as np
from PIL import Image
review,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);result={}
for p in (review/'assets').glob('*.gltf.import'):
    text=p.read_text();assert 'meshes/generate_lods=false' in text and 'meshes/force_disable_compression=true' in text
for p in list((review/'textures').glob('*.png.import'))+[review/'forest-floor.png.import']:
    assert 'mipmaps/generate=true' in p.read_text()
for renderer in ['forward_plus','gl_compatibility']:
    root=review/'evidence'/renderer
    check=json.loads((root/'checks.json').read_text());walk=json.loads((root/'walk.json').read_text());bench=json.loads((root/'benchmark.json').read_text())
    assert check['pause_resume'] and check['terrain_max_error_m']<.012
    assert walk['length_m']>36 and walk['unsupported']==0 and walk['route_error_m']<.45
    paused=sorted(root.glob('paused-*.png'));assert len(paused)==12
    hashes=[hashlib.sha256(p.read_bytes()).hexdigest() for p in paused];assert len(set(hashes))==1
    motion={}
    for prefix in ['pulse','water-wind']:
        frames=sorted(root.glob(prefix+'-*.png'));assert len(frames)==48
        a=np.asarray(Image.open(frames[0]).convert('RGB'),dtype=np.int16)
        change=max(float(np.abs(a-np.asarray(Image.open(p).convert('RGB'),dtype=np.int16)).mean()) for p in frames[1:])
        assert change>.015,(renderer,prefix,change)
        motion[prefix+'_mean_channel_change']=change
    a=np.asarray(Image.open(root/'tree-scar-off.png').convert('RGB'),dtype=np.int16)
    b=np.asarray(Image.open(root/'tree-scar-on.png').convert('RGB'),dtype=np.int16)
    scar_change=float(np.abs(a-b).mean());assert scar_change>.2,(renderer,'scar not visible',scar_change)
    cfg=json.loads((review/'scene.json').read_text());limits=cfg['candidate_budget'];budget=[]
    for case in bench['cases']:
        if case['all_near_and_shadows']:continue
        passed=case['draw_calls']<=limits['draw_calls'] and case['primitives']<=limits['submitted_primitives'] and case['texture_bytes']<=limits['texture_mib']*1024**2 and 0<case['gpu_p95_ms']<=limits['gpu_p95_ms']
        budget.append({'lighting':case['lighting'],'passes_candidate_ceiling':passed})
        assert passed,(renderer,case,limits)
    result[renderer]={'walk_m':walk['length_m'],'supported_samples':len(walk['samples']),'terrain_error_m':check['terrain_max_error_m'],'paused_frames_identical':True,'motion':motion,'scar_mean_channel_change':scar_change,'budget':budget}
out.write_text(json.dumps(result,indent=2)+'\n');print('B4_EVIDENCE_OK',json.dumps(result))
