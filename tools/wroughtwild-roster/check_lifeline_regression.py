"""Confirm the shared builder still reproduces the retained ART-06B surface."""
import json
from pathlib import Path

repo=Path(__file__).resolve().parents[2]
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
old=repo/'build/roster-art06b/cinder_archer-surface-v04'
new=repo/'build/roster-art06c/art06b-regression'
a,b=read(old/'surface-report.json'),read(new/'surface-report.json')
keys=['source_sha256','config_sha256','geometry_sha256','triangles','vertices',
      'max_displacement_units','flipped_faces','core_texel_fraction','damage_texel_fraction']
for key in keys: assert a[key]==b[key],key
for name in ['base.png','orm.png','scar-mask.png']:
    assert (old/name).read_bytes()==(new/name).read_bytes(),name
result={'passed':True,'checks':len(keys)+3,'scope':'Shared builder preserves the selected ART-06B porcupine geometry and texture maps exactly.'}
(new.parent/'art06b-regression.json').write_text(json.dumps(result,indent=2)+'\n')
print('ART06B_REGRESSION_OK',result['checks'])
