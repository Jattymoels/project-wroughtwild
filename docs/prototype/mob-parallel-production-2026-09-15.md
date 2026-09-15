# MOB-02/03 parallel production boundary

**Ram integration update:** MOB-02 is published on main as `5493470` (production
`fb9fe9d`). `RamPresentation` binds the 23-bone export to existing Stone Husk
guard/melee behavior. Stationary alert braces, movement keeps walking, native
windup/release drives the forehead strike, and Continue clears the cosmetic
release. The 29 native and 10 Continue assertions passed; worker rig evidence was
reused. Porcupine, crane and ram production/adoption are now complete. The original
worker boundaries below are retained as historical setup, not outstanding work.

**Crane integration update:** MOB-03 is published on main as `d9e6b90`.
`CranePresentation` supplies species setup and a five-bone call layer over native
locomotion. `Enemy.recruitment_called` now observes the completed native call;
melee release remains separate. Successful SaveManager restoration resets the
crane's transient action poses through its registered presentation group. Ram
integration above preserves these additions. There is no requirement to redo
either species' source work.

**Earlier integration update:** MOB-01 is published on main as `f0349c2`.
`PorcupinePresentation` supplies species-specific rig/material/size setup and
extends the existing `FinishedFauna` sampler; one `CreatureMotion` dispatch branch
selects it. The A2 sampler, native `enemy.gd`, combat tuning and saves are unchanged.
Ram/crane production should finish its own descriptors without rebasing a running
checkout. The coordinator owns subsequent shared wiring. The crane still needs
the documented observer at the actual `force_scream()` event, separate from melee.

The owner asked on 15 September for work they can start alongside MOB-01.
Rigging/weighting/animation of different approved ART-06C animals can proceed
independently. The owner starts these prepared tasks; do not spawn extra workers.
Keep three production workers total for now: porcupine, ram and crane.

This is the source-production portion of the agreed playable roster sequence,
not a new study or approval checkpoint. The coordinator will integrate each
checked result into its ordinary game role after the shared porcupine adapter
lands, reusing its source/animation evidence. Return a checked production commit
and a concrete wiring handoff; do not claim ordinary gameplay adoption before
that wiring exists. No additional owner approval is required to complete it.

## Ownership and outputs

| Worker | Own files and source output | Shared wiring |
| --- | --- | --- |
| MOB-01 porcupine | Existing MOB-01 scope | Owns shared actor adapters, aggregate manifests and native integration |
| MOB-02 ram | `tools/wroughtwild-mob02-ram/`, `game/assets/authored/roster/stone_husk/`, `game/tests/mob02/`, its own result document; editable versions in `D:/Wroughtwild/source-art/mob02-ram/` | Return descriptor and exact integration notes; do not edit common actor code |
| MOB-03 crane | `tools/wroughtwild-mob03-crane/`, `game/assets/authored/roster/shrieker/`, `game/tests/mob03/`, its own result document; editable versions in `D:/Wroughtwild/source-art/mob03-crane/` | Return descriptor and exact integration notes; do not edit common actor code |

In MOB-02/03 do not edit `game/art/`, `game/scripts/`, `game/project.godot`,
aggregate fauna/mob manifests, `data/`, `sim/`, AGENTS.md, shared recipes, the
coordination sheet or queue. Read them freely. If a shared helper needs a change,
describe the smallest change in your handoff; do not duplicate a general runtime
adapter or ask the owner to reconcile competing implementations. Keep private
render/import configuration in ignored build output and remove test overrides.

Export a skinned `model.glb`, its actual required maps and a small `asset.json`
under your species folder. The descriptor is a handoff, not a new runtime schema:
record enemy ID, file paths, skeleton/AnimationPlayer location, exact clip names
and durations, loop flags, walk-cycle travel in source units, suggested uniform
scale/ground offset/orientation, material settings and actual triangle count.
Use simple clips `idle`, `walk`, `windup`, `release`, plus the species-specific
clip below. Clips animate in place: native actors retain movement and contacts.
Provide useful phase/release markers in the descriptor; no animation event may
apply damage, recruit enemies or mutate persistent state.

The shared adapter may evolve during MOB-01. Describe your exported rig/clips
accurately so the coordinator can wire them without reauthoring the animal.
Do not guess a new shared API or modify the other worker's checkout. Commit only
your owned paths and report the SHA. Leave changes to the aggregate queue to the
coordinator. The checked assets will enter main through sequential integration,
with a short actual-role check of the new wiring and normal Continue entry.

## Source and art requirements

Read current owner AGENTS.md and its required reading order, then the species
prompt, `remaining-mob-art-2026-09-09.md`, `roster-lifelines-2026-09-09.md`,
`tools/wroughtwild-roster/LIFELINES.md` and only relevant native role/adapter code.
Reuse reading and passed evidence for unchanged inputs. Current standing approval
and no-hard-cutoff guidance supersede old studies' exhaustive review, sealed
packaging, multi-renderer and separate visual/adoption approval instructions.

Each SETUP supplies five byte-checked ART-06C inputs on D: packed surface master,
base, ORM, scar mask and surface report. Preserve those inputs; author a new rigged
source version alongside them. Source models use two studio units for their
longest dimension, not gameplay metres. Keep approved structural growth, original
host texture, both-sided connected deep incisions and the dark-but-alive reading.
No concept regeneration, new animal or old ART-06B shallow-scar rollback.

Use fitted joints and useful weights, not a rigid source rotating as one lump.
Retain source originals and produce one sensible runtime mesh/detail level with
good animal silhouette and deformation. Preserve attached eyes, quills/horns,
beak and scar routes as applicable. Record actual simplification/triangle count;
no default three-LOD or retopology matrix, and no claim that automated topology
is hand retopology. Small residual sliding and fine fur/feather limits can remain.

The ART-06C material darkens the existing base through `damage_tint`, with light
inside physical routes and connected travel in the mask. Read selected
`lifeline-study.json` and `surface_scar.gdshader`; do not substitute ART-06B
settings or A2's different flat dark-edge treatment. Preserve map channels and
non-emissive animal details. Ambient pulse never grants healing or attack timing.

Native IDs, colliders, damage, reach, AI, population, era rules and saves stay
unchanged. An animal pose must communicate its existing role. Record the old
upright capsule/animal silhouette mismatch; do not squash the approved animal,
change the body or invent a new move to make the presentation fit.

## Small checks and shared machine

Default to at most three focused jobs, one renderer (Forward+):

1. Inspect this source, fit the rig and validate the saved rig/export: weights,
   attachments and a few meaningful rest/gait/action poses. Reuse old source
   identity/scar-depth evidence; no parent rehash/reopen or full BVH rerun.
2. Import the selected exported files in a small species-owned fixture. Check
   skeleton, clips, maps and independent instance poses; sample the actual output,
   not a separate higher-quality source disguised as runtime evidence.
3. One useful short motion capture showing idle, walk and the native-role action,
   with a few focused assertions for obvious detachment/pose-reset failures.
   The source fixture cannot establish native combat/save correctness; reserve
   that short check for actual integration and state the limit in the handoff.

Use background Blender and headless state/import checks. Keep logs, caches and
private application data on D:. Do not run a benchmark, soak, both-renderer review
or camera/lighting/seed matrix. R9 stays stopped. There is no hard ten-minute cutoff
for routine rigging, a useful correction, commit or handoff.

Rendered Blender/Godot jobs share the named Windows mutex
`Local\WroughtwildArtRender` with MOB-01. Acquire it nonblocking in the process
that launches and waits for the rendered job, and hold it until that job exits;
release/dispose in `finally`. If occupied, do independent CPU/source work and
retry later rather than launching a competing capture. Do not leave a detached
renderer after releasing the lock or interrupt an active peer. A recovered
abandoned mutex grants ownership; inspect for an orphan renderer before starting.
Headless imports/state checks and non-rendering source authoring need no GPU lock.

Use verified `--r8-no-mouse-capture` and a disposable
`display/window/size/no_focus=true` override for ordinary-game rendered fixtures;
assert visible mouse/no focus. A source fixture must likewise never capture the
pointer or focus. Script the camera; do not operate the owner's mouse. Remove
overrides and stop owned tests before handoff. CPU setup can overlap, but avoid
large simultaneous full-project imports when a selected-asset fixture suffices.

## Handoff

Return the checked commit, retained editable source/recipe paths, actual motion
achieved, known limits, checks run and exact integration requirements. Show one
or two selected screenshots and a short motion clip inline in chat with absolute
paths. Write only your species result document. No complete parent archive or
sealed playable package is required; don't stage caches, saves or import sidecars.

The coordinator completes normal-game adoption from these assets after MOB-01;
keep that next action explicit. Underground lag, remaining station/campaign
feedback, later-era additions, other mobs, bosses and Reclaimed Frontier remain
separate queued work. Do not start an unrelated repair/review wave.
