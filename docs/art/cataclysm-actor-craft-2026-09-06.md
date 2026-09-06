# Cataclysm: current creatures and ordinary craft

Implementation under the [approved cataclysm intensive](../prototype/cataclysm-world-intensive-2026-09-06.md)
and D-030, 6 September 2026. This slice connects existing creatures, common
resources and workstations to the land's forked channels and worn pale lamellae.
It introduces no power requirement, extraction process, recipe, enemy or drop rule.

## Runtime integration

The twelve reviewed local Blender mob skins now replace the corresponding
procedural meshes through the normal `Enemy.configure` / `Boss.configure` →
`CreatureMotion.attach` path. Curated source GLBs and a provenance manifest live
in `game/assets/authored/mobs/`. The manifest records the original study path,
hash, family scale, triangle count, pivots, bounds and existing capsule contract.
The source is the [mob study](blender-mobs-study-2026-09-06.md), not an external asset dependency.

`RecoveredActorArt` removes the scale already baked into each reviewed mesh and
maps its skin bindings to the existing canonical part pivots. Ordinary family
scale and later elite enlargement therefore apply once. One cached mesh per
family uses the actor's single existing status material. The imported animation
players and rig are discarded; `CreatureMotion` still reads actual travel,
windup, release, freeze and stagger from the existing actors. No attack timing,
root motion or body shape comes from an imported clip.

Family colours are already present in the mesh. Normal material tint is white
to avoid multiplying them twice; existing hit, freeze and burn feedback still
overrides the complete surface. The boss's separate bright inhale material
remains dominant. Warden and capstone retain their existing shared Tyrant body
and subsequent identity tint.

Small rigidly bound fragments merge into the same creature surface, including
its status feedback. The passive elk stays unadorned as a quieter point of
comparison. This is a visual connection to the existing Kinds/catalysts economy,
not an added promise of a drop from an individual visible fragment.

The broadleaf, boulder and furnishing studies were already used in gameplay
before this slice. Their existing authored meshes are retained. Workbench,
masonry yard, basic forge and improved forge now share small recessed recovered
components, with locally muted metal and seam light. The station lookup serves
both ordinary sites and existing piece rendering. Original wood/stone materials,
interaction boxes and forge hearth light remain in place.

Common broadleaf and field-boulder detail appears only in `frontier_v4` where
the native, row-major augmentation field exceeds the presentation threshold.
Protected ground and older profiles stay plain. The fragment is a child of the
resource's existing mesh, so its normal harvesting lean, shrinking and fall also
move the fragment. It has no separate body, target, light or resource stock.

## Presentation tuning

All added scalar and colour controls are in `game/art/augmentation_look.tres`
and its Resource script, with plain-language purposes. Mount poses in
`AugmentationDetail` are fitted art coordinates for the shared one-metre asset.

| Control | Default | Purpose |
| --- | --- | --- |
| Common influence threshold | 0.32 | Keep ordinary resources plain outside meaningful native exposure. |
| Creature fragment scale | 0.34 | Suggest an embedded component while retaining existing silhouettes. |
| Common-resource fragment scale | 0.48 | Expose part of a fragment through its host. |
| Creature pale/recess colours | `b8b6a3` / `626b64` | Use worn inert material distinct from danger colours. |
| Actor roughness | 0.93 | Keep dry skin, cloth and plates from looking glossy. The boss retains its existing final material setup. |
| Craft inlay tint | `8e9788` | Keep the component within the workshop material palette. |
| Craft inlay roughness | 0.82 | Subdue highlights beside the forge hearth. |
| Craft seam emission multiplier | 0.25 | Retain a quarter of the imported faint seam light without implying a power meter. |

## Verification and review

Whole-game import succeeded. The dedicated real-scene fixture
`game/tests/cataclysm_actor_craft.tscn` passed **200 checks headless** and
**207 checks rendered**, with no failures or stderr. It verifies all twelve
normal spawn paths, exact reviewed world-metre source envelopes, rest/bind pose,
single live sampler and release listener, unchanged capsules and actor rule
state, family/elite scaling, white normal tint and complete status reset on
regular actors and boss. Real station build/upgrade transactions and resource
visual/harvest paths are exercised against isolated state.

Existing checks also pass: CreatureMotion **100/0**, Presentation **29/0** and
CombatPresentation **65/0**. Final local logs are
`build/cataclysm-actor-final-check.*.log` and
`build/cataclysm-actor-final-render.*.log`.

Rendered captures use actual game actors and stations on a fixed review floor:
`build/cataclysm/actor-craft/actors.png`, `workstations.png`, four actor close-ups
and `boss-tell.png`. The manifest records the distinction from normal-world
journey and performance review. The workshop inlay was subdued after the first
capture because its original pale surface read too much like white signage.

These remain faceted prototype models. The study's visible body discrepancies
are preserved: crawler legs and antlers can extend beyond the existing capsule,
wisps occupy only part of it, and elite visual growth does not enlarge collision.
No claim of improved combat balance or production-quality anatomy is made.
Normal-world integration/performance evidence belongs to the intensive's shared
route review; this isolated fixture is not a performance benchmark.
