# Leyline art studies — wolf and river woodland

Status: **In progress.** Owner direction, 8 September 2026, after the portable
playtest build. Baseline: `dc64aea`, clean `main`.

Current checkpoint: [baseline inspection and composition trial](../art/leyline-studies/2026-09-08/README.md)
are prepared. The trial remains below the intended art standard and is not
adopted. The bounded [image-to-3D/Blender experiment](../art/leyline-studies/2026-09-08/wolf-image3d/README.md)
is now complete: two generated models, preserved raw 6 Lite export, normalized
editable Blender candidate, corrected shading, actual matched clay views and
31 passed handoff/reopening checks. It supplies a better starting animal, but
weak eyes, a fused mouth, smoothed coat and merged plate details remain below
the brief. Meshy 7 has also been visually compared using the owner's larger
screenshot; its exported geometry is not locally inspected. Neither model is adopted, and
this is not completion of the broader wolf/woodland quality pass.

The owner explicitly approved publication of the raw Meshy GLB as an intentional
art source on 8 September, resolving the initial automatic-review staging
rejection. The [lower-cost alternatives review](../art/leyline-studies/2026-09-08/wolf-image3d/pipeline-options-2026-09-08.md)
records current prices and local hardware feasibility; no alternative service
upload, purchase or installation has been performed.

The owner rejects the mammal models' rounded, awkward appearance while liking
the moth and the selected concepts. They approve developing one convincing wolf
and one small woodland/river scene while ordinary playtesting waits. They
explicitly preserve the connection to the lore: ordinary animals corrupted or
enhanced by impact-borne leyline magic, carrying currents and glowing scars like
the surrounding world.

Further owner direction on 8 September links different meteorite influences to
seeded habitats, distinct mob combat experiences and recovered augmentations.
The [meteorite influence record](meteorite-influences-2026-09-08.md) preserves that
direction and marks candidate colour meanings as proposals. This art study
should establish a reusable host/scar language without assigning new colour
mechanics or expanding into every animal/influence combination.

## Outcome and boundaries

Produce reviewable, editable studies that establish a visual standard before
extending it to the roster or generated world. This is an isolated art study,
not acceptance of a replacement mob, a new generator or a production pipeline.
The first checkpoint is shape and composition. Owner acceptance of that
checkpoint precedes finishing/adopting the wolf; visual judgement is distinct
from successful mesh import and functional tests.

Relevant decisions: D-013 weathered frontier; D-030 augmentation; D-012
first-person viewing; D-010 gameplay authority; D-032 preserved geography.
Read [the visual references](../art/references/README.md),
[selected creature brief](../art/concepts/creatures/2026-09-07/README.md),
[original adoption and limitations](augmented-beasts-2026-09-07.md), and
[existing environment target](environment-target-2026-09-08.md).

- Keep the liked moth and all normal game assets intact during this study.
- Retain selected wolf ancestry, jaw/shoulder lamellae and Quicksilver-associated
  silver-blue channels. A cool appearance does not grant a Frost attack.
- Scars must be embedded in the host surface with dark weathered edges and a
  narrow luminous interior. Their branching and material transitions should
  relate visibly to rock/root leyline fractures. Avoid floating luminous tubes
  as the sole expression of corruption, and avoid covering the whole coat in glow.
- Preserve readable fur, anatomy and species-specific features beneath the
  transformation. Review geometry with emission and textures removed.
- Landscape composition uses a small authored review setting. It does not
  change saved terrain, resource placement, harvest stock, traversal or damage.
- The owner approved an image-to-3D starting-mesh experiment on 8 September.
  Meshy is the first service being tried. Account creation, subscriptions and
  purchases have not been authorized. The owner resolved the upload approval
  required by automatic review: "Signed in - you may upload the wolf image to
  Meshy". Existing free credits funded the two generated candidates.
- Existing gameplay clocks, body shapes, inventory and progression are outside
  this work. Imported animation requires a deliberate future adapter step.

## Work sequence

1. Preserve baseline views and prepare a repeatable neutral wolf inspection.
2. Select a starting-mesh route; compare anatomy against the selected sheet in
   front, side, rear and three-quarter views, including a close head view.
3. Compose a woodland/river study from intentional foreground, middle and
   distance groups, with exposed roots, bank edges, quiet open ground and a
   restrained leyline example. Inspect eye-height views and an overview.
4. Record actual visual shortcomings, asset provenance and authoring controls;
   deliver the shape/composition checkpoint for owner review.
5. After shape acceptance: surface detail, scar treatment, movement, in-engine
   distance/day/shade review, and measured optimisation. Broader adoption remains
   a separate checked step; no collection of import tests certifies art quality.

## Review criteria

Wolf: convincing canine skull and tapered muzzle, fitted eyes with lids/brow,
coherent chest-to-flank transition, readable elbow/stifle/hock and grounded paws;
the ordinary animal reads before the augmentation. Lamellae have plausible roots
and clearance. Inspect mouth opening and limb bends before final surfacing.

Woodland: connected canopy and understory masses, purposeful openings, irregular
bank/root/rock joins and distance layering. The place should be legible in neutral
daylight as well as atmospheric light. Render quality and composition alone do
not establish runtime performance or compatibility with every generated location.

Both: original concept/reference images remain intact. Label reference art,
actual Blender renders and actual Godot captures distinctly. Keep normal saves,
running playtests and existing portable packages untouched. Use unique ignored
output directories for background processes; curate only intentional source and
review artifacts into version control.
