# Wroughtwild — complete environment and placeable design catalogue

Generated from current game data plus the authored briefs in `tools/wroughtwild-world-design/catalogue.py`.
This is an art backlog, not evidence of model completion or a change to recipes, spawns or saved geography.

Coverage: **26 shapes, 19 material families, 273 legal material/shape pairs, 14 craftable kits and one in-place forge upgrade**. Ordinary profiles expose 10 kits; the four coloured kits require a supported Living Frontier profile.
Nature: **22 existing resource node types and 33 supporting art roles**. Wildlife briefs retain all 16 existing overworld actor/host IDs, using approved ancestries.

The boards illustrate families. The tables cover every item, including small pieces not separately pictured. Incidental furniture in a scene does not add a recipe.

## Material families

| ID / collected item | Traits / restriction | Proposed material construction |
| --- | --- | --- |
| `wood` / `wood` | timber, joinery, fuel, covering | Warm sawn planks with broad end grain, pegs and irregular tool marks; retain straight mating edges. |
| `pine` / `pine` | timber, joinery, fuel, covering | Pale long straight grain and small dark knots; lighter rough cut edges than ordinary timber. |
| `bog_oak` / `bog_oak` | timber, joinery, fuel, covering | Dense nearly black brown wood, water-dark pores and burnished worn corners; grain remains visible in shade. |
| `ash_wood` / `ash_wood` | timber, joinery, fuel, covering | Bone-pale fibrous grain and weathered silver edges; a timber surface, not bone or snow. |
| `stone` / `stone` | masonry, heavy | Dressed grey courses with restrained chips and visible bedding; regular joints distinguish worked masonry from fieldstone. |
| `iron` / `iron_ingot` | metal, joinery, covering | Dark hammered iron, broad rivet heads and oxide in protected seams; muted metal, no generic orange glow. |
| `bronze` / `bronze_ingot` | metal, malleable, tough, joinery, covering | Warm cast/hammered bronze with dark green patina in recesses; curved arch remains recognisably worked metal. |
| `steel` / `steel_ingot` | metal, hard, resilient, joinery, covering | Cooler tightly finished plates, darker weld/fastener lines and sharper worn edges than iron. |
| `silver` / `silver_ingot` | metal, warding, malleable | Pale soft metal with dark tarnished recesses; curved and structural forms only where the existing traits permit them. |
| `charcoal` / `charcoal` | fuel, hot; only shapes requiring fuel | Angular porous black fuel chunks and subtle ash; only the fuel form, never charcoal walls. |
| `fieldstone` / `fieldstone` | rough, heavy; only shapes requiring rough | Rough varied stones with dry contact joints and lichen remnants; low footing/dry wall only. |
| `slate` / `slate` | masonry, heavy, covering | Thin dark cleaved layers, offset joints and chipped edge laminations; roofs read in the silhouette at distance. |
| `shellstone` / `shellstone` | masonry, heavy, covering | Warm pale cut stone carrying uneven fossil fragments and occasional whole shell impressions; fossils must not tile identically. |
| `rustclay_brick` / `rustclay_brick` | masonry, heavy, covering | Warm red-brown fired courses, varied firing marks and restrained pale joints; repeat spacing fits module boundaries. |
| `woven_reed` / `woven_reed` | covering; only shapes requiring covering | Over-under reed weave, bundled cut edges and integral lash-bound frame; opaque functional wall coverage despite visible weave. |
| `resinheart` / `resinheart` | timber, joinery, covering | Strong amber-brown grain, dense cut end rings and occasional non-emissive resin pockets; retain the collected tree's identity. |
| `corkbark` / `corkbark` | covering; only shapes requiring covering | Thick porous bark faces, layered cut edge and inset frame; use coarse pores rather than noisy universal bump. |
| `vitrified_basalt` / `vitrified_basalt` | masonry, heavy, covering | Dark fused rock with broken glossy skin over a matte heavy body; heat-worked material, not an always-burning wall. |
| `cinderglass` / `cinderglass` | glazing; only shapes requiring glazing | Smoky mineral glass with modest distortion and an integral fitted frame; opaque-enough edge/selection readability and existing projectile blocking. |

## Every building shape

Direct Blender modules, using the existing face/edge/block pivots and dimensions. Preserve coarse/fine alignment, grain scale, every allowed rotation and both sides of exposed pieces. Placement preview and installed geometry must share the same source.

| ID / size in metres | Visual brief | Legal material families / gate |
| --- | --- | --- |
| `codex_corner` / 1 × 1 × 1 | A clipped diagonal block with continuous side grain/courses and a clean diagonal mating face. | wood, pine, bog_oak, ash_wood, stone, iron, bronze, steel, silver, slate, shellstone, rustclay_brick, resinheart, vitrified_basalt |
| `codex_corner_floor` / 1 × 0.25 × 1 | Thin triangular slab matching the clipped block; finish the cut edge, preserve exact thickness. | wood, pine, bog_oak, ash_wood, stone, iron, bronze, steel, silver, slate, shellstone, rustclay_brick, resinheart, vitrified_basalt |
| `codex_roof_slope` / 1 × 0.5 × 1 | One half-height pitched module; layer covering toward the low edge and keep shared roof seams exact. | wood, pine, bog_oak, ash_wood, iron, bronze, steel, slate, shellstone, rustclay_brick, woven_reed, resinheart, corkbark, vitrified_basalt; world unlock `stonecut_blocks` |
| `codex_roof_hip` / 1 × 0.5 × 1 | Convex outer roof transition with continuous ridge/corner covering; preserve the same cell envelope. | wood, pine, bog_oak, ash_wood, iron, bronze, steel, slate, shellstone, rustclay_brick, woven_reed, resinheart, corkbark, vitrified_basalt; world unlock `stonecut_blocks` |
| `codex_roof_valley` / 1 × 0.5 × 1 | Concave roof transition with a readable drainage valley; no decorative lip blocking the joining module. | wood, pine, bog_oak, ash_wood, iron, bronze, steel, slate, shellstone, rustclay_brick, woven_reed, resinheart, corkbark, vitrified_basalt; world unlock `stonecut_blocks` |
| `cube` / 1.0 × 1.0 × 1.0 | Solid regular module; timber assembly, masonry courses or metal panels express family without changing occupancy. | wood, pine, bog_oak, ash_wood, stone, iron, bronze, steel, silver, slate, shellstone, rustclay_brick, resinheart, vitrified_basalt |
| `wall_panel` / 1.0 × 1.0 × 0.25 | Thin vertical partition with integral believable edges; courses and grain continue at neighbouring faces. | wood, pine, bog_oak, ash_wood, stone, iron, bronze, steel, silver, slate, shellstone, rustclay_brick, resinheart, vitrified_basalt |
| `pillar` / 0.3 × 1.0 × 0.3 | Narrow vertical support with end joints contained in its exact width; optional details must fit real corner geometry. | wood, pine, bog_oak, ash_wood, stone, iron, bronze, steel, silver, slate, shellstone, rustclay_brick, resinheart, vitrified_basalt |
| `beam` / 1.0 × 0.4 × 0.4 | Horizontal support with readable underside and end grain/metal caps; preserve the existing exposed beam section. | wood, pine, bog_oak, ash_wood, stone, iron, bronze, steel, silver, slate, shellstone, rustclay_brick, resinheart, vitrified_basalt |
| `floor_slab` / 1.0 × 0.25 × 1.0 | Flat floor/ceiling module with legible rim; same finish on exposed underside, no floating trim. | wood, pine, bog_oak, ash_wood, stone, iron, bronze, steel, silver, slate, shellstone, rustclay_brick, resinheart, vitrified_basalt |
| `stairs` / 1.0 × 1.0 × 1.0 | Two substantial steps inside one cell; match native stair silhouette, not a new many-tread staircase. | wood, pine, bog_oak, ash_wood, stone, iron, bronze, steel, silver, slate, shellstone, rustclay_brick, resinheart, vitrified_basalt |
| `door` / 1.0 × 2.0 × 0.25 | Single hinged leaf with frame/hinge detail inside the existing wall form; mirrored hinge orientation and actual open/closed state. | wood, pine, bog_oak, ash_wood, iron, bronze, steel, resinheart |
| `roof_wedge` / 1.0 × 1.0 × 1.0 | Full-height 45-degree cut masonry wedge; distinguish this older stone form from half-height covering roofs. | stone, slate, shellstone, rustclay_brick, vitrified_basalt; world unlock `stonecut_blocks` |
| `girder` / 2.0 × 0.4 × 0.3 | Two-cell metal beam with a visibly reinforced section; no new cable support or structural rule. | iron, bronze, steel, silver |
| `arch` / 1.0 × 1.0 × 0.25 | Worked malleable metal head with half-round underside; clear metal finish prevents confusion with a new masonry arch. | bronze, silver |
| `half_cube` / 0.5 × 0.5 × 0.5 | Half-grid solid for trim or a step; retain material grain scale, avoid an oversized full-block texture squeezed onto it. | wood, pine, bog_oak, ash_wood, stone, iron, bronze, steel, silver, slate, shellstone, rustclay_brick, resinheart, vitrified_basalt |
| `half_wall` / 0.5 × 0.5 × 0.125 | Small face panel for sill/parapet infill; same edge seam contract as its coarse parent. | wood, pine, bog_oak, ash_wood, stone, iron, bronze, steel, silver, slate, shellstone, rustclay_brick, resinheart, vitrified_basalt |
| `half_pillar` / 0.15 × 0.5 × 0.15 | Slender half-grid post for legs/pickets; no attached decorative finial beyond the body. | wood, pine, bog_oak, ash_wood, stone, iron, bronze, steel, silver, slate, shellstone, rustclay_brick, resinheart, vitrified_basalt |
| `half_beam` / 0.5 × 0.2 × 0.2 | Small rail or sill; matching end grain and joints at the half-cell positions. | wood, pine, bog_oak, ash_wood, stone, iron, bronze, steel, silver, slate, shellstone, rustclay_brick, resinheart, vitrified_basalt |
| `half_slab` / 0.5 × 0.125 × 0.5 | Small shelf/step/roof edge with a finished underside; preserve fine lattice placement. | wood, pine, bog_oak, ash_wood, stone, iron, bronze, steel, silver, slate, shellstone, rustclay_brick, resinheart, vitrified_basalt |
| `chest` / 1.0 × 0.7 × 0.8 | Low jointed storage box; inherited material family, supported hinges and clear lid opening; contents stay in native storage. | wood, pine, bog_oak, ash_wood, iron, bronze, steel, resinheart |
| `campfire` / 1.0 × 0.5 × 1.0 | Low fuel pile with timber or charcoal-specific shape; burning/ash transition reads native fuel lifetime and heat. | wood, pine, bog_oak, ash_wood, charcoal |
| `foundation` / 1.0 × 0.5 × 1.0 | Half-height dry-laid rough-stone footing with broad load-bearing base; no full masonry cube implied. | fieldstone |
| `dry_wall` / 1.0 × 0.5 × 0.3 | Low rough-stone course on a wall face; uneven cap inside dimensions, no new shelter or collision interpretation. | fieldstone |
| `light_panel` / 1 × 1 × 0.16 | Framed thin covering wall; family-specific weave/bark/planks/sheets with a complete blocking surface. | wood, pine, bog_oak, ash_wood, iron, bronze, steel, slate, shellstone, rustclay_brick, woven_reed, resinheart, corkbark, vitrified_basalt |
| `glazed_window` / 1 × 1 × 0.16 | Fixed smoky pane and complete integral frame as one piece; no openable window or extra frame recipe. | cinderglass |

These pairings are computed from the native material-trait contract, including `only_for_trait`. Examples: fieldstone is footing/dry wall only, charcoal is fuel only, cinderglass is the integral fixed window, and the arch requires a malleable material. Material eligibility does not bypass a world unlock. Existing recipe and shape costs are retained in the JSON inventory.

## Every station and fixture

Bounds below are current engine bodies, not an artistic resizing suggestion. Feet/pivot and rotating/extending parts need actual placement and movement checks before adoption. Station kits use a 0.96 × 2 × 0.96 m body, including reserved air above low tables. Profile filters remain authoritative. A forge upgrade has no separate kit.

| ID / kit / bounds in metres | Design / production route | Actual-state review poses |
| --- | --- | --- |
| `workbench` / `workbench_kit` / 0.96 × 2.0 × 0.96 | Pegged compact timber bench, thick scarred top and contained clamp. Distinct horizontal wood working surface. Direct Blender frame and fitted tools. | idle; existing craft feedback |
| `forge_basic` / `forge_kit` / 0.96 × 2.0 × 0.96 | Low stone hearth and supported short cowl, iron working face, dark cold basin that lights only with real work feedback. Direct Blender hearth/frame; reusable stone/iron surfaces. | idle; existing fuel/work feedback |
| `forge_improved` / `upgrade in place` / 0.96 × 2.0 × 0.96 | Same forge plinth and footprint with stronger iron collar, better contained hot chamber and visibly refined working plate. Variant of basic forge; no separate kit. | existing global upgrade appearance; idle/work |
| `mason_yard` / `mason_yard_kit` / 0.96 × 2.0 × 0.96 | Squat timber support around a fieldstone dressing bed, attached wedges/chisel rests, cutting dust inside the footprint. Direct Blender support and contained dressed stone. | idle; existing stone work feedback |
| `lantern_lamp` / `lantern_lamp_kit` / 0.55 × 1.06 × 0.45 | Warm Lanternheart core in papery husk within a small timber/reed cage; protect the recognisable recovered heart. Organic core source plus precisely fitted frame. | native on/off; dismantled core |
| `cargo_winch` / `cargo_winch_kit` / 1.4 × 1.83 × 1.15 | Root tension drum on stout timber supports, hand crank, one basket and a distinct cable attachment. Direct mechanism; controlled organic root coil, separate moving drum/basket. | unwound/wound; loaded; travelling/blocked/arrived |
| `winch_landing` / `winch_landing_kit` / 1.4 × 1.83 × 1.15 | Plain matching receiving cradle and rope guide; support feet and basket clearance, no second rare core. Direct Blender; share winch timber/iron and attachment grammar. | connected; arriving/received cargo |
| `stormglass_lever` / `stormglass_lever_kit` / 0.65 × 0.95 × 0.5 | Ringing lightning-glass tube in clamps, readable tapping hand lever and outgoing request socket. Organic tube plus direct frame/lever with physical pivot. | idle; actual pulse; unavailable request |
| `magnetic_sorter` / `magnetic_sorter_kit` / 1.3 × 1.3 × 0.85 | Inclined hand-fed chute, braced dark Pullstone nodule and two unmistakable receiving trays. Direct Blender chute/trays; organic magnetic nodule. | empty/loaded; native sorting; separate tray contents |
| `ventlung_bellows` / `ventlung_bellows_kit` / 0.92 × 0.97 × 1.15 | Folded natural membrane between boards, fibre lashings, priming handle and short directed nozzle. Organic membrane with deformation-friendly topology; direct boards/nozzle. | unprimed/primed; actual discharge |
| `pressure_feeder` / `pressure_feeder_kit` / 1.5 × 1.45 × 1.45 | Compact frame with separate clay hopper, fuel cup, root drum, pressure chamber and brick tray; distinct pressure and forge attachments. Direct assembled mechanisms; separate supply meshes driven by native readout. | idle; loaded; reserved/running; paused/blocked; output |
| `white_connection` / `white_connection_kit` / 0.65 × 1.18 × 0.55 | Reuse approved White post, fracture material and fitted frame; immediate request path stays visually distinct from receiver winding. Reuse tools/wroughtwild-white and its accepted handoff. | native request/connection; no stored winding |
| `blue_delay` / `blue_delay_kit` / 0.65 × 1.18 × 0.55 | Reuse approved supported flake/delay form; visible held request with a legible local pause/release cue. Reuse tools/wroughtwild-blue and its accepted handoff. | empty; holding; paused; released/cancelled |
| `green_junction` / `green_junction_kit` / 0.65 × 1.18 × 0.55 | Reuse approved resin-root fork with two distinct branch sockets; branch result must not imply free work. Reuse tools/wroughtwild-green and its accepted handoff. | native branch outcomes; disconnected |
| `red_heat_buffer` / `red_heat_buffer_kit` / 1.0 × 1.2 × 1.0 | Reuse approved braced heat store, clear charge chamber and existing feeder attachment. Frame material is separate from spent charge. Reuse tools/wroughtwild-workshop and its accepted handoff. | empty/charged; supplying; native reservation/removal restriction |

Every kit additionally needs a readable pack/palette thumbnail, grounded placement preview, occupied outline, local interaction focus and faithful dismantle/reload presentation. A failed placement retains its kit; success creates exactly one usable fixture. Native counts and work progress drive contents and motion; idle decoration must not invent stock, energy or items.

## Existing finite resource art

Every current worldgen resource type has its own brief. Art variants do not add resource identities or duplicate yields. Original positions, collision/work targets, stock and saved partial progress remain. Model depletion rather than hiding missing stock behind an intact glowing source.

| Node / recovered item | Habitat art context | Host → worked appearance |
| --- | --- | --- |
| `tree` / `wood` | meadow/forest | Reuse ART-02 broadleaf trunk language; branching silhouette, leaf masses, exposed roots and matching cut stump; ordinary and locally altered finish. |
| `pine` / `pine` | forest/uplands | Tapered conifer with uneven branch tiers, attached needle clusters and visible trunk gaps; pale cut timber matches the pine building family. |
| `bog_oak` / `bog_oak` | fen | Leaning dark oak, flared knuckled waterline roots, sparse lower branches and dense irregular upper crown; dark cut wood. |
| `ash_snag` / `ash_wood` | ember_wastes | Bleached twisted dead trunk with broken boughs, limited char in splits and readable standing/felled silhouette; not a forest of identical spikes. |
| `resinheart_tree` / `resinheart_log` | oldgrowth_grove | Thick buttressed amber-grain oldgrowth with hanging crown masses and deep structural root channels on altered variant; preserve approved grove ancestry. |
| `corkbark_deadfall` / `raw_corkbark` | oldgrowth_grove | Low independent dead trunk with thick porous rolled bark lips; show exposed lighter underlayer as its own finite deposit is worked. |
| `boulder` / `fieldstone` | all | Reuse approved fractured rock as one family; rounded weathering vs hard broken faces, separate removable chunks and final worked remnant. |
| `stone_seam` / `split_stone` | rock/caves | Bedrock face with broad bedding planes and wedge-readable split; integrate visually with surrounding rock while retaining one work target. |
| `iron_vein` / `iron_ore` | rock/caves | Ochre iron streaks and dense dull nodules inside broken host rock, not uniform shiny crystal spikes. |
| `copper_vein` / `copper_ore` | era_2_ore_sites | Weathered green-brown copper-bearing bands in warm host rock; exposed worked interior remains recognisable without blue magic association. |
| `tin_vein` / `tin_ore` | era_2_ore_sites | Pale granular mineral pockets in dark banded rock; distinct from iron and silver at interaction distance. |
| `ember_iron_vein` / `ember_iron_ore` | era_3_ore_sites | Heat-marked dark ore with restrained ember-bearing internal fractures; hot/worked states follow existing rules. |
| `silver_vein` / `silver_ore` | era_3_ore_sites | Narrow pale metallic seam through dark host rock; broad material contrast survives reduced texture detail. |
| `slate_outcrop` / `raw_slate` | quarry_escarpment | Thin stacked dark sheets with exposed split edge and a readable detachable working face; matching slate roof layers. |
| `shellstone_outcrop` / `raw_shellstone` | quarry_escarpment | Pale fossil-bearing bed with scattered shell cross-sections and broad cleaving planes; irregular fossils, not repeated giant medallions. |
| `clay_bank` / `raw_clay` | fen_hollow | Damp rust-coloured earth pocket in a rooted bank with scooped working layers; depleted pocket stays distinct from decorative mud. |
| `reed_bed` / `raw_reed` | fen_hollow | Harvestable mature upright reed bundle with clear cuttable stalk mass; separate low decorative sedge from this work target. |
| `lanternheart` / `lanternheart` | rare_sites | Papery lantern husk sheltering a luminous intact heart; harvest reveals/lifts that same core and leaves an empty husk. |
| `thrumroot` / `thrumroot` | rare_sites | Bowed deadfall held by taut sinewy roots; exposed reusable coil has the same weave/strain as the winch drum. |
| `stormglass` / `stormglass` | rare_sites | Naturally fused lightning tube partly embedded in scarred ground; ringing hollow form becomes the lever's resonator. |
| `pullstone` / `pullstone` | rare_sites | Dark nodule attracting clinging ferrous grit; working separates one intact visibly dense core from its braced host. |
| `ventlung` / `ventlung` | rare_sites | Bulged natural membrane in a split host, seam and pressure-release opening visible; lifted membrane becomes the hand bellows. |

## Supporting nature and world feel

These IDs belong to this art catalogue only. Habitat labels are composition briefs, not new biome definitions or spawn assignments. Decorative reeds, wood and rocks must not misrepresent finite work targets. Existing pressure and coloured sources retain their separate native ledgers.

| Art role | Context | Proposed form / reuse |
| --- | --- | --- |
| `canopy_broadleaf` (foliage) | meadow/forest | Several linked leaf-mass arrangements on real branches; near leaf detail, simpler middle crowns and matched distant silhouette. |
| `canopy_conifer` (foliage) | forest/uplands | Needle-cluster branches with a sparse lower tier and irregular upper spire; separate wind weighting and distant solid read. |
| `sapling_shrub` (foliage) | meadow/forest | Young bent stems and low bush clusters connect grass to tree scale; leave trunk access and routes open. |
| `fern_bracken` (groundcover) | forest/river | Broad asymmetric frond groups with sparse and lush variants; reuse approved ART-02 understory where suitable. |
| `meadow_grass` (groundcover) | meadow | Mixed-height clumps and flattened edge variant, quiet olive/straw colour shifts; distribute in authored patches. |
| `upland_tussock` (groundcover) | uplands | Dense low wind-combed clump with a dry rim and green centre; fills pockets between rock without hiding ledges. |
| `fen_sedge` (groundcover) | fen | Short rooted wet sedge hummocks, distinct from the finite harvestable reed_bed. |
| `wastes_scrub` (groundcover) | ember_wastes | Thorny low scrub and coarse surviving grass, weathered seed heads, broken rhythm across grit rather than bare ash everywhere. |
| `bramble_climber` (groundcover) | forest/ruins | Restrained thorn stems, leaf sprays and climbing ivy rooted to actual support; keep openings readable. |
| `fungal_detritus` (groundcover) | oldgrowth/fen | Non-glowing shelf fungi, small mushrooms and damp wood debris as cosmetic habitat detail, no new harvest promise. |
| `moss_lichen` (surface) | rock/forest/fen | Damp moss cushions and dry pale lichen masks with different edge shapes; no universal carpet on every material. |
| `leaf_needle_litter` (surface) | forest/meadow | Branch-correlated litter, dark humus and exposed soil transition; tiling maps plus a few silhouette-breaking chips. |
| `root_skirt` (geology_contact) | forest/fen | Attached flared roots crossing soil and rock; modular contact pieces derived from parent tree, no floating ends. |
| `deadwood_stump` (geology_contact) | forest/meadow | Broken log, stump and low branch variants; ordinary decorative pieces cannot mimic fresh resource yields. |
| `river_bank` (geology_contact) | river/fen | Irregular damp ledge, root shelf and reed-edge transitions, matching actual bank support and access. |
| `talus_pebbles` (geology_contact) | uplands/river | Grouped angular scree plus rounded water pebbles; clustered with exposed ground between, not a collider on every stone. |
| `rock_shelf` (geology_contact) | uplands | Layered ledge transition and small outcrop variants; silhouette and material variation fit retained terrain. |
| `cave_threshold` (geology_contact) | caves | Broken overhang/root lip and damp wall transitions framing existing cave opening; clear human entrance and host approach. |
| `leyline_scar` (augmentation) | existing_influence_routes | Deep host-specific recessed channel with dark margins and contained moving light; ordinary/recessed-unlit/lit review states. |
| `red_source` (retained_source) | existing_LF_red | Reuse ART-04 Red host, owned fragments, recovered salt and charge language; native lot/formation states only. |
| `white_source` (retained_source) | existing_LF_white | Reuse ART-04B White fractured host and recovered mineral; request transmission is not stored drive. |
| `blue_source` (retained_source) | existing_LF_blue | Reuse ART-04C layered host and recovered flakes; retain native formation and held-request distinction. |
| `green_source` (retained_source) | existing_LF_green | Reuse ART-04D root host and resin pieces; growth supports branching anatomy, not free item propagation. |
| `pressure_pocket` (existing_source) | existing_pressure_sites | Braced split host with readable finite pressure reservoir and attachment; intact/worked/exhausted native stock, no spontaneous refill. |
| `ruin_wall` (ruin) | existing_ruins | Weathered low masonry wall, broken corner and small rubble cap, root contact; no relocation or new wall collision. |
| `ruin_threshold` (ruin) | existing_ruins | Fallen lintel, worn stair and fractured paving expose former human routes; keep existing entrance clear. |
| `workshop_approach` (ruin) | existing_workplaces | Reuse original smithy language and LF marks/clamps; distinguish old ordinary craft from deliberate later containment. |
| `trail_transition` (surface) | existing_routes | Exposed compacted soil, leaf-thin path edge and stone-step blend, no new pathfinding or forced navigation line. |
| `water_surface` (motion) | existing_water | Readable shallow edge, slow broad flow and small local riffles; match existing water geometry, no new swimming/flooding. |
| `wind_motion` (motion) | canopy/groundcover | Shared gentle direction with different branch/reed response; preserve leaf attachment and keep combat tells visually stronger. |
| `far_treeline` (distance) | forest/valley | Crown-group silhouette variants matched to near families; prevent a uniform green wall or obvious empty gaps beyond detail range. |
| `far_rock_haze` (distance) | uplands/skyline | Reuse actual terrain skyline, large rock value planes and restrained atmospheric separation; concept mountains do not replace geography. |
| `light_and_quiet` (atmosphere) | all | Broken sunlight, readable cool shade and dusk warmth; local water/leaf events with quiet gaps, no continuous magic drone. |

## Approved wildlife in the landscape

Retain current actor/host IDs and all existing encounter rules. Habitat poses below are visual staging/animation briefs. No new species, loot, enemy cap or ecological AI is introduced. The dedicated human Conservator and other boss finishing remain in the existing separate backlog.

| Existing actor | Approved ancestry | Presentation brief |
| --- | --- | --- |
| `lf_white_stag` | stag | Retain approved stag anatomy; White host structure/current variant and existing encounter location. |
| `lf_green_moth` | moth | Retain liked moth and existing Green host influence; wing/thorax glow never replaces actual attack tells. |
| `lf_paired_boar` | boar | Retain approved boar with its existing paired influence presentation; no new damage or sustain inference. |
| `lf_red_boar` | boar | Approved boar, Red host variant; structural scar placement remains readable in brush. |
| `lf_blue_boar` | boar | Approved boar, Blue host variant; no automatic ice-armour redesign. |
| `ember_whelp` | boar | Low foraging/rooting art pose in scrub pockets; preserve current combat body and role. |
| `cinder_archer` | porcupine | Approved ART-06C face and deep connected quill-root lifelines; keep quill silhouette clear of dense background. |
| `ash_hound` | wolf | Approved wolf, silhouette visible through trunk gaps; resting/walking art poses, no added pack rules. |
| `stone_husk` | bighorn_ram | Approved uneven horn buttress and lifelines; rocky shelf composition frames broad head shape. |
| `shrieker` | crane | Approved long-leg anatomy and exposed throat resonator; tall silhouette against low vegetation. |
| `gloom_crawler` | ground_beetle | Approved displaced plates and deep shell channels; cave/ground detail must not hide its outline. |
| `bog_lurker` | dragonfly_nymph | Approved six-leg nymph and shell lifelines; shallow root-bank composition with clear whole-body read. |
| `marsh_wisp` | moth | Retain liked moth ancestry and current variant; no swarm count increase to fill the fen. |
| `cinder_wisp` | moth | Retain established Ember catalyst moth; warm accent remains below immediate attack-warning salience. |
| `hollow_knight` | tortoise | Approved irregular ossified shell and deep channels; side profile reads as an animal, not a boulder. |
| `valley_elk` | stag | Approved stag/grazer, browsing/resting art poses with open head/antler background; no new fauna spawns implied. |

## Cross-kit handoff requirements

- Organic hero forms: approved concept, local TRELLIS where suitable, Blender topology/anatomy/support inspection, deliberate deep scar geometry and contained pulse.
- Repeated foliage: attached branch/leaf clusters, species silhouette variants, wind weights, tiling/atlas review, tested middle/far detail. Large generation meshes are sources, not automatic runtime assets.
- Hard surfaces: directly model exact modules, frames and mechanisms; shared material family surfaces and independently movable parts. Use sockets at existing engine attachments.
- Resource and device states: compare intact/empty, working, blocked/paused and spent using actual native data; no visual stock owner or hidden duplicated kit.
- Scene composition: near/middle/far continuity, clear cave/work/home routes, readable threats, lighting in day/shade/dusk and local sound with quiet gaps.
- Adoption evidence: source provenance, packed Blender reopen, scale/pivot/body fit, renderer comparison and measured cost in an isolated retained world/save. Numeric budgets follow measurements, not this concept image.
