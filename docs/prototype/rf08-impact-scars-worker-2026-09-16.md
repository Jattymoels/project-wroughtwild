# RF-08: recovered impact edges and living scars

## Selected original-plan outcome

On 16 September the owner agreed with the coordinator's RF-07 assessment and
said "let's move on". RF-07 is adopted with its visual weaknesses recorded for
cleanup. This is the remaining original Reclaimed Frontier composition slice:
established life growing over old impact damage, with selected dark fractures
and contained pulsing light still revealing the world beneath. Bounded cleanup
follows this slice. Do not resume highland/fen revisions or start another art,
performance or all-biome production wave.

Workspace: `D:/Wroughtwild/work/rf08-impact-scars`.
Branch: `codex/rf08-impact-scars`. Exact base/runtime: `build/rf08/SETUP.md`.
The owner starts the worker; do not launch parallel or next tasks automatically.
RF-08 is a Reclaimed Frontier slice, unrelated to the historical ART repair R8/R9.
R9 remains stopped.

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and its required
reading order, then this owner-depot prompt. Read the intended-result and living-
scar sections of [Reclaimed Frontier](reclaimed-frontier-intensive-2026-09-14.md),
the relevant [world-generation](../systems/world-generation.md) presentation
sections, and the [art direction](../art/art-direction.md) for grounded fractures
and ordinary/work/danger meanings. Inspect actual owner references ENV-005 and
ENV-006 in the [gallery](../art/references/environment/2026-09-14-reclaimed-frontier/README.md)
with [owner wording](../art/references/environment/2026-09-14-reclaimed-frontier/owner-intent.md).
Image three was closer to the intended feel but too crater-focused: green life
over old chaos matters at least as much as the impact. The references do not
authorise a new event, more craters, exact style or rewritten world geography.

## What the player should see

Walking from ordinary living ground toward an existing impact and exposed trace,
the player should read one connected place: grown-over damage, weathered remnants
and an occasional surviving seam of energy. The surrounding land remains useful
and alive, rather than a bare circular display area around a glowing prop.

Deliver three visible outcomes together:

1. **Recovered margins:** irregular tongues and pockets of appropriate ground
   growth meet existing impact slopes, fragments and exposed rock. Use low cover,
   litter/soil and selected grounded debris to connect old disruption to the
   surrounding biome. Preserve open routes, visible ground and broken rock; avoid
   uniform planted rings, repeated bowls or blanket grass over the whole scar.
2. **Physical scars within the land:** selected exposed native trace stretches
   read as narrow branching dark mineral fractures, tied to the host ground and
   impact direction. Chipped edges and intermittent vegetation partly conceal
   their margins. The physical mark remains readable with emission disabled;
   it must not depend on a floating luminous strip or uniform drawn outline.
3. **Quiet living light:** restrained pulses/variation move the eye along selected
   exposed lengths without lighting the entire region or hiding the dark fracture.
   Preserve the distinction from attacks, active machinery and finite-source
   readiness. Some lengths stay dark, while the surroundings remain mostly unlit.

## Develop the actual place before expanding its rules

Start with one existing V8 seed-77 meadow/woodland impact margin and a nearby
native exposed leyline stretch selected from actual map records. Pick a place
where an ordinary short walk can show the transition, not a disconnected gallery.
Do not assume coordinates, relocate a source or manufacture an impact/trace fixture
to make the screenshot work. If no single connected short route captures both,
disclose the two real locations and keep their ordinary gameplay intact.

State the intended three visible changes briefly. Establish the plant/ground/
fragment relationship and physical scar in one normal player-height view early.
If the view still reads as separate clumps around a bare circle or a neon road,
revise that dominant art/composition weakness before polishing the report/tests.
Reuse existing approved kit and current RF-01/02/06B/07 biome treatments where
suitable. Author only small missing Blender/material elements if necessary; no
large catalogue. Source retention and available local tools are in SETUP.
Follow the imagegen skill if making a concept or texture; concepts are not game
evidence. Reuse appropriate art without treating reuse as a reason to accept an
unconvincing visual result.

Apply the demonstrated treatment through deterministic seed/profile/map context
in normal New World and Continue. No coordinate-specific showcase code. Primary
new recovery composition is meadow/forest impact margins; where the same actual
impact/trace crosses eligible fen or Rocky Hills, retain that biome's adopted
kit and identity through its existing compositor rather than planting meadow or
wetland plants everywhere. Keep ember-waste ecology and older V1-V5 presentation
unchanged. V6/V7/V8 and existing LF profiles receive the scoped cosmetic treatment.
Broad crater size/frequency, mountain scale and new landforms remain future design;
do not claim this presentation slice solves those generator outcomes.

## Inspected implementation leads and concrete boundaries

- `game/scripts/cataclysm_sites.gd` consumes native `impacts`, `ruins` and
  `leylines`; `_impact` relates existing fragments to incoming direction.
  `_trace_records` tiles native paths/exposure and `_trace` uses current terrain
  support. Keep site IDs, source/discovery relationships and the small accidental
  blacksmith strike distinct. Do not turn the smithy into another giant landmark.
- `game/scripts/leyline_fissures.gd`, `game/art/leyline_look.gd` and
  `game/art/leyline_fissure.gdshader` already supply grounded opaque dark mouths,
  chipped lips, narrow interrupted light and bounded branches. Only native
  exposure `2` is drawn; buried `0` and broken `1` are excluded. Preserve that
  authority, actual support and paid clearing. Improve/reuse this path rather
  than adding a second fake glowing network.
- Current ground-light modulation is only 2.5% over 47 seconds. If it fails the
  requested visible living-light intent, tune the scoped eligible presentation
  to a quiet, observable pulse while preserving the established colour/readability
  contract. Do not change V4/V5 visuals by globally editing a shared default.
  Honour applicable existing pause/motion preferences; avoid attack-like blinking.
- `StrangeSites._reservations` includes an entire impact exclusion at 60% of its
  radius, mixed with real resource/ruin/approach protection. Identify those roles
  explicitly. A scoped replacement of only this cosmetic impact exclusion is
  allowed where it is necessary for recovered margins; preserve exact resource,
  source, building, ruin and approach clearances and the actual fragment footprint.
  Do not globally reduce all reservations to obtain denser pictures.
- Reuse RF cover masks, actual footprint sampling, paid suppression and chunk
  lifetimes. Prefer a small `game/rf08/` context/tuning module and targeted hooks;
  avoid a generic decoration framework or stacked duplicate old/new planting.

All changes remain presentation. Preserve native heights/voxels/collision, caves
and digging, water/swimming, profile/seed, impact and leyline topology/exposure,
finite source stock, yields, interactions, player structures and progression.
No save migration/new fields, source regeneration, damage, buffs, extraction
capability, placed infrastructure or restored post-catastrophe civilisation.
Native state alone determines actual readiness/work/danger. Cosmetic light must
not imply replenishment or an actionable object where none exists.

Supported dressing cannot bridge excavations, create a fake walkable shelf or
remain under a paid octagonal floor/station. Preserve laboratory/trial approaches
and both LF terrain publication paths. Keep global camera/exposure, unrelated
tree art and biome palettes intact. New queries must be bounded and cached at
existing build/refresh points. Preserve CataclysmSites' deferred per-tile trace
refresh and sampled-support reuse; do not reintroduce full-network work on every
chunk arrival or building edit. Shared heavy assets prepare/reuse at world entry.

## Focused checks and handoff

Concrete risks: falsely lit native buried/broken traces, floating scars or plants,
blocked source/paid-work access, and refresh changing owned state. Reuse earlier
native/LF/save evidence. Default to three focused jobs on Forward+:

1. Changed composition/support/clearance: one real affected impact/trace, a local
   dig/rebuild, paid octagonal floor/station and source approach, native exposure
   exclusions and a cheap deterministic seed/profile boundary spot check. If the
   cosmetic impact reservation changes, explicitly retain the other reservation
   types. No all-biome/seed/material matrix or full campaign replay.
2. One fresh-process Continue with exact native identity, finite source work,
   paid possessions/structures/stations and reconstructed presentation. Native
   exposure and source availability remain identical. Reuse unchanged lake/LF
   evidence; do not create another full regression suite.
3. One short real player-height route showing recovered ground, old damage and
   exposed living scar. Keep ordinary world systems/HUD/lighting active. Retain
   roughly three useful pictures plus a short real-time clip long enough to show
   the actual selected pulse; no accelerated time, fake glow or retouched evidence.
   In this same focused run, take one brief emission-disabled view to establish
   physical readability and restore normal state. This is not a second renderer
   or an art/performance baseline matrix. Inspect the actual final pictures.

An early art look is useful before the final changed-behavior checks. Revise an
obvious dominant weakness, then stop when the scoped playable iteration is clear;
no perfection or exhaustive review requirement. Keep raw logs/private state on D:,
use background Blender and verified no-focus/mouse opt-out for automated captures,
write BOM-free overrides, retain process handles and end owned tests.

Return checked commit SHA(s), `docs/prototype/rf08-impact-scars-result-2026-09-16.md`,
actual game images embedded in chat with absolute paths, editable-source/recipe
paths, remaining visual/technical weaknesses and an exact private play command
using `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...`. Preserve old
private progress and owner saves. Separate appearance from functional checks and
actual commit/push status; never infer aesthetic acceptance from assertion counts.
Coordinator integrates/pushes main. Stop after RF-08; consolidate notes for the
subsequent bounded cleanup, but do not start it or a wider intensive automatically.
