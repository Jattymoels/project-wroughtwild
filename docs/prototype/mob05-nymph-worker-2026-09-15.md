# MOB-05 — playable dragonfly nymph Bog Lurker

Work in `D:/Wroughtwild/work/mob05-nymph`, branch `codex/mob05-nymph`.
Read `build/mob05/SETUP.md` for the prepared main base, unchanged native DLL and
selected source receipt. Use this checkout even if the task opens at the C:
owner depot. The owner starts this worker; do not launch other tasks or reviewers.

## Deliver one usable enemy

Rig, animate and integrate the approved ART-06C dragonfly nymph into the existing
`bog_lurker` / `root` role in ordinary new worlds and Continue. Preserve exactly
six short strong legs attached to the thorax, a legless segmented abdomen,
compact folded labium, bog-iron crust, layered abdominal ruptures and deep
connected lifelines. The selected source is **v04**; the eight-legged v02 was
rejected. Do not generate a new animal or restore the rejected anatomy.

Give the heavy insect a readable grounded walk, idle, anticipation and short
labium/head release and recovery that communicate its existing attack. A rig-only
source or showcase is not completion: deliver the native playable role. Native
root happens on the existing confirmed hit; no animation may apply it, stretch
its duration, add reach or make a new persistent attachment/grab mechanic.

Current main includes A1/A2, PLAY-01/02 and the integrated porcupine, crane, ram
and beetle. Preserve them. The owner approved the current delivered visuals after
ram and has standing approval for the agreed remaining sequence. Full performance
impact and broader playtesting remain incomplete; do not create another visual
or performance gate. The prototype aims at useful look, feel and atmosphere,
improved through playable iterations. R9 stays stopped.

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and its required
reading order, reusing applicable prior reading. Relevant follow-up reading:

- `docs/prototype/remaining-mob-art-2026-09-09.md`,
  `docs/prototype/roster-lifelines-2026-09-09.md` and
  `tools/wroughtwild-roster/LIFELINES.md` for the approved source;
- the `bog_lurker` entry in `tools/wroughtwild-roster/lifeline-study.json` and
  its `surface_scar.gdshader` material;
- `docs/prototype/mob04-beetle-result-2026-09-15.md`, existing species adapters
  and focused native/Continue fixtures;
- relevant D-010/D-012/D-013/D-030 and ADR-0003, native root/contact sections in
  `docs/systems/combat-and-builds.md`, current `Enemy` and `PlayerCombat` code.

Old isolated-delivery exclusions, source-generation recipes and broad review
requirements are history, not tasks to repeat for this approved playable slice.

## Selected source and implementation

Setup copies only `bog_lurker-surface.blend`, `base.png`, `orm.png`, `scar-mask.png`
and `surface-report.json` from the retained canonical
`C:/Users/Matty/Dev/project-wroughtwild/build/roster-art06c/lifeline-handoff/sources/bog_lurker/`
to `D:/Wroughtwild/source-art/mob05-nymph/input-art06c/`, with a matched-hash receipt.
Preserve both originals; create new rigged versions under
`D:/Wroughtwild/source-art/mob05-nymph/`. Do not copy or rehash the whole parent.

The v04 source has 290,654 triangles and no rig. Its longest dimension is two
studio units, not game metres. Fit six leg chains, the thorax, supported abdomen,
head and compact labium to the actual mesh; do not reuse beetle pivots blindly.
Keep the abdomen visibly legless and its layers supported. Finish only anatomy
needed for coherent motion; a brief labium action must stay compatible with the
existing contact envelope. No wings, flight, new lunging movement, tongue tether,
bleed change or extra limb hurtboxes.

Use one sensible runtime detail level and retain the dense editable master.
Report actual simplification and triangle count; automatic reduction is not
manual retopology. Keep original maps, recessed routes, animal identity and
source-supported parts. Minor sliding, no terrain IK and fine generated cavities
can remain documented prototype limits rather than starting a polish wave.

Reuse the small `CreatureMotion` / `FinishedFauna` / species-adapter patterns and
ART-06C material/status shader. Preserve separate per-instance poses/materials,
shared reusable resources, one animation driver, pause, exact freeze hold and
native stagger/death interruption. Observe the actual native melee release;
resample authored recovery into its existing cosmetic window. Clear unsaved
cosmetic action state through the existing Continue presentation-reset hook.

Choose a grounded uniform visual scale and source-forward alignment from this
animal, with documented purposes. **Lurker has no 0.76 humanoid reduction**, and
already has a **1.4 family size multiplier**. Apply family/elite scaling once;
do not copy ram compensation or count the lurker's family size twice. Keep the
native upright .35 m radius / 1.3 m capsule, targeting and reach and document its
animal-silhouette mismatch. Do not squash the nymph or enlarge the body to pass.

Current reference rules are 120 life, 6 physical damage, bleed immunity,
1.8 m/s movement, 2.4 m reach, .9-second windup and 1.2-second root broken by
dash. Read authoritative tuning rather than copying numbers into animation
logic. Preserve hit/cover eligibility, trial modifiers, root duration and escape,
AI, separation, loot, population, IDs, era rules, progression and saves. Do not
change gameplay to match an art pose or infer a new LF colour rule from scars.

Own `tools/wroughtwild-mob05-nymph/`,
`game/assets/authored/roster/bog_lurker/`, `game/tests/mob05/`, a small species
adapter, necessary dispatch/manifest edits and
`docs/prototype/mob05-nymph-result-2026-09-15.md`. This worker owns the next shared
mob wiring. Avoid shared refactors and unrelated fixes. The coordinator updates
aggregate status and publishes the checked commit to main.

## Focused verification and handoff

Name concrete risks first. Default to three focused job groups on Forward+;
there is no hard ten-minute cutoff for routine finishing:

1. Check this saved rig/export: six fitted legs, supported abdomen/labium, useful
   deformation, retained maps and a few representative gait/action poses. Reuse
   existing source identity and scar-depth evidence; no parent reopen/BVH review.
2. Import and a short native Bog Lurker view/motion clip. Check actual pursuit
   and melee event, hit versus missed/blocked root application, existing dash
   escape, freeze/stagger/pause and instance independence. Reuse unrelated combat
   evidence; an animation-only fixture does not establish native root behavior.
3. One relevant ordinary generated-pack/death/Continue check: correct normal rig,
   progression/ownership intact, one driver, no replayed cosmetic strike. Reuse
   completed fauna/other-mob checks unless a concrete shared change affects them.

Use background Blender/headless checks when possible. Put imports, build output,
logs and private APPDATA/TEMP/saves on D:. Rendered checks hold the nonblocking
`Local\WroughtwildArtRender` mutex until the owned process exits, use verified
`--r8-no-mouse-capture` and disposable `display/window/size/no_focus=true`, and
assert visible mouse/unfocusable window. Script camera/input; never use the
owner's desktop pointer. Remove owned overrides and end owned processes at handoff.
Reuse existing runners; leave other tasks, source packages and remote access alone.

No benchmark gate, soak, renderer/seed/camera matrix or parent reconstruction.
Exclude documentation media from Godot imports when needed, as in MOB-04.
Fix concrete load/gameplay failures and record small cosmetic gaps. Do not expand
the slice into general performance investigation or close underground lag based
on this creature fixture. Preserve legitimate caves and digging.

Commit the complete checked slice on `codex/mob05-nymph` and return its exact SHA
for coordinator integration/push. Report actual gameplay achieved, limitations,
checks run, source provenance/new visual tuning and publication status. Include
exact normal-game launch/playtest steps. Show selected pictures and a short useful
motion clip inline in chat using absolute paths. Keep editable masters, generated
caches/builds out of Git; commit selected runtime assets, recipes and compact evidence.

Tortoise follows. Physical era forms and boss art remain separate. Underground
lag, station/campaign feedback and Reclaimed Frontier landscape direction stay
queued. R9 remains stopped.
