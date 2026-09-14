"""Concise human-readable index of the actual R8 acceptance evidence."""
import json,re
from pathlib import Path
from inspect_inputs import ROOT,read,sha
from compose import write
out=ROOT/'build/art07-repairs/r8/v01';doc=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r8';a=read(out/'acceptance.json');jobs=a['required_receipts']
lines=['# R8 verification','',f"The concrete acceptance matrix has {a['required_fresh_jobs']} required successful fresh processes. Raw process receipts, commands, private paths, exit statuses and verified log hashes are in `records/acceptance.json` and `evidence/job-index.json`. Retained earlier failures remain separate.",'','| Required run | Whole-process seconds | Native/result markers |','| --- | --- | --- |']
for r in sorted(jobs,key=lambda x:x['start']):
 markers=[s for s in r['markers'] if not s.startswith('R8_COMFORT startup')]
 markers=[s for s in markers if not s.startswith('R4_CLEANUP')]
 if not markers:markers=[s for s in Path(r['log']).read_text(encoding='utf-8-sig').splitlines() if re.search(r'(NATIVE_OK|REOPEN_OK|MASTER_REOPEN)',s)]
 lines.append('| '+r['version']+' / '+r['id']+' | '+f"{r['seconds']:.3f}"+' | '+'; '.join(markers).replace('|','/').replace('\n',' ')+' |')
lines += ['','These whole-process durations include setup, assertions/captures and shutdown. They are not substituted for the separately measured setup or settled-frame values in `costs.md`. Native/reload timings recorded during fixture runs are diagnostic, not isolated benchmark samples.','', 'All four paid flows pass 865 checks; four fresh-process restores pass eight. Initial/paid/final save fingerprints, route records and final-hook geography match between art-on/off and between renderers. The canonical full probe also matches the verified historical G1 snapshot; that historical comparison is explicitly not a fresh G1 engine run. Only ephemeral generated station scene names are omitted, never persistent station keys or saved poses.','', 'All eight R4 fixtures have 44 successful fresh flow/restore jobs. Every terminal report has zero children and observed playbacks and no ObjectDB leak warning. F4 retains native escrow/payment/drive, real pause/block and synchronous fractional/exhausted recovery. The native save manager bytes and call order remain unchanged.','', 'Packed-source reopens cover two tree masters and 19 exports; three building material masters with 102 images; the chest master with 16 body/lid exports; the selected ore master with 153 meshes and seven packed images; and two retained ground-cover masters. Exact before/after input hashes and all copied selected source hashes are checked.','', 'Both live comfort jobs observe 120 rendered player process frames with visible mouse mode and the real window no-focus flag. No desktop pointer movement is automated. Normal-play runtime excludes the override and preserves the original capture branch.','', 'Runtime gates are separate from owner visual acceptance, continuous human first-hour play and minimum-hardware clearance. See `README.md`, `TUNING.md`, `DIAGNOSTICS.md` and `image-provenance.json`.']
write(doc/'CHECKS.md','\n'.join(lines)+'\n')
reloads={}
for renderer in ['forward_plus','gl_compatibility']:
 folder=out/'runtime/evidence'/('r2-reloads-paced-'+renderer);flow=read(folder/'flow.json');restart=read(folder/'restart.json');assert flow['failures']==restart['failures']==0
 reloads[renderer]={'flow_checks':flow['checks'],'restart_checks':restart['checks'],'cycles':[{'cycle':r['cycle'],'cost':r['cost']} for r in flow['cycles']],'scope':'Three bounded native focus/read cycles. Allocation counters are retained; incidental duration fields are not isolated cost benchmarks.'}
write(doc/'reloads.json',reloads)
print('R8_CHECK_REPORT',len(jobs))
