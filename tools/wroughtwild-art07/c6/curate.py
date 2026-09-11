"""Copy selected actual evidence into the owned documentation directory."""
import json,shutil,sys
from pathlib import Path
from prerequisites import sha
root,review,destination=[Path(p).resolve() for p in sys.argv[1:]]
assert not destination.exists();destination.mkdir(parents=True)
selected={
 'blender-wall.png':root/'blender-v06/cataclysm_fen_wall_struck-material.png',
 'blender-rootvault.png':root/'blender-v06/cataclysm_rootvault_frame-material.png',
 'blender-scar-off.png':root/'blender-scar-v06/scar-material-off.png',
 'godot-before.png':review/'evidence/forward_plus/capture-77/fen_wall_struck-before-inspection-sun.png',
 'godot-after.png':review/'evidence/forward_plus/capture-77/fen_wall_struck-after-inspection-sun.png',
 'godot-native-day.png':review/'evidence/forward_plus/capture-77/fen_wall_struck-after-day.png',
 'godot-compatibility.png':review/'evidence/gl_compatibility/capture-77/fen_wall_struck-after-inspection-sun.png',
 'godot-collection.png':review/'evidence/forward_plus/capture-77/collection-marks-after-day.png',
 'godot-emission-off.png':review/'evidence/forward_plus/capture-77/struck-wall-emission-off.png',
 'godot-emission-on.png':review/'evidence/forward_plus/capture-77/struck-wall-emission-on.png',
 'godot-pulse.gif':root/'media-v06/forward_plus-pulse.gif',
 'godot-collection-walk.gif':root/'media-v06/forward_plus-collection-walk.gif',
 'model-audit.json':root/'audit-v06-rays.json',
 'verification.json':root/'verification.json',
 'measured-costs.json':root/'summary.json',
 'environment.json':root/'environment.json',
 'prerequisites.json':root/'prerequisites.json',
 'reproduction.json':root/'reproduction.json',
}
records={}
for name,path in selected.items():
    shutil.copy2(path,destination/name)
    records[name]={'sha256':sha(path),'bytes':path.stat().st_size,'actual_source':str(path)}
(destination/'evidence-manifest.json').write_text(json.dumps(records,indent=2)+'\n')
stats=json.loads((root/'summary.json').read_text())
lines=['# ART-07C6 actual candidate evidence','','Owner visual acceptance is pending. The packed source, native scene and full evidence are identified in the C6 receipt. All images here are actual Blender/Godot renders. Before/after inspection-sun images share the same deliberately rotated review light; godot-native-day.png retains the native sun direction. GIFs use actual captured frames without interpolation.','','The kit adds worn surfaces and fitted low roots to existing ruin geometry, one physical accidental scar at the old smithy, and quiet bevelled LF approach marks. It retains native envelopes, route anchors, collisions, finite stock and source/work ownership. No normal-world adoption is included.','','Remaining visual limits: inherited regular lattice/block forms, visible triangulation in the close scar, thin/angular root details and terrain clutter can limit readability. The unchanged native terrain/canopy is visibly less dense than the selected concept board. Fixed RTX views and fixture walks do not clear broader habitat adoption.','','| Variant | Godot width × height × depth (m) | Near / middle / far triangles | Near exported surfaces |','| --- | --- | --- | --- |']
for name,levels in stats['assets'].items():
    low,high=levels[0]['bounds_blender_m'];size=[high[i]-low[i] for i in [0,2,1]]
    lines.append('| '+name+' | '+' × '.join(f'{v:.3f}' for v in size)+' | '+' / '.join(str(v['triangles']) for v in levels)+' | '+str(levels[0]['surfaces'])+' |')
lines+=['','Original/native dimensions, hashes, all LOD bounds, scalar controls, contacts, ray measurements, texture costs and exact executed job arguments are retained in the JSON evidence. No new single-object generation input was required; the existing B3 packed source and original native GLBs were verified and reused.']
(destination/'README.md').write_text('\n'.join(lines)+'\n')
print('C6_CURATED',len(records),sum(r['bytes'] for r in records.values()))
