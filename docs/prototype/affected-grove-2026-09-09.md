# ART-02 — one affected grove

**Status: technically delivered; grove visual review pending.** On 9 September the owner visually approved
the ART-01 boar: “I love it, it's almost too high quality !!!” and requested
continuation without changing the process. This selects the next bounded slice
in the [asset roadmap](leyline-asset-roadmap-2026-09-09.md).

Build one approximately 40 m walk through ordinary woodland into a scarred
grove, using six environment roles: quiet tree, related altered tree, exposed
root/bank, fractured rock cluster, deadfall and understory. Reuse the approved
boar. Connect bark, root and rock scars through their material structure;
ordinary plants provide contrast. Red/Ember is scenic continuity with this boar,
not a new source, hazard, reward or assignment of combat behaviour.

Affected systems: isolated Blender authoring and Godot presentation, their
recipes, evidence and local editable handoff. D-013/D-030 provide appearance;
D-010/D-012 preserve authority and eye-height readability; D-017/D-032 preserve
game bodies and saved geography. No game tuning or generation changes.

The earlier woodland trial is below the target: straight trunks, angular
foliage and rounded repeated boulders remain conspicuous. Start one stronger
tree source through the approved image/TRELLIS route, inspect it, finish its
canopy and embedded scars in Blender, and author supporting root/rock forms.
Compose a route with clear approaches before day/shade/dusk and moving review.
Keep the source image, generation settings, original export and exact hashes.

Assumptions: this is a composed review setting, not a generated world or an
interactive extraction site. Preserve current gameplay assets and the owner's
normal save/process. The walk needs honest review collision and grounding;
normal-world streaming, harvesting and combat adoption remain ART-05. Owner
visual acceptance of the grove remains separate from technical checks.

## Delivered setting

The **Emberroot Grove** is a 38.293 m supported route beside a small stream,
through ordinary growth into one Red-scarred clearing containing the ART-01
boar. The kit supplies both tree forms, a bank-facing section of the same root
flare, fractured mineral slabs, deadfall and fern/tuft understory. Fifty-two
tree placements and 834 understory groups compose this isolated setting;
they are not resource records or a new population policy.

The new tree and rock began as original generated references, then passed
through the approved local TRELLIS pipeline. Actual front/back/side Blender
inspection preceded finishing. The first simple procedural root tubes and
rounded layered rock were visibly below the tree/boar standard and were
replaced. Root-bank geometry now comes from the generated tree; the mineral
cluster has its own detailed source. Canopy sprays attach to actual upper
branches rather than floating canopy blobs. The boar source and handoff mesh,
maps and skin are reused without modification.

Scar rays follow inspected host surfaces, with shallow physical incisions and
separate UV masks for narrow cores, dark damage and travel. Source bark relief
is baked into a normal map. The quiet tree binds a zero scar mask; distant
ordinary rock copies keep their unlit PBR material. No bloom or per-scar light
is needed. The same pause-aware clock drives the copied ART-01 shader and the
review's water/boar motion. This is ambient life, not a native work or attack cue.

[Actual engine views, source renders and moving walks](../art/leyline-studies/2026-09-09/grove-art02/README.md)
and [tools, exact prompts and rebuild instructions](../../tools/wroughtwild-grove/README.md)
form the durable record. The local clean handoff is
`build/grove-art02/emberroot-handoff/`: four packed Blender files, a standalone
Godot review, captures/loops and a 105-file manifest. The main editable scene
is `editable/emberroot-grove.blend`. Blender has a steady-light preview;
Godot is authoritative for the exact moving light and review lighting.

## Checks and measurements

- **69 focused artifact/evidence checks pass:** actual GLB indices/coordinates,
  exported UV/colour channels, independent masks, PNG decoding, matched rendered
  comparisons, route result and preserved input/current wolf/moth hashes.
  All ten inspected GLBs have zero triangles below the recorded near-zero-area
  threshold. This does not certify watertight generated topology.
- All four packed Blender files reopen in a fresh background process with valid
  meshes and readable packed images. The composed master contains 25 packed
  images, one boar armature and all six imported actions.
- **153 support/capsule samples and 152 connecting sweeps pass.** The actual
  CharacterBody3D completes the route in 956 physics steps; 953 are grounded,
  with a maximum 0.0352 m support offset including the starting settle. An early
  tree crossed the route; its placement was corrected without ignoring collision.
  Terrain-only support rays are separate from all-obstacle capsule checks.
- A clean copy of the packaged review reimports and repeats the actual traverse
  with its own APPDATA. The delivered manifest is checked separately, without
  importing into the clean package itself.
- Eye-height day/shade/dusk stills and an unlit scar comparison are captured in
  Godot at 1440×900, FOV 72, eye 1.65 m, Forward+, 4× MSAA. The matched light-off
  comparison changes 0.578% of pixels above the recorded threshold, rather than
  brightening the whole host. The dark injury remains visible.
- Each day/dusk walk has 192 deterministic camera frames at 12 samples/second,
  spanning about 15.96 seconds at 2.4 m/s. These are camera samples over the
  physically checked route, not human input or measured playback FPS. WebP/GIF
  derivatives are smaller than the retained original PNG sequences.

| Runtime piece | Triangles | Materials |
| --- | ---: | ---: |
| Quiet / altered tree trunk and roots, each | 84,990 | 1 |
| Detailed / distant canopy | 326,040 / 85,800 | 2 |
| Exposed root/bank section | 8,546 | 1 |
| Fractured mineral cluster | 54,996 | 1 |
| Deadfall | 8,112 | 1 |
| Understory cluster | 15,140 | 2 |
| Retained boar mid detail | 64,983 | 1 |
| Review support terrain | 70,400 | 1 |

The canopy comparison keeps all 780 sprays and their attachment positions.
Only individual distant leaves lose their fine lobes. At 18 m, with a 2 m fade,
this reduces the clearing view's reported submitted primitives, including
shadow passes, from **51.93 million to 35.25 million**. Additional transition
draws raise the measured draw-call count from 156 to 185.

On the RTX 5090, each matched view uses 90 warmup frames and 300 samples with
PNG readback excluded. Day GPU median/p95 improves **3.225/3.550 → 2.474/2.804 ms**;
dusk **3.393/3.588 → 2.501/2.827 ms**. Final whole-frame wall medians are
2.531/2.550 ms. These are isolated grove measurements, not normal-world FPS or
lower-spec evidence. Whole-project reported texture memory is **701,871,104
bytes**, including framebuffers and duplicate embedded fallback textures;
it is not per-tree memory. Lossless authoring maps remain intentionally uncompressed.

One early rendered launch exited without a useful engine diagnostic. The same
project succeeded on retry, and later fresh imports/captures completed. Its
cause remains unconfirmed; the record does not attribute it to geometry or
claim a crash fix. The runner now records its own PID and exit code and stops
only its own failed process on script/shader errors.

## Authoring controls and remaining limits

`grove.json` and `rock.json` explain every exposed control. Selected values:
8 m normalized tree / 1.6 m rock, 780 canopy sprays, 0.22–0.32 m leaf length,
0.38 half-width fraction, 18 m detail distance / 2 m fade, 1,050 understory
candidates before water/path exclusion, 0.4 m support sampling, and the 1.65 m
eye / 2.4 m/s observation walk. Tree scars use 12 mm core half-width, 55 mm
damaged half-width and up to 12 mm incision; rock uses 8/35/10 mm. Shared ambient
light uses a 4-second period, 2.8 peak and 22% minimum. Geometry and deliberate
placements remain authoring data, with no game tuning introduced.

The stronger tree/rock sources and shared scars are a useful advance, but this
is **not final owner approval of the environment**. Repeated tree silhouettes,
geometric understory, close scar-mask stepping and simplified water remain
visible. Root sections have an open back fitted into this bank; they are not
freestanding universally placeable props. Some tree roots are deliberately
buried to fit the reviewed ground. The boar roots in place and has no terrain
IK, navigation, interactions or new combat adapter here. No foliage wind,
harvesting/depletion, saved-world placement, streaming, construction clearance
integration, lower-spec measurement or general tree/understory LOD pass is
claimed. The high geometry/texture cost still needs production integration work.

The original generated tree/rock and boar are preserved. The raw reconstruction
logs report eight tree and six rock uncharted faces with collapsed UVs; the
working reductions repair duplicate faces before export. No claim of pristine
source topology is made. Editable/generated working assets remain local under
ignored `build/`; the repository publishes recipes, original reference inputs,
selected actual evidence and hashes. Raw-source promotion remains separate.

## Publication boundary

Implementation and verification: **Codex (OpenAI)**. Only ART-02 tools, images,
evidence and documents, plus the factual ART-01 visual-approval update, are
included. Concurrent Living Frontier work, normal game assets, saves, finite
resources, progression and running test/playtest processes remain outside this
change. Local commit and ordinary push are reported separately at publication.
ART-03 is next proposed after this grove review; it has not been started here.
