# Augmented beasts: editable sources

Owner review, 8 September: the moth is liked; the mammals' visual quality is
rejected relative to the selected concepts. The
[new bounded studies](../../docs/prototype/leyline-art-studies-2026-09-08.md)
retain these assets as baselines while establishing a better wolf and woodland
standard. Current game files remain the earlier playable pass.

Open [augmented-beasts-v01.blend](augmented-beasts-v01.blend) in Blender 4.5.
This is the first playable interpretation of the owner's selected creature
concepts. The game uses the five corresponding GLBs in
[`game/assets/authored/mobs`](../../game/assets/authored/mobs), through normal
enemy spawning. No Blender installation is needed to run the game.

| Game family | Base animal | Current influence association |
| --- | --- | --- |
| Ash Hound | Wolf | Quicksilver; silver-blue jaw/shoulder channels |
| Ember Whelp (the requested Cinder Whelp) | Wild boar | Ember catalyst; grown heat shield and tusks |
| Valley Elk | Stag | Existing Marrow association; enlarged living crown |
| Marsh Wisp | Moth | Existing Ember association; olive wing membranes |
| Cinder Wisp | Moth | Ember catalyst; soot/copper wings and orange reservoir |

The owner explicitly supplied the animal mappings and Cinder/Ember example.
The other Kind associations follow current game data. Broader leyline variants
are a design direction, not a new exposure or spawn system in this slice.

## Editing

The opening gallery contains static review copies linked to the source mesh
data. The hidden `SOURCE - isolate one animal to edit` collection holds five
meshes and their armatures at the origin. Enable that collection and isolate
one mesh/armature pair; hide gallery copies while editing. Gallery objects,
floor, lights and camera are not game exports. Metres map directly to Godot;
Blender `(x, y, z)` maps to Godot `(x, z, -y)`. Animals face Blender +Y / Godot -Z.

Each mammal has a continuous blended skin, independent jaw/tail and four
upper/lower/foot chains. Moths have four wing roots, six two-part legs, head,
abdomen and antenna joints. Packed albedo, roughness and masked emission
atlases use one material per family. Tiles distinguish coat, growth, energy,
horn, eyes and hoof/nose; the shared tile UVs support material editing but
are not a unique paint unwrap for individual scars.

The muted NLA tracks contain transform-only idle/walk and hostile windup/release
previews. Unmute one track to preview it; the grazer has no attack clips.
The game reads movement and existing combat events through `CreatureMotion`.
It builds the matching skeleton from the manifest and does not run a second
AnimationPlayer clock. A local sole correction keeps a supporting foot on the
authored plane; uneven-ground foot IK remains future polish.

## Rebuilding

From the repository root, using the already installed portable Blender:

```powershell
& './build/blender-tool/blender-4.5.9-windows-x64/blender.exe' --background --python tools/wroughtwild-blender/scripts/build_augmented_beasts.py -- $PWD.Path "$PWD/build/augmented-beasts/rebuild"
```

This writes a new review folder, never overwrites the adopted game assets or
this master automatically. Geometry is authored in the script;
[`augmented_beasts.json`](../../tools/wroughtwild-blender/augmented_beasts.json)
documents palette, resolution and motion controls. Blender edits to the
master are durable art work but are not reverse-translated into the generator.
Preserve them before regenerating. After an intentional revision, re-export
the selected mesh/armature, update the rig/bounds/hash entry in the game
manifest, and run the adoption checks before replacing checked assets.

## Review and limits

[Godot and Blender review](../../docs/art/creatures/2026-09-07/README.md) contains
actual rendered geometry. The source illustration sheets remain separately
stored under `docs/art/concepts` and remain the richer finish target.

These models are usable game assets with first-pass anatomy, surface detail
and animation. They do not yet reproduce the illustrations' sculpted fur,
weathering and naturalistic faces. There are no hand-authored LODs, unique
scar/fur bakes, terrain-aware foot placement or appendage hurtboxes. The
existing capsule is deliberately retained; antlers, tails, tusks and wing tips
can extend beyond it. Those presentation limits are documented rather than
silently changing combat reach or collision.

## INT-02B environment target, 8 September 2026

Three additional editable masters contain the actual curated environment meshes:

- `environment-target-nature-v01.blend`: broadleaf, its 1,436-triangle distant
  silhouette, field boulder, shrub and fern; retained deadfall/stump sources.
- `environment-target-ruins-v01.blend`: the existing fourteen ruin recipes.
  Only the nine fen/rootvault/upland surfaces were adopted in this slice.
- `environment-target-ventlung-v01.blend`: the existing membrane with curved
  pleats, inside its previous envelope. Its runtime case and light remain separate.

Source meshes sit at the origin in Godot metres (Blender X,Y,Z = Godot X,-Z,Y).
The ruin, membrane and distant-LOD meshes are hidden after export; unhide the
named object to edit it. These are authoring masters, not a new generated level.
The complete place is assembled and reviewed in the normal Godot world.

Rebuild with the installed local Blender, using unique ignored output folders:

```text
blender --background --python-exit-code 1 --python tools/wroughtwild-blender/scripts/build_nature.py -- REPOSITORY OUTPUT/nature --assets-only
blender --background --python-exit-code 1 --python tools/wroughtwild-blender/scripts/build_cataclysm.py -- REPOSITORY OUTPUT/ruins
blender --background --python-exit-code 1 --python tools/wroughtwild-blender/scripts/build_strange.py -- REPOSITORY OUTPUT/ventlung --only=ventlung
```

The adjacent `nature.json`, `cataclysm.json` and `strange.json` recipes explain
every changed number. Preserve deliberate Blender edits before regeneration;
they are not reverse-translated into recipes. Curate only reviewed exports into
`game/assets/authored`, update their hashes, then run
`python tools/check_environment_target.py` and the isolated Godot review.
The retained ruin triangle contracts must not be regenerated from changed walls:
their exact geometry also defines existing runtime collision.

[Implementation and matched field evidence](../../docs/prototype/environment-target-2026-09-08.md)
records the visual target, source limits, save checks and performance.
