# Living Frontier Wave 1 — orchestrator review

8 September 2026. Reviewed baseline: `ecd0bdc2354bcbf24d1152ecd58951878e1cd992`.
The three implementation commits are `e6feb0b`, `42ee83d` and `ecd0bdc`;
local `main` and `origin/main` both point to the reviewed final commit.

**Verdict: one blocking correctness issue before Wave 2.** The implementation
delivers the ordinary extraction, crafting and connected cargo journey, but a
source cannot recover from an ordinary excavation even after paid construction
physically restores its support. This review changes no gameplay rule or code.

## LF1-R1 — A supported repair cannot recover an undermined source

Priority: P2; blocks expansion of these source rules into Blue and Green.

[LeylineSource.supported()](../../game/scripts/leyline_source.gd#L83) asks
`StrangeSites._ground()` for terrain height and rejects before considering a
player-built supporting surface. That helper samples terrain triangles only.
Both collection/work and formation readiness use the result. The UI tells the
player to restore ground support, but a paid timber block cannot satisfy it.
Red and White share this implementation; the concrete reproduction used Red.

Reproduced in a fresh seed-77 experimental world:

1. Gather ordinary wood and approach the Red host at `(469.5,31,438.5)`.
2. Complete a lot, retaining its released material in the source.
3. Remove the hand-diggable surface cell `(469,30,438)` beneath it. The source
   becomes unsupported, as expected.
4. Pay the ordinary timber-cube cost and place its native registered block at
   lattice volume cell `(938,60,876)`. Its physical centre is
   `(469.5,30.5,438.5)` and its top restores support at the original source base.
5. A physics ray confirms a real `PlacedBlock` supports the host, but
   `supported()` and the source's work/collection eligibility remain false.
6. Capture and restore the complete checkpoint. The repair and exact source
   claim persist; the source remains unusable.

Diagnostic output:

```text
SOURCE_START supported=true
DUG material=surface supported=false
REPAIR paid=true placed=true physical_support=true source_supported=false claim_exact=true
COLLECT_ALLOWED false
RESTART restored=true supported=false claim_exact=true
```

The probe used ordinary finite-resource gathering, the terrain's normal
hand-diggable removal rule, native placement payment and registered construction.
It invoked those routines directly to isolate support handling; it is distinct
from the full input-driven journey below. Local diagnostic files are
`game/tmp/lf1_orchestrator_probe.gd`, its `.tscn`, and
`build/lf1/orchestrator-probe.log`; they are ignored test artifacts.

Required repair: recognise valid restored physical support at the existing
anchor while retaining workspace obstruction checks. Do not move the source,
refill its stock, reroll its outcomes or introduce an invisible no-dig area.
Add a regression for both hosts: unsupported refusal, paid support repair,
resumed collection and formation, renewed obstruction, and exact saved recovery.
Already saved undermined hosts must become repairable without resetting them.

## Independent verification completed

The current native extension was rebuilt successfully. The documented runner
was then rerun against the reviewed source and tuning:

| Check | Independently observed result |
| --- | --- |
| LF native extraction/crafting/connection tests | 128,078 checks, zero failures |
| Complete existing native rules suite | 224,380 checks, zero failures |
| Empty-pack paid engine journey | 733 checks, zero failures |
| Fresh-process restore and cargo delivery | 15 checks, zero failures |
| Seven affected engine regressions | Catalogue 52, contraptions 85, pressure 60, loose drops 148, save recovery 175, weathered save 21, wide-frontier pacing 319; zero failures |
| Committed diff whitespace | Pass |

The expected malformed-save fixtures emit refusal warnings. The committed
Ember recipe and connected White lever captures were visually inspected; the
new independent engine rerun was headless. The support probe above exposes a
case not covered by the passing suites, so their counts do not clear LF1-R1.

Ordinary discovery, four-action effort, the 96-Salt price, formation cadence,
host visibility and circuit usefulness still need owner playtesting. Hostile
AI and travel pacing are controlled in the scripted journey. These limits are
already honestly recorded in the [implementation handoff](living-frontier-wave1-2026-09-08.md).

## Next-session boundary

Begin with the LF1-R1 repair and its saved-world regression. Verify that repair
before extending the source system. Wave 2 remains the four proposed slices in
the [roadmap](living-frontier-roadmap-2026-09-08.md#lf-2--give-all-four-materials-a-construction-purpose):
Blue source/delay, Green source/junction, bounded Red heat storage, and complete
ordinary recipes plus a useful combined workshop. Preserve the opt-in boundary,
existing source ledgers, signal/energy separation and normal-world acquisition.
This review does not grant an unconditional Wave 2 all-clear.
