# Rare resources: rough hosts and contained light

Implemented by Codex (OpenAI), 6 September 2026, under the owner-approved
[leyline/resource visual work item](../prototype/leyline-resource-visual-2026-09-06.md).
The supplied reference informs environmental fractures and luminous deposits;
its character and interface are outside this pass.

## What changes in ordinary play

The five existing authored specimens retain their bodies, positions and useful
identities. Their shared surface now adds smooth wood grain, mineral bedding
and roughness variation. Added light belongs to narrow seams and small exposed
interiors, with the surrounding host remaining normally shaded.

| Find | Presentation |
| --- | --- |
| Lanternheart | Warm interior among papery folds; a tapered, ragged lower opening in the existing hollow reveals it from the approach. |
| Thrumroot | Weathered fibre and restrained pale tension threads around the existing coil. |
| Stormglass | Cool milky mineral surfaces, lit tube mouths and fine seams projected onto the actual tube skins. |
| Pullstone | Readable iron-grey facets, embedded pale fractures and a few locally suspended grains. |
| Ventlung | A darker empty mineral casing distinguishes the pale membrane and its surface seams. |
| Struck smithy | Narrow contained light on the old pressure casing; the visible membrane and stock light disappear when its native finite pressure is empty. |

The smithy remains an accidentally struck **pre-cataclysm** ruin. Its appearance
does not grant crafting access or imply a functioning older production network.
Existing crafted lamps, winches, levers, sorters, bellows and feeder art retain
their prior appearance.

## Shared geometry and state

`game/art/rare_finish.tres` and its resource script own presentation values.
`StrangeResourceArt` attaches one `RareFinish` child to each intact specimen;
`PressurePocket` supplies the native ledger's remaining/capacity fraction.

Detail meshes are cached once per kind. Mineral seam samples project against
the actual authored triangles, stop at misses and break across unsupported
spans. Short uncapped four-sided tubes use eight triangles per span; they have
no physical bodies. This replaces the initial free-standing wire appearance.
Host chips reuse the approved compact `deadfall` and `strange_low_outcrop`
meshes fitted into the same small bounds, rather than a full field boulder.

Visual stock uses the original generated node capacity identified by stable
resource ID, rather than the quantity remaining when its scene streamed in.
Ordinary work presses refresh the existing staged pose and seam exposure.
The normal whole-haul rare harvesting rules, stock, recipes and physical drops
are unchanged. No new persistent field is required. Depletion hides the intact
core and every added luminous detail; highlighting an empty source cannot
restore that promise. The existing separate site shell remains as aftermath.

## Tuning and cost controls

All controls and their plain-language purposes are in `rare_finish.gd`:

- Added details retire at 48 metres with an 8 metre margin. The existing core
  keeps its original distance; the pass adds no light or shadow network.
- Main seams have a 10 mm radius, with secondary branches at 48% of that width.
  Surface sampling is 45 mm and the centre is inset by 3 mm into its host.
- Core emission is 2.4, modulated by actual stock and slight work/hover feedback.
  Host colours, material mode and roughness distinguish all five families.
- Grain scale is 22 and strength is 0.3. Smooth analytic noise avoids a random
  screen-space dot pattern; cavity noise runs only on the hollow's material.
- Quiet shader motion is 8 mm at a 0.6 rate. Pullstone uses 11 small grain forms.
  Shader `TIME` supplies this local movement; no timers or per-frame geometry
  rebuilds were introduced.
- The Lantern opening is 0.7 metres in half-width and 1.25 metres high, with
  tapered, irregular edges; these are visual cutout bounds, not collision edits.

## Review and limits

The reproducible actual V5 seed-1 review is
`game/tests/leyline_visual_review.tscn`, with matched daylight/dusk outputs under
ignored `build/leyline-visual`. Its native hashes, harvesting/save checks and
indexed geometry counts are recorded by the integrated verification report.
Review processes use isolated outputs and do not load or write the owner's
normal save or interrupt their running playthrough.

The first actual views caught a hidden heart, detached Stormglass strands and
buried Ventlung detail. The pass opens the existing hollow and conforms mineral
seams to the real mesh surfaces instead of relying on a material-only assertion.
These remain stylised, faceted authored hosts; small grain and filaments are
close-range detail, not a replacement regional modelling pass. Final visual
acceptance belongs to the owner. Matched render results do not certify the
previously reported cold terrain-streaming hitches.

The final integrated rendered review passes 177 checks with zero failures.
Index-aware added mesh counts are 792 triangles for Lanternheart, 1,996 for
Thrumroot, 1,864 for Stormglass, 2,512 for Pullstone and 1,936 for Ventlung.
All added vertices remain within the original body tolerance. Ventlung's
daylight accent remains subtle against its pale membrane and reads more
clearly at dusk. [Integrated evidence and timing](leyline-resource-review-2026-09-06.md).

The corrected actual views show the heart through its hollow, Stormglass seams
ending on the tube skins and a Pullstone seam on its facing iron-grey plane.
Ventlung's crown seams are visible, but remain subtle in daylight against the
pale membrane; its darker casing and staged work provide additional contrast.
The current pass deliberately retains the existing faceted silhouettes rather
than claiming a new organic modelling finish.
