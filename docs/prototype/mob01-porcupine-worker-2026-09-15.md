# MOB-01 — playable porcupine Cinder Archer

Work in `D:/Wroughtwild/work/mob01-porcupine`, branch `codex/mob01-porcupine`.
Read `build/mob01/SETUP.md` for the prepared current-main base, native DLL and
selected source copies. The owner starts this worker; do not launch other tasks
or reviewers. Use this checkout even if the task opens at the C: owner depot.

## Result to deliver

Replace the existing Cinder Archer's older humanoid presentation with the approved
ART-06C porcupine, with a real fitted rig, skin weights, readable locomotion and
attack motion in ordinary new-world/Continue play. Finish one usable enemy role;
a static mesh, rig-only showcase or unintegrated source package is not completion.
Preserve the approved broad nose, natural eyes, rooted fine whiskers, quill comb,
grotesque shoulder growth and deep connected lifelines. Do not generate a new animal.

This follows A1, A2, PLAY-01 and PLAY-02, already on main. The owner reviewed the
canopy captures and requested publication and the next slice. Standing approval
covers this agreed production sequence; hands-on owner feedback is deferred.
Build the look, feel and atmosphere through playable iterations. There is no hard
ten-minute cutoff or separate visual/adoption/performance gate. R9 stays stopped.

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and its required
reading order, reusing applicable prior reading. Then read:

- `docs/prototype/remaining-mob-art-2026-09-09.md` for approved anatomy/role;
- `docs/prototype/roster-lifelines-2026-09-09.md` and
  `tools/wroughtwild-roster/LIFELINES.md` for the selected ART-06C source;
- `docs/prototype/mainline-fauna-a2-result-2026-09-15.md` and relevant adapter code;
- `docs/systems/combat-and-builds.md`, D-010/D-012/D-013/D-030 and ADR-0003,
  only the relevant ranged-contact sections of linked specifications.

Old isolated-delivery exclusions, multi-renderer/full-source audits and packaging
requirements do not apply to this approved playable slice. Do not replay source
generation, ART-06B repairs or the entire ART-06C verifier.

## Selected source and useful implementation leads

Canonical approved input is retained at
`C:/Users/Matty/Dev/project-wroughtwild/build/roster-art06c/lifeline-handoff/`.
Setup copies only these five selected files from `sources/cinder_archer/` to
`D:/Wroughtwild/source-art/mob01-porcupine/input-art06c/`:
`cinder_archer-surface.blend`, `base.png`, `orm.png`, `scar-mask.png` and
`surface-report.json`. The source selection receipt records their hashes.
Preserve both input copies; create new rigged masters under a new version in
`D:/Wroughtwild/source-art/mob01-porcupine/`. No whole-parent copy or rehash.

The source has approximately 280,126 host triangles plus 4,432 face-attachment
triangles, with no rig. Its longest dimension is two **studio units**, not game
metres. Eye/whisker attachments need to follow the head. The porcupine's repaired
2048-by-2560 base/ORM atlases include a muzzle strip; preserve those UVs and the
scar mask. Deep channels are physical geometry, not just painted emission.
Existing selected pictures are in
`docs/art/leyline-studies/2026-09-09/roster-art06c/cinder_archer/`.

The canonical `review/scar.gdshader` and `review/surfaces.json`, plus tracked
`tools/wroughtwild-roster/surface_scar.gdshader` and `lifeline-study.json`, describe
ART-06C's material: texture-preserving dark damage and connected pulse travel.
The current A2 shader uses a different dark-edge treatment and enables normal maps
for its families. Preserve the porcupine's actual maps/treatment; do not assume a
drop-in material or missing normal texture. Keep eyes and whiskers non-emissive.

Relevant runtime points are `game/art/recovered_actor_art.gd`,
`game/art/creature_motion.gd`, `game/art/finished_fauna.gd`, its shader and manifests,
and `game/scripts/enemy.gd`. A2 demonstrates manually sampled imported animations
driven by actual movement/windup/release/status state. Reuse its small applicable
pieces without changing finished boar/wolf/stag/moths or creating a general rig
framework. `tools/wroughtwild-boar/build_rig.py`,
`tools/wroughtwild-fauna/build_rig.py` and their weight helpers are examples,
not instructions to reuse their animal-specific pivots or run their full pipelines.

## Implementation boundary

Restate the intended animal motion and affected presentation files. Inspect this
one source, fit joints to its actual anatomy and weight the four legs, torso and
head; keep quills and face attachments coherently attached. Produce idle, walk,
windup and release/recovery poses appropriate to the existing actor. A grounded
quill-comb brace/recoil should make the existing shot readable. Use bounded
weight/mesh repairs where deformation needs them. Report residual sliding or fine
fur/face limitations; full facial animation, foot IK and perfect close-up polish
are not prerequisites for an otherwise convincing prototype creature.

Select one sensible production mesh/detail level that retains the selected face,
quill silhouette and recessed routes while deforming acceptably. Keep the dense
editable master. Do not multiply delivery into three new LODs or a distance system
by default; document actual runtime triangle count and any simplification. Never
present automatically generated topology as manual retopology.

Use presentation-only orientation, grounded offset and uniform size settings with
plain-language purposes. The old upright capsule (radius 0.35 m, height 1.3 m) has
a known animal-silhouette mismatch. Preserve it and native targeting; do not squash
the animal into the old humanoid mesh or change collision just to pass a fit check.
Keep its stance and launch region coherent with the actual native muzzle; report
any remaining body/visual mismatch honestly.

`enemy_id = cinder_archer`, behavior `ranged`, remains the existing mark/fire role.
Current reference values include 55 life, 6 fire damage, 0.6-second committed
windup, 18 m/s projectile, 14 m shot range and 1.05 m muzzle height. Read current
engine-neutral tuning; do not copy those numbers into animation logic or alter
damage, aim commitment, projectile origin/clearance, mark, cadence, navigation,
body, loot, population, IDs or saved state. No new volley, bow, homing or quill
hurtbox. Animation follows the authoritative native release; it never fires shots.
Existing sidestep/solid-cover responses, interrupt/freeze/stagger and death remain.

Keep pause and status priority, independent actor pose/material state, shared
reusable meshes/textures and a single active animation driver. Scar pulse is
ambient anatomy and grants no healing or combat timing. Preserve A2 families,
campaign influences, ordinary Continue/new-world entry and PLAY-01's resource
work budget. All production paths stay inside tracked `game/` resources; never
make production depend on an absolute source path, private save or showcase flag.

## Focused verification and delivery

Name the concrete risks before checking. Default to three focused jobs and one
renderer (Forward+), narrowing to this changed role:

1. Source/rig/export check: retained identity/maps/attachments, bound weights and
   meaningful leg/head deformation at rest and a few representative moving poses.
   Check the actual saved rig/export, without reopening every parent master or
   recreating historic depth/BVH evidence for unchanged source surfaces.
2. Import and a brief ordinary-game/native-actor view: idle/walk, committed ranged
   tell and one release, pause/status interruption. Show enough animation to judge
   the gait and quill response. Verify native shot timing/cover behavior with
   focused assertions where the adapter touches it; reuse existing combat evidence.
3. One relevant death/streaming/Continue check for this existing actor identity and
   its normal instantiation path. If shared A2 code changes, add only a small
   directly affected old-family smoke; do not rerun all fauna/campaign/save suites.

Prefer background Blender and headless state checks. Rendered automation must use
verified `--r8-no-mouse-capture` and a disposable
`display/window/size/no_focus=true` override, asserting visible mouse and no focus.
Use scripted input/cameras, never the owner's desktop pointer. Remove the override
and end owned processes before handoff. Store large imports, logs and private test
application data on D:. No benchmark gate, long soak or camera/seed matrix.

Commit the complete checked slice on `codex/mob01-porcupine` and return its SHA for
coordinator integration and ordinary push. Update the current coordination sheet
and queue, add a concise result/provenance note and include exact normal-main
launch/playtest steps. State achieved gameplay, remaining limits, checks actually
run and actual publication status. Show one or two selected screenshots and a
short useful motion clip **inline in chat using absolute paths**; do not leave
the pictures accessible only through a Markdown report. Keep editable masters and
generated caches out of Git; commit recipes, selected runtime assets and settings.

This completes only the porcupine role. Ram, crane, six-legged beetle, six-legged
nymph and tortoise follow individually. Later-era physical augmentation and boss
art remain separate backlog work. PLAY-03 underground lag is unresolved, canopy
blunt ends remain polish, station/campaign feedback is deferred, and the Reclaimed
Frontier landscape references stay queued. Do not restart R9 or unrelated repairs.
