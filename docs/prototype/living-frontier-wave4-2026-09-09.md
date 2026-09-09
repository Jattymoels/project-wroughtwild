# Living Frontier Wave 4 — bounded implementation and evidence

Owner authorization: 9 September 2026. Repair **LF3-R1 first**, then implement
**LF-4A → LF-4B → LF-4C**, commit checked slices and stop for orchestrator review.
Baseline: `4cc5e3c`. The [Wave 3 review](living-frontier-wave3-review-2026-09-09.md),
[Wave 3 contract](living-frontier-wave3-2026-09-09.md) and
[roadmap](living-frontier-roadmap-2026-09-08.md) constrain this work.

## LF3-R1 contract, recorded before implementation

Preserve the published generation pass, including terrain, resources, packs,
homes, sources, host positions/habits, lab shells and both future envelopes.
After those positions are final, derive approaches against their physical
footprints. Recompute all three lab approaches, four host/source cue walks and
the collection trail; never feed the repaired routes back into site selection.
Use the ordinary 0.42 m capsule radius plus a small clearance allowance around
the complete exterior footprint, including projecting foundation and door trim.
These are derived paths, not saved ownership or a new generation profile.
Paid construction still suppresses overlapping cosmetic pieces locally.

Affected systems: native LF composition, route verification, engine traversal
fixtures and `living_frontier.json` clearance tuning. D-010/D-017/D-032/D-033
and the explicit review repair apply. No unresolved game-rule decision blocks
this correction. Construction may deliberately block a route; rerouting the
world around arbitrary paid walls is outside this generated-path guarantee.

Plan: retain failing seeds 5/77 and a pre-repair paid-trail checkpoint; correct
the derived walk; repeat the 37-seed sweep and actual capsule movement along
complete generated routes; verify old saves/paid overlap and affected regressions.
Only a passing repair enables Wave 4 work. Each later slice records its bounded
consequential decisions before implementation. Human comfort/art acceptance
remains separate from automated checks.

## LF3-R1 evidence

The retained negative controller tests stop against real `ExteriorBody` walls:
seed 5's collection segment **256** and seed 77's Central approach segment
**233**. Capsule corridor samples find **28 / 26** shell contacts respectively.
The test starts each route once, then uses the ordinary 5 m/s controller and
normal Space jump for existing metre ledges. It never relocates the player
between waypoints or uses a movement skill. The final endpoint must settle on
physical support. A centre-only first candidate also exposed a cave-edge fall
on seed 5's Central approach; the supported neighbouring band fixes that route.

The final native sweep passes **17,311 checks** across **0–31, 42, 77, 256,
1337 and 2147483647**. Complete pre-repair fingerprints retain all voxels,
finite resources, old paths, packs, homes, source anchors, hosts/habits,
laboratories and both future envelopes; only the derived LF walks are excluded.
Main rules **224,380**, Wave 1 **213,482**, Wave 2 **601** checks also pass.
These reruns link the just-built simulation objects from the existing CMake
build; the initial sweep also uses the existing `-FocusedNative` wrapper.

All **24 complete paths** in seeds 5 and 77 clear actual shell geometry and
pass ordinary controller traversal: the collection trail, all three laboratory
approaches, all four host approaches and all four source cue walks per seed.
Committed compressed pre-repair checkpoints contain gathered-and-paid timber
over an old collection mark, partial Red work and the complete original finite
resource ledger. Repeated fresh-process restoration retains ownership, while
corrected dressing yields to the paid overlap. Native voxel fingerprints and
engine complete-map hashes independently prove that route repair did not move
published geography.

`lab_route_clearance_m = 0.9` is the only new tuning value: 0.4 m foundation
projection + 0.42 m ordinary capsule + 0.08 m allowance beyond each nominal
half-size. The supported band is one native cell. Trail spacing, shell geometry,
source work/renewal, recipes and all saved payload formats remain unchanged.

Commands: `tools/living_frontier_wave3_checks.ps1 -Routes`, `-FocusedNative`
and `-Full`. Negative probes use `living_frontier_routes.tscn` with
`--lf3-r1-baseline --route-seed=5` / `77` on the published native build.
Receipts are in ignored `build/lf3/r1-*` logs and `routes-*-before/after.json`.
The [fixture record](../../game/tests/fixtures/lf3-r1-saves.md) explains the
committed historical saves.

Full-pipeline coverage: **113 ordered engine invocations plus four Foundry
identity scenes, all passing**. The first run reached invocation 109, where
the older Cataclysm persistence fixture retained a resource scene across travel
and streaming freed it. The fixture now retains its stable ID and rematerialises
at the second visit; all harvesting/persistence assertions remain. Rerunning
109–113 and all four identities passes (Cataclysm **171 checks**). The expanded
visible-dressing and exact-inventory checks pass **35 + 37 checks** separately.
The final full-route runs pass **56 + 58 checks**. Documentation checks find
130 valid local targets; scoped whitespace passes. LF3-R1's repair gate is clear.

Limits: this samples 37 seeds, with full physical routes in the two reported
regressions. Ordinary jump input is scripted and does not establish human route
comfort. Deliberately blocking a trail with paid construction remains permitted;
the repair preserves that ownership rather than changing the building rule.

## Wave 4 contract, recorded before implementation

These selections implement the requested roadmap within a separate opt-in
campaign policy. They do not enable progression before LF-4A passes.

- **Identity:** retain `living_frontier_wave3` as the immutable geography and
  source/machine identity. New `--living-frontier-wave4` games select an explicit
  saved `living_frontier_wave4` campaign policy and a separate default save.
  Missing policy means the published campaign, including old LF worlds. Loading
  follows the saved policy, never the launch flag; there is no automatic conversion.
  Acquisition, source formation, recipes, grades and owned rewards retain their
  published policy. This wave does not globally remove existing Catalyst paths.
- **LF-4A:** Retained Fen's already-declared 40 m envelope receives a deterministic
  retained bank/shelf, rising by at most two metres with blended margins. It
  changes the native voxel terrain and its rendered collision. Base seed, all
  three labs, the other declared envelope and existing resource identities stay
  fixed. The saved sparse transformation is versioned and replayed exactly.
  An isolated fixture schedules the event; no Trial schedules it until LF-4C.
- **Protection:** retain entire columns around current paid footprints (including
  bridges, supports, doors, workstations and machinery), excavated columns,
  source attachments, returns and owned recoverables. Protect existing sites and
  finite resource workplaces as well. Blend displacement down at protected
  margins and prevent any originally ordinary terrain edge from becoming a
  taller obstacle. Existing ordinary approaches remain available. Local buffers
  do not freeze a whole biome for one block; they are captured once at the event,
  with no accumulating immunity from earlier place/remove operations.
- **Event transaction:** first qualifying victory records pending resonance and
  its first-clear receipt once. On safe overworld return, checkpoint pending
  ownership, prepare and validate the complete protected candidate, commit its
  matching save, then publish physical geometry. Failed preparation/publication
  retains a recoverable pending checkpoint and an explicit retry. Never mutate
  terrain under an active Trial, mixed restore or moving combat encounter.
  Restart before and after publication must neither replay payment nor reroll
  geography. A fully occupied envelope may defer preparation instead of erasing
  paid work; the reason must be explicit.
- **LF-4B:** the existing Collection Annex door is the physical entry. Reuse the
  existing two-floor Tyrant topology and mechanics, with a bounded laboratory
  treatment: collection/containment apparatus, individually altered Red/Blue
  specimens and inspectable later human intervention. Emergency return conduits
  foreshadow the failsafe before victory. The old asteroid-struck smithy retains
  its accidental pre-cataclysm history. No human boss or hybrid is implied.
- **LF-4C / D-019 and D-028 replacement:** first Annex victory queues its failsafe;
  successful safe publication grants the existing `stonecut_blocks` era-two
  milestone and its existing Foundry/building/alloy consequences. The Tyrant
  Heart is a once-only trophy, not a second era switch. Its hill-cairn use is
  optional remembrance with no additional capability or payout. Ordinary run
  loot retains its normal per-run settlement. Repeated victories, suspended runs
  and reloads cannot repeat the first-clear trophy, milestone or transform.
  Legacy worlds retain both original curio gates and their rewards unchanged.
- **Useful consequence:** the raised Retained Fen bank exposes a small finite
  copper/tin opportunity for ordinary bronze work, using distinct era-event
  resource identities, and an additional existing Blue host expression in the
  changed habitat. Existing lots, ore depletion and finite host deaths remain.
  No new currency, harvest gate, mandatory Catalyst or hybrid is introduced.
  Exact counts, spacing, protection margins and presentation values will be
  recorded with their data before use.

Pairing Hall, Central Laboratory and Excited Uplands remain visible future
ambitions in this incomplete opt-in campaign. LF-5–7 progression, the second
transform, human finale and configured Heat are unavailable, rather than opening
the old later Forge stories through an unintended bypass. Human discovery,
combat balance and final laboratory/ice art remain review questions.
