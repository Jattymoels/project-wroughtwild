"""Write TEMPLATE-shaped R7 receipts after the checked implementation commit."""
import argparse,re
from common import *
from package import verify
parser=argparse.ArgumentParser();parser.add_argument('commit');args=parser.parse_args();guard()
commit=subprocess.check_output(['git','rev-parse',args.commit+'^{commit}'],cwd=ROOT,text=True).strip()
assert re.fullmatch('[0-9a-f]{40}',commit)
owned=['tools/wroughtwild-art07-repairs/r7/','docs/art/leyline-studies/2026-09-14/art07-repairs/r7/']
changed=subprocess.check_output(['git','diff-tree','--no-commit-id','--name-only','-r',commit],cwd=ROOT,text=True).splitlines()
assert changed and all(any(n.startswith(prefix) for prefix in owned) for n in changed)
seal=read(OUT/'sealed-package.json');assert verify(seal['path'])==seal
checks=read(OUT/'evidence/final-checks.json');assert checks['passed']
parent=read(OUT/'evidence/r1-consumption.json');inputs=read(ROOT/'docs/prototype/art07-repairs/2026-09-14/inputs.json')
limitations=['Uniform fitting makes some fine shrub silhouettes smaller than the old broad-card mesh; Compatibility reads colder/less saturated in shade. Local form/detail improves, but source size and cross-renderer colour balance require owner visual review.','Direct standalone scenery_grounding startup reports resource preload diagnostics in this candidate. Both renderers pass the original 16 assertions through the owned normal-resource-graph bootstrap; direct failures are retained. R8/R9 should retain this execution context or separately resolve the preload dependency.','Owner visual acceptance pending; ordinary-world rollout outside scope.','Retained eligible plant envelopes cover at most 6.12–8.68 percent of the four measured 32 x 32 m XZ windows; continuous reference understorey remains unmet. Enlarged-envelope or geography options are proposals only.','B2 far LOD2 stays selected at all distances; small ground disappears at existing batch visibility ranges. No new distant dressing or terrain-conforming litter/climber support.','Current-machine RTX 5090 costs only; minimum hardware and budget unset. R2 loading changes not included. R8/R9 must assess combined cost and independently review the result.','R2 repackages images in the consumed sapling-shrub-lod2.glb; apply its image-alias delta once during integration and validate R7 material bindings.','Paid acquisition/address selection is harness-paced; actual route and home entry use native controller movement. Catalogue stock is explicit isolated inspection stock. No claim of a continuous human first-hour playtest.','V01 BEFORE capture reuse is explicit; it is an actual executed R1-parent baseline, not a fresh V02 baseline run. Failed parser, missing historical container and busy-slot diagnostics are retained.']
receipt={'id':'r7','status':'ready_for_integration','source_commits':[commit],'runtime_base':inputs['runtime_base'],'parent_candidates':[{'id':'r1',**parent['parent'],'published_commits':parent['published_commits']}],'delta_base':'Common pinned G1 runtime plus the exact published R1 candidate; own changes.json before hashes refer to that parent state.','package':seal,'changes':'changes.json','findings':{'G2-V05':'Bounded retained-anchor composition candidate with fuller local leaf groups and rooted materials; reference-wide continuous coverage remains limited by measured envelopes and has explicit unimplemented proposals. Independent visual review pending.'},'checks':[{'id':j['id'],'exit_code':j['exit_code'],'log_sha256':j['log_sha256'],'seconds':j['seconds']} for j in checks['jobs']],'preservation_checks':checks['checks'],'remaining_limits':limitations,'owner_visual_acceptance':'pending','ordinary_world_rollout':'outside scope','worktree':str(ROOT),'branch':'codex/art07-r7','inspected_main_base':'a3aab16f7220d6ccc37cb17a54a164a84bf524b6','verified_source_commits':read(OUT/'evidence/source-commits.json'),'verified_input_packages':{'runtime_source':inputs['runtime_source'],'g2_review':inputs['g2_review'],'b2':inputs['source_packages']['b2'],'b4':inputs['source_packages']['b4']},'main_integration_push':'not performed by worker'}
R=ROOT/'docs/prototype/art07-repairs/2026-09-14/receipts';assert not (R/'r7.json').exists() and not (R/'r7.md').exists();write(R/'r7.json',receipt)
py=inputs['tools']['python'].replace('\\','/');pkg=seal['path']
text=f'''# ART-07R7 — Compose fuller habitat at retained anchors

Status: ready_for_integration (bounded candidate).
Owner visual acceptance: pending. Ordinary-world rollout: outside scope.

## Source and scope

Worktree `D:/project-wroughtwild-art07-r7`, branch `codex/art07-r7`; inspected published
main base `a3aab16f7220d6ccc37cb17a54a164a84bf524b6`. Wave-2 readiness and all published
R1–R4 receipts/commits/packages were verified before source consumption. Full
`workspace.py verify --id r7` input-hash results are sealed as
`evidence/input-verification-r7-01.txt`. Common game/data/native remains
`{inputs['runtime_base']}`; DLL SHA-256 is `{inputs['native']['dll_sha256']}`.

Selected source publication commits and input package identities are in the sibling
JSON and sealed source-commits.json. Direct parent is the published R1 candidate:
`{parent['parent']['path']}`,
manifest `{parent['parent']['manifest_sha256']}`
({parent['parent']['files']:,} files, {parent['parent']['bytes']:,} bytes). Its complete
payload was hashed before applying only the declared 105-file runtime delta.

Owned Git outputs are tools/wroughtwild-art07-repairs/r7/, the R7 art review directory,
and these two receipt files. The own runtime delta changes only
G1Environment.cover_mesh/_process, HabitatLook.mesh_for, GroundCover's material
binding, StrangeSites._batch, and adds the R7 presentation/inspection directory.
Exact before/after hashes and functions/settings are in changes.json. R1 changes
are ancestry, not new R7 ownership. All other parent bytes are verified unchanged.

The six B2 far meshes, packed groundcover-master.blend/shrub-source.blend, albedo
and ORM remain unchanged. Full original sources are retained and hashed. R2 has no
direct file overlap with these four hooks, but repackages the consumed shrub GLB's
image references and aliases; R8 must apply that change once and validate final
material bindings. No loading optimization, new anchors/geography/body/recipe,
ordinary adoption or save migration is introduced.

## Result and checks

The [review and actual images](../../../../art/leyline-studies/2026-09-14/art07-repairs/r7/README.md)
show crossed leafier shrubs, fern/grass layers, rooted sway and the remaining bare
middle ground. All 33 support roles have explicit used/retained/unsuitable/uncomposed
assessments. Original envelopes, IDs/counts/poses, building masks, visibility ranges,
geography, static collision and actual R1 crown dimensions/overlaps match in all
four views across both renderers. Raw inspector capsule-yaw differences remain
recorded; its round upright shape, dimensions and position are unchanged.

There are {checks['checks']:,} evidence/identity checks and {len(checks['jobs'])} accepted
actual guarded jobs, including fresh import, both renderer smokes, both packed-master
reopens, all-vertex/rooted-wind checks, native grounding and building/excavation
clearing, both 273-pair catalogues, before/after paid flows, separate-process restarts,
actual controller-route capture and four separate settled benchmark processes.
The paid flows pass {checks['paid']['checks_before']}/{checks['paid']['checks_after']}
original assertions and walk {checks['paid']['walk_before']['metres']:.3f}/
{checks['paid']['walk_after']['metres']:.3f} m. Exact native ownership, finite stocks,
source claims/work, geography and saved paid state compare in the raw reports.

The historical ecology fixture retains every original assertion and profile; it
adds an empty typed history container required by the inherited G1 C6 inspection
adapter. The initial missing-container error and corrected fresh runs are preserved.
The first mesh fixture parse failed local type inference; its fresh explicit-type
run passed. Earlier V01 probe/indentation failures and rejected visual candidate are
also preserved. Busy GPU attempts launched no engine, and Compatibility's inherited
SSAO warnings remain visible. No diagnostics were filtered or assertions relaxed.

Four matched eye-height cameras (home, source route, clearing, oldgrowth habitat)
each have day/shade/dusk in Forward+ and Compatibility. Original images are
1440 x 900; review contact sheets only resize/tile. Actual live-sway sequences have
66 frames per renderer and recorded wall intervals; controller-route playback uses
nominal intervals for real input-driven captures. Source and derivative image hashes,
dimensions and operations are sealed. The V01 BEFORE runs are explicitly reused as
the executed R1 comparison, not claimed as fresh V02 executions.

Hardware is RTX 5090 / driver 32.0.15.9186, Ryzen 9 9950X3D, 32 GB RAM, Windows 11 Home.
Settings are 1440 x 900, 4x MSAA, VSync off, with 120 warmup and 300 settled samples
per camera/light/mode. All texture/buffer, geometry, draw-call, GPU and frame counters
are in review/costs.md and raw reports. These full-world R1+R7 costs include other
G1 content/hidden stages and exclude R2. They establish no independent performance
or minimum-hardware clearance. Benchmarks ran apart from imports, captures, reopening
and image encoding, with no competing guarded process recorded.

Every numeric grouping budget/yaw and purpose is in review/settings.json and
changes.json. Controls include LOD2, 0.018 m/m bend, 5.5 s wind period, 2.5% envelope
inset, inherited olive gain (0.85,0.72,0.60), 0.72 upward leaf-normal mix and 0.22
diffuse backlighting. All grouping roots share the retained origin. Analytical and
actual vertex checks retain the original envelope including sway. The full role,
coverage, tuning, source and diagnostic details are in the review and exact reports.

## Candidate and limits

Sealed package: `{pkg}`

Manifest SHA-256: `{seal['manifest_sha256']}`

Exact file set: {seal['files']:,} files, {seal['bytes']:,} bytes, excluding manifest.json.
The receipt is outside its own hashed package. changes.json names the own delta
against the verified R1 parent and identifies integration overlap. The seal includes
full runtime, original source masters, source hashes, actual raw engine evidence,
failed/accepted logs, job specifications, review media and owned recipes.

Full verification:

```powershell
& '{py}' tools/wroughtwild-art07-repairs/r7/package.py verify '{pkg}'
```

Reconstruct into an absent version (`v03` only if still absent), then freshly import:

```powershell
& '{py}' tools/wroughtwild-art07-repairs/workspace.py prepare --id r7 --version v03
& '{py}' tools/wroughtwild-art07-repairs/r7/apply.py '{pkg}' D:/project-wroughtwild-art07-r7/build/art07-repairs/r7/v03/runtime
./tools/wroughtwild-art07-repairs/run.ps1 -Spec build/art07-repairs/r7/v03/import-smoke.json
```

Actual executed commands/logs/exit status are in review/execution.md and job-specs.
Every run used the unchanged shared mutex/process guard and private APPDATA/local/
temp/Blender paths. The retained ART07G1 user directory resolves under each job's
private APPDATA; paid restarts reuse only their corresponding disposable state.

Remaining limits:

'''
for line in limitations:text+='- '+line+'\n'
text+=f'''\n## Commits and publication

Checked implementation commit: `{commit}`.
Receipt commit is resolved from Git history after writing this receipt.
Main integration/push: not performed by this worker. The serial publisher owns
integration and publication; R7 sends no task messages or monitor requests.
'''
(R/'r7.md').write_text(text,encoding='utf-8');print('R7_RECEIPTS_WRITTEN',commit)
