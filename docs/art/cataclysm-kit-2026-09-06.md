# Cataclysm environment kit — 6 September 2026

This is the bounded authored asset portion of the owner-approved
[cataclysm intensive](../prototype/cataclysm-world-intensive-2026-09-06.md), under
the [accepted world premise](../world-premise.md). Runtime generation, ruin
placement, buildings, actors and Forge integration are reviewed separately.

The kit uses small practical structures in regional materials: a low timber
dwelling on masonry, reed screens and clay waterworks, and shellstone shelters
with slate coverings. Missing courses, cut members and fallen roof sections
provide damage without expanding a ruin into a large dungeon. A directional
buried fragment links them to the same event. Roots wrap one fragment instead
of merely standing beside it.

Augmentation repeats a narrow forked split channel, pale worn metal inset and
short ribbed lamellae. Most of it is inert. Only a small terminal seam has a
0.10 linear emission factor, in pale neutral light; it does not use fire/frost
colours or create a timed danger cue. The same attachment is available for
deliberately contained craft and existing actors. Their status/telegraph
materials and animation authority remain with the runtime adapters.

## Files and placement contract

- Source: `tools/wroughtwild-blender/scripts/build_cataclysm.py`.
- Presentation controls and their purposes: `tools/wroughtwild-blender/cataclysm.json`.
- Reproducible authoring plates: `tools/wroughtwild-blender/scripts/render_cataclysm.py`.
- Curated meshes and exact bounds/hashes: `game/assets/authored/cataclysm_*.glb`
  and `cataclysm_manifest.json`.
- Ignored source blend, export logs and five plates:
  `build/blender-study/cataclysm-2026-09-06/`.

All meshes use Godot metres, applied identity transforms and a ground pivot at
Y=0, with small intentional burial beneath it. +Z is the damage/impact direction
and the visible front of an augmentation attachment. Do not infer gameplay
stock from decorative ruin materials. Exports contain no collision bodies,
resource quantities, animation or light nodes.

| Role | Curated suffix | Placement and reading |
| --- | --- | --- |
| Timber remnants | `rootvault_wall`, `rootvault_frame`, `rootvault_roof` | Pegged framing, separate timber courses, low masonry and a fallen roof section. |
| Managed fen | `fen_wall`, `fen_cistern`, `fen_roof` | Woven reed screens, fired clay courses, a broken three-lobed waterwork and bundled roof members. |
| Upland shelter | `upland_wall`, `upland_shelter`, `upland_paving` | Pale masonry, dark layered caps and modest worn paving. |
| Impact | `impact_fragment`, `root_fragment` | Leaning dark fragment with visible embedded channels; a second version is partly engulfed by connected roots. |
| Shared augmentation | `augmentation_inlay` | Lower-centre pivot; bounds X −0.381…0.363 m, Y 0.010…1.142 m, Z 0.001…0.117 m. |
| Forge threshold | `forge_threshold`, `forge_lamella` | Local dark masonry incorporates the same channels and repeated contained ribs. |

Use the manifest's exact bounds when composing footprints, support samples and
runtime collision. The three open frames conservatively provide a 2 m wide
central aperture: 2.10 m high for the timber frame, 2.02 m for the upland shelter,
and 2.40 m for the Forge threshold. Those openings are tested against actual
imported triangle collision, including positive controls on the solid jambs.
They are not an instruction to give the whole frame one solid box collider.

Keep imported material surfaces to retain original embedded 128 × 128 grain,
linear vertex colour, distinct stone/wood/reed/metal roughness and the quiet seam.
The GLBs carry these original textures internally and require no image download
or new runtime package. Actor adapters may merge the inert geometry into their
existing status material so freeze, hit and hostile telegraphs remain readable.

## Verification and review

The Blender recipe built all 14 exports twice internally and compared geometry,
face ordering, colour and material assignments. It checked finite coordinates
and nondegenerate faces before export. The GLB inspection verified embedded image
data, base-colour texture bindings and vertex colour attributes.

`res://tests/cataclysm_art_review.tscn` passed **455 checks, 0 failures** after
the shared import. It verifies imported mesh availability and exact bounds,
embedded textures and vertex colour, low effective linear emission, no exported
gameplay bodies and 60 open-aperture physics rays plus solid-side controls.
Godot exposes imported emission colours in sRGB; the intensity check converts
back to linear energy rather than comparing unlike colour spaces.

The first integrated world captures exposed uniformly pale ruin surfaces, so
the fixture now compares every surface of all 14 runtime `AuthoredAssets`
meshes with the imported scene's active material. It also checks a fresh runtime
instance, cache reuse and scaled meshes. A synthetic instance override is packed
temporarily into an in-memory scene to exercise the loader's single-mesh fast
path, then restored without writing an asset or import file. That regression
confirms active overrides survive scene disposal without mutating the source
mesh. The current kit imports put materials on the mesh itself; the actual
colour loss occurred earlier in Blender's export. Its default material-graph
inference failed to associate the vertex-colour/texture multiply with `COLOR_0`
and emitted an all-white first colour array. The authoring script now explicitly
exports the named `Color` layer. A binary GLB check compares actual exported RGB
extrema with the authored linear palette for every asset, and the engine fixture
repeats that comparison on imported runtime arrays. This catches white or
incorrect colours rather than merely requiring a nonempty colour attribute.

Godot's current scene-import settings extract copies named
`cataclysm_*_Cataclysm * grain.png` beside the GLBs. Those files and their PNG
import sidecars are generated from the embedded original images and are ignored
by `game/.gitignore`; they are not additional curated source assets. They remain
available locally for the existing importer and are recreated on a fresh import.
The fourteen GLB import settings remain source-controlled configuration.

Five assembled plates were rendered and inspected: Rootvault ruin, fen waterwork,
upland shelter, Forge threshold and shared inlay. That inspection caught an
upper fragment fork partly hidden inside its host. Its vertices now project
onto the actual front triangles, preserving a small surface offset instead of
assuming a flat attachment plane. The root-engulfed variant received curved
connected members rather than long angular segments. Material grain, worn edges
and joinery are present in the actual exported meshes/materials.

The authoring plates prove asset composition and material export, not final
world placement or performance. The kit is intentionally compact and stylised.
Actual daylight/dusk, terrain support, navigation and active-combat readability
must be assessed in the integrated route. It introduces no resource yields,
building recipes, combat effects or progression gates.
