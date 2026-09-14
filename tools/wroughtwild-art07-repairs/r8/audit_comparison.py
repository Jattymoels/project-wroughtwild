"""Verify the original measurement control still differs only by test instrumentation."""
from pathlib import Path
from inspect_inputs import ROOT,read,sha
from compose import write
out=ROOT/'build/art07-repairs/r8/v02';runtime=out/'runtime';prepared=read(out/'prepared.json');original=prepared['original_files'];changed=[]
base=Path(read(ROOT/'docs/prototype/art07-repairs/2026-09-14/inputs.json')['runtime_source']['path'])
for n,r in original.items():
    if sha(runtime/n)==r['sha256']:continue
    assert n=='game/scripts/player.gd',n
    text=(base/n).read_bytes();old=b'\t\tInput.mouse_mode = Input.MOUSE_MODE_CAPTURED';new=b'\t\tInput.mouse_mode = Input.MOUSE_MODE_VISIBLE if "--r8-no-mouse-capture" in OS.get_cmdline_user_args() else Input.MOUSE_MODE_CAPTURED'
    assert (runtime/n).read_bytes()==text.replace(old,new)
    changed.append({'path':n,'before_sha256':r['sha256'],'after_sha256':sha(runtime/n),'purpose':'Explicit test-only capture opt-out; no-flag behavior preserved'})
for n in ['benchmark.gd','benchmark.tscn','profile.gd','views.gd','views.tscn','traversal.gd','traversal.tscn']:
    assert sha(runtime/'game/r2'/n)==sha(out.parent/'v01/runtime/game/r2'/n),n
write(out/'comparison-source-audit-final.json',{'original_entries_checked':len(original),'changed_original_files':changed,'identical_measurement_harness':True,'scope':'All original game/data/native/engine/assets unchanged except explicit test-only player opt-out. Additive benchmark/visual/traversal fixtures are byte-identical in both runtime copies.'})
print('R8_ORIGINAL_CONTROL_AUDITED',len(original))
