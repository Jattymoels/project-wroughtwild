# ART-01 — boar and living scars

Status: **Technically complete; owner visually approved, 9 September 2026.** Owner continuation: "Alright let's do it"
selects the first bounded slice of the [asset roadmap](leyline-asset-roadmap-2026-09-09.md).
Baseline: `cf9cfd3`; unrelated Living Frontier work is present and preserved.

Outcome: preserve the owner's generated boar, author recessed branching scars,
show a controlled pulse in Godot, and prepare the source/rig/movement handoff.
This is an isolated art candidate under D-013/D-030. Existing game bodies,
combat clocks, save ownership, moth and other normal assets remain unchanged.

Affected files: the boar authoring tools and study settings, isolated Godot
material/review fixture, intentional source/candidate files and review evidence.
No gameplay tuning is selected. The original local GLB has the pinned SHA-256
`2a889ab30879bf6a4854ebe6def3e1b696d8a411ffaee6f215c7398bebe7abef`.

Plan: surface/no-light comparison → controlled pulse and movement → measured
detail levels and handoff checks → reviewed evidence and scoped publication.
Routine scar paths and comparison settings follow the selected brief. Runtime
adoption and any body-fit changes remain later work; no new attack is invented.

## Reproduced surface problem

The source has base colour and metallic/roughness, but no emission layer.
The first authored mask interpolated sparse vertex values across the broad
shield plates, creating triangular glowing patches instead of narrow cracks.
That result is retained locally as `build/boar-art01/surface-review-v01/`.
The corrected method bakes linear object position into the existing UV atlas
and evaluates authored projected paths per texel. Surface-attached masks then
remain separate from the ordinary colour and animated light.

## Delivered behaviour

The liked silhouette remains a heavy, recognisable boar. Five sparse projected
scar branches cross the shoulder shield and adjoining hide. A shallow physical
incision and dark rough edge remain with emission off; the narrow inner core
travels along the UV-attached branch data while the animal moves. The default
four-second crest retains 25% light between peaks. There is no bloom, transparent
overlay, per-crack light or gameplay effect.

The isolated Godot review offers off/steady/breathing/travelling light, day/shade,
2.5/4-second periods, 25/50% minimum, six poses, camera orbit/distance, detail
selection and a status-priority demonstration. One material carries independent
per-instance phases and an explicit pause-aware cosmetic clock. Blender node
animation is not assumed to survive glTF: the review binds the shader explicitly,
and each GLB has a safe ordinary PBR fallback when opened independently.

The packed editable source includes the intact normalized reference, authored
surface, near/mid/far candidates, sixteen-bone rig, clips, UVs and packed images.
The separate local package contains the importable review and previews as well,
at `build/boar-art01/boar-handoff/`. Its 62 files match the inputs of the separately
reopened/reimported verification copy; the clean delivery contains no imported
engine cache or user-data directory.
The [recipe](../../tools/wroughtwild-boar/README.md) documents rebuild/import and
the [evidence index](../art/leyline-studies/2026-09-09/boar-art01/README.md) records
the actual renders, stream audit and measurements.

## Failures reproduced and corrected

- Sparse vertex-mask interpolation produced glowing triangles on the shield.
  The final mask is evaluated per texel from a baked surface-position atlas.
- Embedded source images are WebP. Writing those bytes under `.png` names was
  accepted by parts of the Blender path but rejected by Godot. The builder now
  preserves the real embedded files and produces valid PNGs; decoded RGB pixels
  compare exactly with the source.
- glTF exported a constant emission strength from a node graph it could not
  represent, lighting the whole fallback material. The fallback now has no
  emission; the explicit Godot shader supplies the masked light.
- Collapse left extra tiny skin groups and blended hoof edges into the chest.
  The final weights are normalized, limited to four and include the actual inner
  hoof edges. Reduced meshes transfer the reviewed skin and retain sole planes.
- Coarse pose sampling dipped hooves during the 0.22-second release. Sampling
  at 100 Hz and importing at 100 Hz preserves the planted solution. The lowered
  source muzzle also needed a bounded head lift to keep solid tusks above ground.
  Whole-mesh floor checks now supplement the hoof-only checks; the rejected
  captures remain under ignored `build/boar-art01/`.
- The initial 35,979-triangle middle candidate lost too much tusk/coat detail.
  It is rejected in favour of 64,983 triangles. Ordinary collapse also stalled
  around 35k for the far mesh; a separately rebaked volume yields the actual 10k
  distant candidate. Neither failed reduction is labelled a successful 10k asset.

## Verification and selected study settings

The original GLB hash is unchanged. Wolf, moth and original editable beast-master
hashes match the preserved baseline. New processes use isolated project/user
directories; no game launch, save operation or gameplay mutation occurs here.
Concurrent Living Frontier changes and their staging are outside this commit.

- Blender reopens the final source with its images packed. Across 68 sampled
  poses, including every 100 Hz release sample, the actual near mesh's soles stay
  planted/in swing as intended. Whole-mesh ground clearance is checked for all
  three delivered detail levels. These are flat-floor checks, not terrain IK.
- Godot reimports all three GLBs. Each has one surface, sixteen bones, valid
  normalized skin influences and six clips with finite sampled bone transforms. Imported
  planted/swing targets, exact clip durations, pause/resume and independent phases
  pass. A separate Python audit reads the actual GLB accessors, image headers,
  material fallback and preserved source files.
- Actual Forward+ captures cover day/shade, emission off/steady/travelling,
  six poses, both flanks, front/rear, status priority and 3.2/8/18 m detail views.
  Two eight-second engine loops use 24 sampled frames/sec and close both the
  gait and pulse cycles. Capture sampling is separate from measured FPS.
- The final package is reopened/reimported separately before publication.
  Python syntax, PowerShell parsing, scoped documentation links and Git whitespace
  are checked. No simulation suite is claimed for this isolated art-only change.

| Study control | Selected value | Purpose |
| --- | --- | --- |
| Review height | 1.2 m at rest | Consistent comparison scale; does not resize a game body |
| Dark scar / core half-width | 16 / 4.5 mm before branch multipliers | Keep narrow light inside visible host damage |
| Maximum physical incision | 4 mm | Preserve a solid-looking shallow fracture |
| Peak / minimum / period | 3.2 / 25% / 4 s | Readable ember core with a smooth passing crest |
| Alternate comparison | 50% minimum, 2.5 s period, steady/breathing | Review intensity and comfort without regenerating art |
| Near / mid / far triangles | 109,972 / 64,983 / 10,000 | Preserve close detail; reduce it only at reviewed distances |
| Near/mid maps / far maps | 2048 / 1024 | Keep source UV detail near; separately rebake distant volume |
| Distant volume step | 14 mm | Close small generated gaps before 10k simplification |
| Idle / walk / root / turn | 4 / 1.6 / 3 / 3 s | Bounded presentation clips, with in-place walking |
| Windup / release | 0.4 / 0.22 s | Baseline generic melee and existing presentation clocks |
| Stance sink / release head lift | 50 mm / 0.45 rad | Settle reachable legs while keeping the low muzzle/tusks clear |

All study settings and their purposes live in `boar-study.json` and
`rig-study.json`. The rig's anatomical coordinates belong to this 1.2 m source;
changing its scale requires reviewing the rig and scar paths together.

## Visual judgement and adoption limits

The narrow orange scars read as a shared material injury and remain embedded in
motion. The 4-second/25% travelling setting is the useful default for owner review.
The no-light comparison keeps the dark scar; shade strengthens the core without
requiring bloom. The owner subsequently said “I love it” and asked to continue
without changing the process. That supplies visual approval; the technical
limitations below and separate ordinary-game adoption boundary remain.

The generated coat still has layered sheets, some gaps and coarse transitions;
some scar edges are too regular at close range. The fitted triangle rig is a
usable study rig, not hand-authored quad topology or finished production animation.
The 10k volume looks softer and has coarse baked relief close up; use its 18 m
comparison, not its hero view, when judging that candidate. The camera distances
are review points, not installed automatic LOD thresholds.

Textures are deliberately lossless in this review, including the 16-bit authoring
scar. The performance report includes the whole review project's texture memory,
embedded fallback textures and framebuffers; it is not per-instance asset memory.
Compression, reduced mask precision, a production texture layout and lower-spec
measurements remain integration work. The measured scene contains a floor and
actors, not the real world, native simulation, streaming or combat.

At this study scale the near bounds are approximately 0.89 m wide and 1.63 m long,
with visible tusk/plate overhang beyond the existing 0.35 m-radius enemy capsule.
No collider, reach or saved geography was changed to hide that difference. Actual
travel, slopes, native status/hit material wiring and collision fit require the
later integration slice. Concurrent LF-3 work adds separate boar behaviours;
these baseline generic-melee preview poses do not implement or validate those
new clocks, attacks or influence variants. Reconcile the published native behaviour
before adoption; never infer combat timing from this decorative pulse.

## Publication and next item

Implementation and verification: **Codex (OpenAI)**. Local implementation commit
`f7250f4` was created and successfully pushed by an ordinary non-force push to
`origin/main`, `https://github.com/Jattymoels/project-wroughtwild.git`.
Its Git author/committer metadata inherited the repository's pre-existing
`Claude <noreply@anthropic.com>` identity; that is not this work's actual authorship.
This note corrects the attribution without rewriting the published commit or
changing the owner's Git configuration.

Only ART-01 tools, settings, documentation and selected review evidence are scoped
for publication. Generated source/runtime working assets stay in the local ignored
handoff, following the roadmap's separate source-promotion boundary. The source
hash identifies a required local input; a fresh clone alone cannot recreate it.

The owner subsequently visually approved this result and selected
[ART-02 — one affected grove](affected-grove-2026-09-09.md). ART-03/04/05 and
ordinary game art adoption remain separate.
