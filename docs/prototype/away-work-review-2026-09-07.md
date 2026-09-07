# Independent development review

7 September 2026. Assessed against `main` at `57696a5`.
**Status: proposed priorities; no new implementation or design acceptance.**

The owner asks what remains worthwhile without their playtesting and whether
high-quality Blender work should follow. The recommendation is a bounded
playtest-readiness wave, followed by one finished visual target. Art is now a
useful next intensive; it need not wait for final combat balance.

## What the existing work establishes

All seven [tracked intensives](intensive-queue.md) have implemented initial
slices. Save recovery, actual home/trial traversal, crafting clarity, feedback
and measured streaming have received focused verification. The remaining owner
reviews concern comprehension, comfort, discovery excitement and build expression.
Passing those checks cannot be inferred from more scripted runs.

Generation already has a [64-seed matrix and historical fingerprints](wide-frontier-intensive-2026-09-06.md).
The latest [performance work](frame-pacing-2026-09-07.md) measured an actual
integrated GPU and fixed a reproduced ground-support failure. The intermittent
pause remains unresolved. Resume that investigation when a capture identifies
something actionable; further general optimisation or a larger seed count is
not the recommended next intensive without a specific concern. Godot's guidance
likewise emphasises measured bottlenecks and selective effort.
([Godot 4.5 optimisation guidance](https://docs.godotengine.org/en/4.5/tutorials/performance/general_optimization.html))

## Recommended next work

| Priority / tracking | Concrete work | Evidence possible while the owner is away |
| --- | --- | --- |
| 1 — INT-08A: controls and comfort | A compact settings screen for mouse sensitivity/inversion, field of view, volume, optional cosmetic motion, display options and keyboard/mouse bindings. Prompts follow bindings; settings persist separately from world saves. | Exercise actual controls, reset defaults, restart persistence, binding conflicts, readable menus at supported sizes, and absence of settings changes to saved runs. Subjective comfort still needs the owner. |
| 2 — INT-08B: portable Windows playtest build | A repeatable local export containing the native extension, tuning and required assets, with an identifiable build version. | Launch from a separate folder with no repository-relative data dependency; verify first launch, gathering/crafting, an existing save and a suspended trial using isolated test saves. Repeat the export from tracked sources. Other-machine compatibility remains unverified until tested there. |
| 3 — INT-02B: finished visual target | Finish one existing asteroid-struck smithy and its approach, with a nearby existing rare discovery. Establish a reusable standard for shapes, surfaces, ground contact, lighting and vegetation. | Actual Godot daylight/dusk views, a short first-person walk, interaction/depletion states, collision clearance and matched frame timing. The owner can review direction through images/video before broader adoption. |

The first two are individually bounded slices, not prerequisites for a store
release. Do not expand them into a general settings framework or a distribution
service. The art target can be prepared independently if export tooling takes
longer than expected.

### Why these are real gaps

Current `player.gd` exposes mouse sensitivity as a scene property, and input
bindings live in `project.godot`. This audit found no runtime settings/remapping
screen or preference store. Cosmetic landing motion and locally set audio gains
also lack player controls. A small settings pass helps the next playtest produce
feedback about the game rather than an uncomfortable setup. Microsoft's game
accessibility guidance recommends configurable camera motion and sensitivity,
remapping, and hints that reflect changed bindings.
([Camera settings](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/117),
[input and prompts](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/107))

There is no tracked export preset or export helper. `Sim.get_tuning_directory()`
resolves `../data/tuning` outside the Godot project, while the native extension
loads tuning from disk. That dependency needs an explicit packaged location.
The standard local `4.5.stable` export-template directory was absent; this does
not establish whether templates exist elsewhere. An exported-game launch was
not attempted in this review. Godot requires export presets/templates and
explicit handling of non-resource files such as JSON.
([Godot 4.5 export documentation](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_projects.html))

## The Blender intensive

The local connection reports Blender **4.5.9** available for background jobs.
The [existing authoring pipeline](../../tools/wroughtwild-blender/README.md)
already produces editable studies and GLB assets, with scale, pivot and collision
checks. The current bridge exposes preset study builders; new asset work extends
the local authoring recipes. Another connector is not currently needed.

Start with the [previously proposed playable visual target](playtest-feedback-2026-09-06.md#proposed-visual-target)
under the accepted weathered-frontier and accidental-augmentation direction:

1. Select an existing site/seed and capture its actual gameplay baseline.
2. Develop a small reusable set of broken masonry/timber, rocks, appropriate
   vegetation, embedded technological detail and one existing rare host. Work on
   convincing silhouettes, UVs, baked surface detail, roughness and edge wear.
3. Assemble and iterate inside Godot with terrain transitions, contact shadows,
   restrained light/motion and clear gathering approaches. Keep current resource
   IDs, stock, working spaces, collision and saved geography authoritative.
4. Deliver editable sources/recipes, curated game exports, distant-detail
   treatment where useful, and matched normal-game captures/timing. Review the
   style before multiplying it across the world.

This aims for a finished place and a repeatable asset standard. A detailed
model alone cannot establish the quality of the assembled environment. GDC's
production guidance includes focused art tests alongside technical prototypes;
Godot recommends glTF for the Blender-to-engine handoff.
([GDC production workshop, slide 21](https://media.gdcvault.com/gdc2026/Slides/Marty_Fleur_ProductionWorkshopPart2.pdf#page=21),
[Godot 4.5 3D formats](https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html))

High-quality environment assets are the first target. A complete creature-rig
replacement has additional deformation, body-fit and combat-tell implications;
it should follow a successful environment benchmark and a separate bounded brief.
Final taste is still the owner's judgement. Existing references support a first
candidate, without assuming photorealism or a permanently dark world.

## Other work and deliberate stopping points

- The [era-sensitive gear preview](loose-drop-persistence-2026-09-07.md#separate-finding-gear-at-an-era-transition)
  remains a concrete correctness follow-up. Confirm the intended item-roll
  moment before changing persisted drop identity. This review does not settle it.
- A furnishing kit or further inert environmental stories can follow an agreed
  visual target. New resource scarcity, automation chains, biomes and world size
  need their own player-experience decisions; they are not consequences of art.
- Combat/build calibration, complete-run pacing, discovery excitement and
  first-hour clarity still need ordinary play. Existing legal-build comparisons
  can expose broken mechanics, but cannot certify these experiences.
- Keep earlier-profile compatibility and the known timber-demolition conflict
  outside new scope. No tuning values or accepted rules change in this review.

Verification for this assessment was a read-only repository/document audit,
Blender availability query and primary-source research. No Blender creation job,
gameplay test, export or new benchmark ran. Only planning records were edited.
