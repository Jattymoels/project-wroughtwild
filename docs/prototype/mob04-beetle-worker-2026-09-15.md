# MOB-04 — playable beetle Gloom Crawler

Work in `D:/Wroughtwild/work/mob04-beetle`, branch `codex/mob04-beetle`.
Read `build/mob04/SETUP.md` for the prepared main base, unchanged native DLL and
selected source receipt. Use this checkout even if the task opens at the C:
owner depot. The owner starts this worker; do not launch other tasks or reviewers.

## Deliver one usable enemy

Rig, animate and integrate the approved ART-06C ground beetle into the existing
`gloom_crawler` / `swarm` role in ordinary new worlds and Continue. Preserve the
low quick insect, exactly six distinct jointed legs, antennae, supported mandibles,
displaced dark elytra, exposed inner lamellae and physically recessed lifelines.
Do not generate a new animal. A static mesh, source-only rig or isolated showcase
is not completion; deliver the normal playable role on this branch.

A1/A2, movement/canopy improvements and the porcupine, crane and ram are already
on main and included in this base. The owner approved the current visuals after
MOB-02, explicitly saying full performance impact was not tested and that this
was fine. Standing approval covers the agreed remaining production and ordinary
integration. Build the look, feel and atmosphere through playable iterations;
do not introduce another visual/performance gate. R9 remains stopped.

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and its required
reading order, reusing applicable prior reading. Then read only the relevant parts:

- `docs/prototype/remaining-mob-art-2026-09-09.md` and
  `docs/prototype/roster-lifelines-2026-09-09.md` for approved anatomy/source;
- `tools/wroughtwild-roster/LIFELINES.md`, the beetle entry in
  `lifeline-study.json` and `surface_scar.gdshader` for the selected material;
- `docs/prototype/mob02-ram-result-2026-09-15.md`, the existing presentation
  adapters and their focused native/Continue fixtures;
- `docs/systems/combat-and-builds.md`, relevant accepted D-010/D-012/D-013/D-030
  decisions and ADR-0003, plus current native swarm/melee tuning and code.

The old studies' isolated-delivery exclusions, parent-package reviews and broad
renderer matrices are historical. Do not replay generation, ART-06B repairs,
the entire ART-06C verifier or previous completed mob checks.

## Source and runtime boundary

Five selected files are copied from the retained canonical
`C:/Users/Matty/Dev/project-wroughtwild/build/roster-art06c/lifeline-handoff/sources/gloom_crawler/`
to `D:/Wroughtwild/source-art/mob04-beetle/input-art06c/`:
`gloom_crawler-surface.blend`, `base.png`, `orm.png`, `scar-mask.png` and
`surface-report.json`. The receipt records their matched hashes. Preserve inputs;
author new rigged versions under `D:/Wroughtwild/source-art/mob04-beetle/`.
No whole-parent copy, rehash or source regeneration is needed.

The selected v02 source has 293,396 triangles before rig finishing, with no rig.
Its longest dimension is two studio units, not game metres. Fit joints to its
actual three pairs of legs; an alternating tripod gait is a suitable starting
point. Keep foot plants readable and the body low while travelling at native
speed. Fit head/mandibles and antennae where the real source permits. Preserve
shell/inner-plate support; do not flex a hard wing case like loose cloth.

Provide idle, walk, windup and release/recovery clips. Use a short mandibular
brace/bite to communicate the existing melee event, with no added movement or
damage. Do not add flight, burrowing, spider legs, a leap or a new attack. Choose
one useful runtime detail level while retaining the dense editable source.
Record actual triangle count and simplification honestly; automatic reduction
is not manual retopology. Fine cavities, slight sliding and lack of foot IK can
remain documented limits if the animal and its motion read well in play.

Use existing `CreatureMotion` / `FinishedFauna` patterns with a small species
adapter where needed. The ram is an example of data-driven setup, not a template
for beetle anatomy or size: **native swarm does not receive the ram's 0.76
humanoid reduction**. Read current `Enemy.configure`; apply uniform visual size,
ground offset and source-forward alignment with family/elite scale exactly once.
Do not squash the animal into the old upright radius-0.35 / height-1.3 capsule.
Preserve that collider, targeting and contact reach; report silhouette mismatch.

Bind ART-06C base/ORM/scar maps with texture-preserving `damage_tint`, the selected
palette and connected pulse travel. There is no normal map to invent. The shared
`porcupine.gdshader` already carries this material math with native status priority;
read actual descriptor conventions before reusing it. Keep per-instance material,
phase and pose state, shared reusable mesh/textures, one animation driver,
pause-aware ambient light and exact freeze/status interruption. The scars do not
grant healing or set attack timing. Use the existing transient presentation reset
hook if needed; a saved world must not replay an old cosmetic attack after load.

Current reference behavior: 60 life, 5 physical damage, 5 m/s movement, 1.5 m
attack range and 0.25-second windup. Each other living swarmer within 4 m adds
15 percent to the native bite, capped at 60 percent. Read current engine-neutral
tuning rather than duplicating these numbers into animation logic. The native
`attack_released("strike")` event owns the release; animation never deals damage.
Preserve swarm eligibility/radius/cap, contact/cover checks, AI, separation, loot,
population, era mechanics, IDs, progression and saves. Do not make visual leg
cadence control movement or copy the ram's cosmetic stride without considering
this insect and its native speed.

Own `tools/wroughtwild-mob04-beetle/`,
`game/assets/authored/roster/gloom_crawler/`, `game/tests/mob04/`, a small species
adapter, necessary dispatch/manifest edits and
`docs/prototype/mob04-beetle-result-2026-09-15.md`. This worker owns the next shared
mob integration slice. Preserve completed art and gameplay; no general animation
framework, shared refactor or unrelated fixes. Leave aggregate queue/status
updates and mainline publication to the coordinator.

## Focused completion checks

Name the concrete risks first. Default to three focused job groups, one renderer
(Forward+), with no hard time cutoff for routine finishing:

1. This saved rig/export: six fitted legs, weighted deformation, supported
   shell/head parts, retained maps, a few useful gait/action poses. Reuse original
   source identity and scar-depth evidence; no parent reopening/BVH review.
2. Import and a short native Gloom Crawler view with a useful motion clip.
   Check actual pursuit, one authoritative melee release, pause/freeze/stagger
   and independent instances. Focused assertions should establish that the native
   swarm count/radius/cap still drives damage, rather than merely playing a clip.
3. One relevant ordinary generated-pack/death/Continue check: the normal actor
   selects this rig, preserves progression/ownership and discards transient poses.
   A cave-associated actor fixture does not establish underground performance.

Use background Blender and headless checks where possible. Keep build/import
output, private saves, logs and test APPDATA/TEMP on D:. Rendered checks must hold
`Local\WroughtwildArtRender` nonblocking until the owned process exits, then release
it in `finally`. Use verified `--r8-no-mouse-capture` and a disposable
`display/window/size/no_focus=true` override; assert visible mouse and unfocusable
window. Use scripted camera/input and never the owner's desktop pointer. Reuse
the current ram/crane runners. Remove your override and end all owned jobs at
handoff; never interfere with another process or remote-access tooling.

No benchmark gate, long soak, renderer/seed/camera matrix or source package
reconstruction. Fix observed load/gameplay failures; record small cosmetic gaps.
Documentation media is not a runtime dependency: keep evidence excluded from
Godot imports where needed (the ram uses `.gdignore` for its animated WebP).

Commit the complete checked slice to `codex/mob04-beetle` and return its exact SHA
for coordinator integration/push. Start the handoff with actual gameplay achieved,
then limitations, checks actually run and commit/publication status. Explain new
visual tuning, source provenance and exact normal-game playtest steps. Show one
or two selected pictures and a short motion clip inline in chat with absolute
paths, not only in the Markdown report. Keep editable masters, caches and builds
out of Git; commit selected runtime dependencies, recipes and compact evidence.

Nymph and tortoise follow; physical era variants and boss art remain separate.
The owner-reported significant underground lag is unresolved. Do not assume its
cause or restrict legitimate cave/digging access. Station/campaign feedback and
Reclaimed Frontier landscape direction remain queued. Do not restart R9.
