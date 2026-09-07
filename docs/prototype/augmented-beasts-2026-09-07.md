# Augmented beasts: Blender creation and game adoption

Owner approval, 7 September 2026: create the four selected concepts in Blender
for use in the game. Wolf maps to wolf/Ash Hound; boar to the existing Ember
Whelp (called Cinder Whelp in the request); stag to Valley Elk; moth to both
existing Wisps. Different coloured meteorite leylines influence ordinary base
animals in different ways; Cinder Wisp is an Ember-influenced moth.

## Scope and assumptions

- Build editable Blender sources, textured skinned GLBs, review renders and
  the bounded adapter needed to use articulated anatomy in the current game.
- Retain existing IDs, native stats, drops, behaviour, attack timing, movement
  bodies, projectile origins, elite multipliers, world profiles and saves.
- Existing Kind data supplies the current family association: Quicksilver for
  Ash Hound, Ember for Whelp and both Wisps, Marrow for Valley Elk. This is an
  appearance interpretation, not a change to the recovered Kind economy.
- The wolf keeps the selected jaw/shoulder growth and silver-blue channels;
  the hound is not granted a Frost attack. Both moths share Ember ancestry but
  keep distinct marsh/cinder habitat colouring. Stag remains passive.
- Capture the broader leyline-colour/animal-augmentation direction in lore.
  Dynamic exposure, spawning by leyline, additional forms, mixed influences,
  purification and save-state changes are future design, not inferred here.
- Concept size numbers inform the models. Visual limbs, tusks, antlers and
  wings are not extra hurtboxes; report discrepancies against existing capsules.

Affected decisions: D-010 combat authority, D-012 first-person readability,
D-013 art direction, D-030 augmentation premise, D-032 preserved worlds.
Source concepts and design cautions: [selected sheets](../art/concepts/creatures/2026-09-07/README.md).
No simulation tuning is changed. Authoring and motion values have plain-language
purposes in the local art data.

## Small implementation sequence

1. Author four animal structures and five family exports, with coherent anatomy,
   independent jaw/limb/wing joints, shared material vocabulary and reference views.
2. Inspect Blender renders and resolve shape/attachment defects before adoption.
3. Extend the existing single-surface skin adapter and combat-driven pose sampler
   only for these data-described rigs. Keep existing actors on their current path.
4. Verify imports, weighted bind poses, articulated motion, exact freeze/stagger
   cancellation, status materials, reconfiguration, elite size and unchanged rules.
5. Inspect actual Godot actors and a representative group, save review artifacts,
   record limitations, then commit and ordinarily push the completed slice.

## Outcome

Implemented: five skinned exports from four animal designs, an editable packed
[Blender master](../../art/blender/README.md), material atlases, transform-only
preview clips, and normal-spawn adoption. The existing adapter now preserves
UV/material data and named joint hierarchies. Skin weights conserve their
16-bit sum; local light multiplies its mask while existing status effects use
the whole surface. Cosmetic limbs/jaw/tail/wings follow existing travel and
combat clocks. A local sole correction anchors a supporting paw/hoof without
moving the gameplay body. The other seven family skins retain their old path.

Verified: 618 relevant headless checks across six suites, 204 rendered beast
checks, independent byte-identical GLB/geometry rebuilds, and reopened packed
master. The [review and evidence](../art/creatures/2026-09-07/README.md) include
counts, bounds, actual rendered poses and the limits of the 60-actor sample.
No new simulation tuning, save fields, world profiles, dependencies or mobs
were introduced. Art-only palette/resolution/motion controls are explained in
`tools/wroughtwild-blender/augmented_beasts.json`; measured dimensions live in
the export manifest rather than masquerading as unused tuning controls.

Limits: simplified first-pass surface/anatomy; no unique fur/scar bakes,
hand-authored LODs or terrain foot IK. Enlarged appendages extend beyond the
retained capsule and are not separately targetable. Leyline/animal combinations
are accepted direction, not dynamic transformation mechanics in this slice.
Owner visual acceptance of the actual Blender/game result remains separate
from approval of the source concepts.
