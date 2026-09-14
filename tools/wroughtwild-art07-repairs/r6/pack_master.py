"""Pack the derived R6 atlas beside the unchanged C5 source geometry."""
import sys
import json
from pathlib import Path
import bpy
sys.path.insert(0, str(Path(__file__).resolve().parent))
from master_geometry import signatures

source, atlas, controls, target = map(Path,sys.argv[sys.argv.index('--')+1:])
assert not target.exists()
bpy.ops.wm.open_mainfile(filepath=str(source))
original_geometry = signatures()
image=bpy.data.images.load(str(atlas),check_existing=False)
image.name='R6 C5 surface fields - mineral scar height coverage'
image.use_fake_user=True
image.colorspace_settings.name='Non-Color'
image.pack()
text=bpy.data.texts.new('R6 surface controls and projection.json')
text.use_fake_user=True
text.write(controls.read_text(encoding='utf-8'))
bpy.context.scene['R6_scope']='Source-field projection only. Original C5 mesh objects, material fields and dimensions are unchanged. No faceted slab or new body.'
bpy.ops.wm.save_as_mainfile(filepath=str(target))
assert signatures() == original_geometry
target.with_suffix('.geometry.json').write_text(json.dumps(original_geometry, indent=2), encoding='utf-8')
print('R6_SURFACE_MASTER_PACKED',target)
