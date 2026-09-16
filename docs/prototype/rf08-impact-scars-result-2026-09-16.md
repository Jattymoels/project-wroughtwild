# RF-08: recovered impact margins and living scars

RF-08 brings low woodland growth, moss/litter transitions and settled chips into
previously bare impact margins, while exposed native fractures retain a physical
dark mouth and a quiet visible pulse. It is installed in normal eligible New World
and Continue on main as `ef9601b`. The result is a usable presentation iteration;
its steep bare slopes, strong tree shadows and angular scars still fall short of
the fuller reference atmosphere. The owner called it a good start and approved
merging on 16 September; full aesthetic success is not claimed.

## Coordinator adoption and owner feedback — 16 September

The owner wants more "meaty" cracks with different coloured magic pulses deep
within, like the AI image placeholders, and asks whether a proper art pipeline
is needed. The coordinator agrees after inspecting all four retained game PNGs:
the narrow angular surface ribbons and pale fine light do not yet read as broken
rock enclosing a deep, living interior. Strong shade further conceals their
physical form. This assessment uses stills and source, not a new live playthrough
or a claim to have watched the retained pulse animation.

The implementation explains part of the gap: its mouth remains a surface mesh
with at most 4.2 cm of raised lip relief and the existing cool-white core colour.
It does not create a recessed terrain cavity or multi-coloured interior layers.
Increasing emission alone will not supply missing shape, depth or material.

Recommended separate art scope: establish one convincing fissure section in
ordinary player-height play, using a reference/concept, authored broken rock
lips and inner walls, a dark recessed reading, irregular embedded coloured
mineral light and slow layered pulses. Resolve its fit/occlusion against actual
editable terrain before expanding into reusable branching/end sections along
the native exposed network. Direct Blender modelling/material work is suitable;
image-to-3D can be considered for solid rock forms, without making it mandatory
for the whole fissure. Do not add colour-to-gameplay rules or a second network.
This is a substantive art follow-up, not a small glow adjustment or an implicit
all-asset rebuild. It is recorded for later scoping, not started by this adoption.

Fast-forwarded the checked worker commit `ef9601b93f487abdedad054482648f62933a87f6`
onto main, reusing its 37 support/ownership, 17 Continue and 10 Forward+ route
checks. Main's hidden headless import passed in **4.88 s**, exit 0 and zero
reported errors; output is in the D: worker's `build/rf08/main-integration-2026-09-16`.
Native DLL unchanged. Only committed worker changes were adopted; unrelated local
capture/import files and all private progress remain untouched. The coordinator
import ended; no test remains running. This completes adoption of the scheduled
creative slices. Bounded cleanup is next; full reference atmosphere remains open.

## Delivered appearance

The real V8 seed-77 Rootvault impact is centred at **(479.5, 29, 171.5)**, radius
13 m. The initial scene used its actual `lyv6_rootvault_wildwood_glasswind_uplands`
exposed segment, around **(489, 35, 180.5)**. No impact, trace, source or tree was
moved. The final 19.54 m walk follows the existing impact approach from
**(481.5, 37, 196.5)** toward **(481.5, 34, 176.5)** in the same place.

Early views showed an overly bare margin and a black strip/bright-wire reading.
The revision added one original broadleaf creeping mat, stronger connected moss
colour, warmer chipped lips, and reduced core albedo. Seventeen supported cover
roots enter the former blanket exclusion in the selected fixture. This is a
local observation, not a whole-world coverage measurement or proof of lushness.
Native steep surfaces and protected spaces still reject much of the cover.

- [Ordinary approach](rf08-evidence-2026-09-16/01-recovered-impact.png)
- [Impact and exposed scar](rf08-evidence-2026-09-16/02-living-scar.png)
- [Close growth, fragments and scar](rf08-evidence-2026-09-16/03-growth-and-fragments.png)
- [Emission disabled](rf08-evidence-2026-09-16/04-emission-disabled.png)
- [Real-time pulse clip](rf08-evidence-2026-09-16/living-scar-pulse.gif)

These are actual unretouched Forward+ game views with ordinary HUD/lighting/world
systems. The GIF only resizes/quantizes captures and retains their measured wall
intervals; no accelerated clock or painted glow. The dark geometry remains with
emission off, although deep shadow weakens its readability. Emission was restored.
All four final PNGs were inspected. They do not establish owner aesthetic approval.

## Boundaries and implementation

V6/V7/V8 and existing LF identities receive the scoped presentation. RF01's low
cover reservation replaces only the cosmetic 60%-radius impact blanket with
conservative actual fragment footprints. Resource, ruin, source/clue, approach,
laboratory, spawn and paid work protections remain. Large regional trees retain
their former reservation. Fen/highland crossings use their adopted cover kits;
new moss/mat composition is meadow/forest only. V1-V5 and Ember Wastes ecology stay
unchanged; the accidental smithy remains small and separately protected.

The existing tiled fissure renderer still draws only native exposure 2; buried 0
and broken 1 remain undrawn/unlit. A reproduced suspended-scar-after-dig case was
fixed by requiring original top-cell support in addition to sampled triangles.
The added query cache resets for each tile rebuild. Existing deferred refresh and
sampled-support reuse, mob/scenery entry preparation, terrain/collision/caves,
lakes, finite stock/yields, ownership, progression and save schemas remain.
No native code, native tuning tables, DLL or generation inputs changed. No new mechanics.

Tuning and source purposes are in [RF08 settings](../../game/rf08/settings.json),
[scar look](../../game/rf08/fissure.tres) and [source/recipe notes](../../game/rf08/SOURCE.md).
The new editable master is
`D:/Wroughtwild/source-art/rf08-impact-scars/rf08-creeping-mat.blend`;
recipe `tools/wroughtwild-rf08/build_mat.py`. Shared art prepares at actual entry.

## Focused verification

| Job | Actual outcome |
| --- | --- |
| Changed support/composition/ownership | 37 checks passed: real impact/scar, exact preserved reservation records, fragment footprints, native exposure exclusions, one second-seed context spot, chunk rebuild, real dig/restore, paid nine-piece octagonal floor and workbench, partial finite work and unchanged native identity. |
| Fresh-process Continue | 17 checks passed: exact native possessions/progression, resource/source state, buildings/stations, exposure/geography, reconstructed cover/clearance, actual movement and private resave. |
| Short Forward+ route | 10 checks passed: 19.54 m of ordinary walking along the native approach, live world/mobs/HUD, more than one real-time 7.5 s pulse cycle, emission-off/on and free mouse/no focus. |

Final runs exit 0 with zero reported script/shader/engine errors. The final
placement repeat specifically checks invalidation after adding the per-tile
support cache; it is not a new review wave. Earlier failed development logs stay
in `build/rf08/logs/`: an indentation error was corrected; the original support
probe was oversized for the smaller plants; the genuine dug-scar defect was fixed.
The first capture route hit the raised paid-floor edge (three route failures),
so the retained capture follows the real native impact approach. Paid placement
and station use remain separately checked; no controller rule was changed.

The copied matching DLL and unchanged lake/LF/arrival evidence were reused.
No all-seed/renderer/hardware matrix, full campaign or performance clearance was
run. All owned test/Blender processes finish; the temporary no-focus override is
removed. Prior owner/private saves and previous workers remain untouched.

## Exact private playtest

Run this in PowerShell; it changes execution policy for that process only:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:/Wroughtwild/work/rf08-impact-scars/tools/wroughtwild-rf08/play.ps1"
```

Choose **Continue saved world**. The first launch copies the paid/finite-work
fixture with only its initial player pose set to the native approach already
walked above. Subsequent launches preserve private progress, including a previous
checkpoint. It uses `build/rf08/playtest-impact/user/`, separate from owner saves.

Face forward/north and walk down the existing clear approach into the impact.
Pause beside a pale exposed seam for at least eight seconds. Compare the green
pockets, dark mineral mouth and embedded fragments with the surrounding litter.
The paid floor is at **(490, 35, 180)** and workbench at **(484, 37, 183)**, east of
the route. Approach the raised floor from suitable ground or use normal building
access; the direct downslope approach was not walkable in the capture fixture.
Use **WASD/mouse**, **E** to interact, **H** for controls and **F5** to save.
Normal enemies remain active. Close the game when finished.

Append **`-Fresh`** to open a separate private seed-77 New World slot at the ordinary
starting point. It does not replace existing impact-playtest progress.

## Remaining weaknesses and stop boundary

Growth is still sparse on steep/native terracing and broad clearances. The small
mat repeats at close range, and ordinary ground/tree art can dominate the scene.
Deep shadows flatten the fragment and physical mouth; some exposed lengths still
read as angular graphic ribbons. Pulse is intentionally fine in daylight and
weak at distance. Larger impact-landform variation and broad tree/material
production remain separate scope, not claimed solved here. Loading time and the
previously recorded lag questions remain unmeasured/open.

These notes feed the original wave's bounded cleanup; they do not dispatch it.
RF-08 was completed on `codex/rf08-impact-scars`, based on
`535fb1edeb2399323cb288917cf15ae9f507a2f6`, and subsequently adopted by the
coordinator as recorded above. R9 and PLAY-06 remain parked.
