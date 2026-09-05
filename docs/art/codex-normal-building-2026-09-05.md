# Normal building look and octagonal construction

Owner clarification, 5 September 2026. Implemented by Codex (OpenAI).

The workshop study had shown a building treatment that normal construction did
not receive. The owner explicitly requested that look too, including the
octagonal build. This pass adopts both the materials and the required pieces.

Normal timber families now share the workshop's continuous board shader, with
distinct family colours, darker beams/posts/trims and quieter ceiling undersides.
Doors use local coordinates so their boards follow the hinge. Other pieces use
world coordinates so adjoining boards meet across piece boundaries. Stone takes
the study's calmer matte grey. Existing structures refresh through ordinary
save loading, without replacement, material charges or a schema migration.

The catalogue includes Chamfer Block, Triangular Slab, Roof Slope, Roof Hip and
Roof Valley. Their existing `codex_*` identifiers are retained; names shown to
players no longer say experimental. Corner blocks cost 2 and slabs cost 1,
matching their existing counterparts. Roof transitions cost 1, require joinery
and keep the existing `stonecut_blocks` unlock from defeating the Forge Tyrant.
The existing stone wedge remains available under its original material rule.
Materials with exclusive traits (fieldstone/charcoal) keep their restrictions.

Beams have a 0.4 m square section instead of 0.25 m; half beams remain exactly
half-sized at 0.2 m. This exposes the framing beneath a 0.25 m ceiling slab and
removes coplanar flicker. Render and collision use the same dimensions. Existing
saved beams adopt the new cross-section, so their clearance is slightly smaller.
Long interior beams in the inspection house are real saved beam pieces, not
workshop-only dressing. The normal station models and a real campfire light it;
no invisible room light or automatically spawned furnished house was added.

Presentation tuning is in `game/art/building_look.tres` and its documented
script exports: timber #98774e, pine #ab8e5f, bog oak #594332, ash #aaa392,
stone #74747a; `frame_shade` 0.62 darkens structural timber; `roof_colour`
#344d58 distinguishes timber roofs; `board_width` 0.28 m and `seam_width`
0.012 m control board scale/joint visibility; `underside_shade` 0.74 quiets
ceilings. Shape costs/dimensions/unlocks stay in engine-neutral construction data.

Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Buildings`.
The review copies normal tuning unchanged, supplies the existing roof unlock,
then uses normal placement, source materials, collision and save restoration.
It introduces no shape fixture or building material override. Ground and cameras
are inspection context. Historical labs may still override adopted entries in
their copied catalogue to reproduce the old ungated study.

The normal-building review passed 797 checks headless and 800 rendered (the
three extra checks save screenshots). Coverage includes diagonal inner/outer
collision, shelter in the empty corner half, floor/ceiling clipping, all rotated
roof transitions, actual preview placement and cost payment, removal, repairing
a leaking ceiling and normal-schema save restoration. The 4,628 native checks
also passed. Images are under `build/codex-aesthetic/normal-building/`; the
gallery links interior, entrance and exterior views. The full engine regression
suite passed before the commit; its original unit suite retains known dummy
renderer exit diagnostics.

Limits: diagonal and pitched pieces still reserve whole existing elements;
they do not introduce arbitrary-angle placement. The octagonal layout must be
built from these pieces. Corner/slab pieces are immediately available, while
pitched roofs follow the retained unlock. Timber roofs currently share one dark
roof colour across timber families. Framing is placed by the player except for
the existing automatic wall-end/corner trims. No new lamp recipe or roof
structural simulation is introduced.
