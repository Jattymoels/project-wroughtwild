"""ART-07 design inventory. --write publishes documents; default verifies them.

Reads current game constraints, never edits tuning or game assets. Brief tables
are authored design proposals. Coverage is checked against data and native kit
discovery, so a new game item cannot silently disappear from the art backlog.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/art/concepts/environment/2026-09-09-frontier"


def rows(value):
    result = {}
    for line in value.strip().splitlines():
        key, *fields = (part.strip() for part in line.split("|"))
        if key in result:
            raise ValueError(f"Duplicate authored brief: {key}")
        result[key] = fields
    return result


MATERIALS = rows("""
wood | Warm sawn planks with broad end grain, pegs and irregular tool marks; retain straight mating edges.
pine | Pale long straight grain and small dark knots; lighter rough cut edges than ordinary timber.
bog_oak | Dense nearly black brown wood, water-dark pores and burnished worn corners; grain remains visible in shade.
ash_wood | Bone-pale fibrous grain and weathered silver edges; a timber surface, not bone or snow.
stone | Dressed grey courses with restrained chips and visible bedding; regular joints distinguish worked masonry from fieldstone.
iron | Dark hammered iron, broad rivet heads and oxide in protected seams; muted metal, no generic orange glow.
bronze | Warm cast/hammered bronze with dark green patina in recesses; curved arch remains recognisably worked metal.
steel | Cooler tightly finished plates, darker weld/fastener lines and sharper worn edges than iron.
silver | Pale soft metal with dark tarnished recesses; curved and structural forms only where the existing traits permit them.
charcoal | Angular porous black fuel chunks and subtle ash; only the fuel form, never charcoal walls.
fieldstone | Rough varied stones with dry contact joints and lichen remnants; low footing/dry wall only.
slate | Thin dark cleaved layers, offset joints and chipped edge laminations; roofs read in the silhouette at distance.
shellstone | Warm pale cut stone carrying uneven fossil fragments and occasional whole shell impressions; fossils must not tile identically.
rustclay_brick | Warm red-brown fired courses, varied firing marks and restrained pale joints; repeat spacing fits module boundaries.
woven_reed | Over-under reed weave, bundled cut edges and integral lash-bound frame; opaque functional wall coverage despite visible weave.
resinheart | Strong amber-brown grain, dense cut end rings and occasional non-emissive resin pockets; retain the collected tree's identity.
corkbark | Thick porous bark faces, layered cut edge and inset frame; use coarse pores rather than noisy universal bump.
vitrified_basalt | Dark fused rock with broken glossy skin over a matte heavy body; heat-worked material, not an always-burning wall.
cinderglass | Smoky mineral glass with modest distortion and an integral fitted frame; opaque-enough edge/selection readability and existing projectile blocking.
""")

SHAPES = rows("""
codex_corner | A clipped diagonal block with continuous side grain/courses and a clean diagonal mating face.
codex_corner_floor | Thin triangular slab matching the clipped block; finish the cut edge, preserve exact thickness.
codex_roof_slope | One half-height pitched module; layer covering toward the low edge and keep shared roof seams exact.
codex_roof_hip | Convex outer roof transition with continuous ridge/corner covering; preserve the same cell envelope.
codex_roof_valley | Concave roof transition with a readable drainage valley; no decorative lip blocking the joining module.
cube | Solid regular module; timber assembly, masonry courses or metal panels express family without changing occupancy.
wall_panel | Thin vertical partition with integral believable edges; courses and grain continue at neighbouring faces.
pillar | Narrow vertical support with end joints contained in its exact width; optional details must fit real corner geometry.
beam | Horizontal support with readable underside and end grain/metal caps; preserve the existing exposed beam section.
floor_slab | Flat floor/ceiling module with legible rim; same finish on exposed underside, no floating trim.
stairs | Two substantial steps inside one cell; match native stair silhouette, not a new many-tread staircase.
door | Single hinged leaf with frame/hinge detail inside the existing wall form; mirrored hinge orientation and actual open/closed state.
roof_wedge | Full-height 45-degree cut masonry wedge; distinguish this older stone form from half-height covering roofs.
girder | Two-cell metal beam with a visibly reinforced section; no new cable support or structural rule.
arch | Worked malleable metal head with half-round underside; clear metal finish prevents confusion with a new masonry arch.
half_cube | Half-grid solid for trim or a step; retain material grain scale, avoid an oversized full-block texture squeezed onto it.
half_wall | Small face panel for sill/parapet infill; same edge seam contract as its coarse parent.
half_pillar | Slender half-grid post for legs/pickets; no attached decorative finial beyond the body.
half_beam | Small rail or sill; matching end grain and joints at the half-cell positions.
half_slab | Small shelf/step/roof edge with a finished underside; preserve fine lattice placement.
chest | Low jointed storage box; inherited material family, supported hinges and clear lid opening; contents stay in native storage.
campfire | Low fuel pile with timber or charcoal-specific shape; burning/ash transition reads native fuel lifetime and heat.
foundation | Half-height dry-laid rough-stone footing with broad load-bearing base; no full masonry cube implied.
dry_wall | Low rough-stone course on a wall face; uneven cap inside dimensions, no new shelter or collision interpretation.
light_panel | Framed thin covering wall; family-specific weave/bark/planks/sheets with a complete blocking surface.
glazed_window | Fixed smoky pane and complete integral frame as one piece; no openable window or extra frame recipe.
""")

# Visual state names below describe review poses/feedback; native fields remain
# authoritative. An animation proposal is not a new simulation state.
DEVICES = rows("""
workbench | 04-stations-and-home | Pegged compact timber bench, thick scarred top and contained clamp. Distinct horizontal wood working surface. | idle; existing craft feedback | Direct Blender frame and fitted tools.
forge_basic | 04-stations-and-home | Low stone hearth and supported short cowl, iron working face, dark cold basin that lights only with real work feedback. | idle; existing fuel/work feedback | Direct Blender hearth/frame; reusable stone/iron surfaces.
forge_improved | 04-stations-and-home | Same forge plinth and footprint with stronger iron collar, better contained hot chamber and visibly refined working plate. | existing global upgrade appearance; idle/work | Variant of basic forge; no separate kit.
mason_yard | 04-stations-and-home | Squat timber support around a fieldstone dressing bed, attached wedges/chisel rests, cutting dust inside the footprint. | idle; existing stone work feedback | Direct Blender support and contained dressed stone.
lantern_lamp | 05-useful-fixtures | Warm Lanternheart core in papery husk within a small timber/reed cage; protect the recognisable recovered heart. | native on/off; dismantled core | Organic core source plus precisely fitted frame.
cargo_winch | 05-useful-fixtures | Root tension drum on stout timber supports, hand crank, one basket and a distinct cable attachment. | unwound/wound; loaded; travelling/blocked/arrived | Direct mechanism; controlled organic root coil, separate moving drum/basket.
winch_landing | 05-useful-fixtures | Plain matching receiving cradle and rope guide; support feet and basket clearance, no second rare core. | connected; arriving/received cargo | Direct Blender; share winch timber/iron and attachment grammar.
stormglass_lever | 05-useful-fixtures | Ringing lightning-glass tube in clamps, readable tapping hand lever and outgoing request socket. | idle; actual pulse; unavailable request | Organic tube plus direct frame/lever with physical pivot.
magnetic_sorter | 05-useful-fixtures | Inclined hand-fed chute, braced dark Pullstone nodule and two unmistakable receiving trays. | empty/loaded; native sorting; separate tray contents | Direct Blender chute/trays; organic magnetic nodule.
ventlung_bellows | 05-useful-fixtures | Folded natural membrane between boards, fibre lashings, priming handle and short directed nozzle. | unprimed/primed; actual discharge | Organic membrane with deformation-friendly topology; direct boards/nozzle.
pressure_feeder | 05-useful-fixtures | Compact frame with separate clay hopper, fuel cup, root drum, pressure chamber and brick tray; distinct pressure and forge attachments. | idle; loaded; reserved/running; paused/blocked; output | Direct assembled mechanisms; separate supply meshes driven by native readout.
white_connection | retained-ART04B | Reuse approved White post, fracture material and fitted frame; immediate request path stays visually distinct from receiver winding. | native request/connection; no stored winding | Reuse tools/wroughtwild-white and its accepted handoff.
blue_delay | retained-ART04C | Reuse approved supported flake/delay form; visible held request with a legible local pause/release cue. | empty; holding; paused; released/cancelled | Reuse tools/wroughtwild-blue and its accepted handoff.
green_junction | retained-ART04D | Reuse approved resin-root fork with two distinct branch sockets; branch result must not imply free work. | native branch outcomes; disconnected | Reuse tools/wroughtwild-green and its accepted handoff.
red_heat_buffer | retained-ART04 | Reuse approved braced heat store, clear charge chamber and existing feeder attachment. Frame material is separate from spent charge. | empty/charged; supplying; native reservation/removal restriction | Reuse tools/wroughtwild-workshop and its accepted handoff.
""")

RESOURCE_BRIEFS = rows("""
tree | meadow/forest | Reuse ART-02 broadleaf trunk language; branching silhouette, leaf masses, exposed roots and matching cut stump; ordinary and locally altered finish.
pine | forest/uplands | Tapered conifer with uneven branch tiers, attached needle clusters and visible trunk gaps; pale cut timber matches the pine building family.
bog_oak | fen | Leaning dark oak, flared knuckled waterline roots, sparse lower branches and dense irregular upper crown; dark cut wood.
ash_snag | ember_wastes | Bleached twisted dead trunk with broken boughs, limited char in splits and readable standing/felled silhouette; not a forest of identical spikes.
resinheart_tree | oldgrowth_grove | Thick buttressed amber-grain oldgrowth with hanging crown masses and deep structural root channels on altered variant; preserve approved grove ancestry.
corkbark_deadfall | oldgrowth_grove | Low independent dead trunk with thick porous rolled bark lips; show exposed lighter underlayer as its own finite deposit is worked.
boulder | all | Reuse approved fractured rock as one family; rounded weathering vs hard broken faces, separate removable chunks and final worked remnant.
stone_seam | rock/caves | Bedrock face with broad bedding planes and wedge-readable split; integrate visually with surrounding rock while retaining one work target.
iron_vein | rock/caves | Ochre iron streaks and dense dull nodules inside broken host rock, not uniform shiny crystal spikes.
copper_vein | era_2_ore_sites | Weathered green-brown copper-bearing bands in warm host rock; exposed worked interior remains recognisable without blue magic association.
tin_vein | era_2_ore_sites | Pale granular mineral pockets in dark banded rock; distinct from iron and silver at interaction distance.
ember_iron_vein | era_3_ore_sites | Heat-marked dark ore with restrained ember-bearing internal fractures; hot/worked states follow existing rules.
silver_vein | era_3_ore_sites | Narrow pale metallic seam through dark host rock; broad material contrast survives reduced texture detail.
slate_outcrop | quarry_escarpment | Thin stacked dark sheets with exposed split edge and a readable detachable working face; matching slate roof layers.
shellstone_outcrop | quarry_escarpment | Pale fossil-bearing bed with scattered shell cross-sections and broad cleaving planes; irregular fossils, not repeated giant medallions.
clay_bank | fen_hollow | Damp rust-coloured earth pocket in a rooted bank with scooped working layers; depleted pocket stays distinct from decorative mud.
reed_bed | fen_hollow | Harvestable mature upright reed bundle with clear cuttable stalk mass; separate low decorative sedge from this work target.
lanternheart | rare_sites | Papery lantern husk sheltering a luminous intact heart; harvest reveals/lifts that same core and leaves an empty husk.
thrumroot | rare_sites | Bowed deadfall held by taut sinewy roots; exposed reusable coil has the same weave/strain as the winch drum.
stormglass | rare_sites | Naturally fused lightning tube partly embedded in scarred ground; ringing hollow form becomes the lever's resonator.
pullstone | rare_sites | Dark nodule attracting clinging ferrous grit; working separates one intact visibly dense core from its braced host.
ventlung | rare_sites | Bulged natural membrane in a split host, seam and pressure-release opening visible; lifted membrane becomes the hand bellows.
""")

# IDs here are art-catalogue identifiers only, not new node types or recipes.
SUPPORT = rows("""
canopy_broadleaf | foliage | meadow/forest | Several linked leaf-mass arrangements on real branches; near leaf detail, simpler middle crowns and matched distant silhouette.
canopy_conifer | foliage | forest/uplands | Needle-cluster branches with a sparse lower tier and irregular upper spire; separate wind weighting and distant solid read.
sapling_shrub | foliage | meadow/forest | Young bent stems and low bush clusters connect grass to tree scale; leave trunk access and routes open.
fern_bracken | groundcover | forest/river | Broad asymmetric frond groups with sparse and lush variants; reuse approved ART-02 understory where suitable.
meadow_grass | groundcover | meadow | Mixed-height clumps and flattened edge variant, quiet olive/straw colour shifts; distribute in authored patches.
upland_tussock | groundcover | uplands | Dense low wind-combed clump with a dry rim and green centre; fills pockets between rock without hiding ledges.
fen_sedge | groundcover | fen | Short rooted wet sedge hummocks, distinct from the finite harvestable reed_bed.
wastes_scrub | groundcover | ember_wastes | Thorny low scrub and coarse surviving grass, weathered seed heads, broken rhythm across grit rather than bare ash everywhere.
bramble_climber | groundcover | forest/ruins | Restrained thorn stems, leaf sprays and climbing ivy rooted to actual support; keep openings readable.
fungal_detritus | groundcover | oldgrowth/fen | Non-glowing shelf fungi, small mushrooms and damp wood debris as cosmetic habitat detail, no new harvest promise.
moss_lichen | surface | rock/forest/fen | Damp moss cushions and dry pale lichen masks with different edge shapes; no universal carpet on every material.
leaf_needle_litter | surface | forest/meadow | Branch-correlated litter, dark humus and exposed soil transition; tiling maps plus a few silhouette-breaking chips.
root_skirt | geology_contact | forest/fen | Attached flared roots crossing soil and rock; modular contact pieces derived from parent tree, no floating ends.
deadwood_stump | geology_contact | forest/meadow | Broken log, stump and low branch variants; ordinary decorative pieces cannot mimic fresh resource yields.
river_bank | geology_contact | river/fen | Irregular damp ledge, root shelf and reed-edge transitions, matching actual bank support and access.
talus_pebbles | geology_contact | uplands/river | Grouped angular scree plus rounded water pebbles; clustered with exposed ground between, not a collider on every stone.
rock_shelf | geology_contact | uplands | Layered ledge transition and small outcrop variants; silhouette and material variation fit retained terrain.
cave_threshold | geology_contact | caves | Broken overhang/root lip and damp wall transitions framing existing cave opening; clear human entrance and host approach.
leyline_scar | augmentation | existing_influence_routes | Deep host-specific recessed channel with dark margins and contained moving light; ordinary/recessed-unlit/lit review states.
red_source | retained_source | existing_LF_red | Reuse ART-04 Red host, owned fragments, recovered salt and charge language; native lot/formation states only.
white_source | retained_source | existing_LF_white | Reuse ART-04B White fractured host and recovered mineral; request transmission is not stored drive.
blue_source | retained_source | existing_LF_blue | Reuse ART-04C layered host and recovered flakes; retain native formation and held-request distinction.
green_source | retained_source | existing_LF_green | Reuse ART-04D root host and resin pieces; growth supports branching anatomy, not free item propagation.
pressure_pocket | existing_source | existing_pressure_sites | Braced split host with readable finite pressure reservoir and attachment; intact/worked/exhausted native stock, no spontaneous refill.
ruin_wall | ruin | existing_ruins | Weathered low masonry wall, broken corner and small rubble cap, root contact; no relocation or new wall collision.
ruin_threshold | ruin | existing_ruins | Fallen lintel, worn stair and fractured paving expose former human routes; keep existing entrance clear.
workshop_approach | ruin | existing_workplaces | Reuse original smithy language and LF marks/clamps; distinguish old ordinary craft from deliberate later containment.
trail_transition | surface | existing_routes | Exposed compacted soil, leaf-thin path edge and stone-step blend, no new pathfinding or forced navigation line.
water_surface | motion | existing_water | Readable shallow edge, slow broad flow and small local riffles; match existing water geometry, no new swimming/flooding.
wind_motion | motion | canopy/groundcover | Shared gentle direction with different branch/reed response; preserve leaf attachment and keep combat tells visually stronger.
far_treeline | distance | forest/valley | Crown-group silhouette variants matched to near families; prevent a uniform green wall or obvious empty gaps beyond detail range.
far_rock_haze | distance | uplands/skyline | Reuse actual terrain skyline, large rock value planes and restrained atmospheric separation; concept mountains do not replace geography.
light_and_quiet | atmosphere | all | Broken sunlight, readable cool shade and dusk warmth; local water/leaf events with quiet gaps, no continuous magic drone.
""")

FAUNA = rows("""
lf_white_stag | stag | Retain approved stag anatomy; White host structure/current variant and existing encounter location.
lf_green_moth | moth | Retain liked moth and existing Green host influence; wing/thorax glow never replaces actual attack tells.
lf_paired_boar | boar | Retain approved boar with its existing paired influence presentation; no new damage or sustain inference.
lf_red_boar | boar | Approved boar, Red host variant; structural scar placement remains readable in brush.
lf_blue_boar | boar | Approved boar, Blue host variant; no automatic ice-armour redesign.
ember_whelp | boar | Low foraging/rooting art pose in scrub pockets; preserve current combat body and role.
cinder_archer | porcupine | Approved ART-06C face and deep connected quill-root lifelines; keep quill silhouette clear of dense background.
ash_hound | wolf | Approved wolf, silhouette visible through trunk gaps; resting/walking art poses, no added pack rules.
stone_husk | bighorn_ram | Approved uneven horn buttress and lifelines; rocky shelf composition frames broad head shape.
shrieker | crane | Approved long-leg anatomy and exposed throat resonator; tall silhouette against low vegetation.
gloom_crawler | ground_beetle | Approved displaced plates and deep shell channels; cave/ground detail must not hide its outline.
bog_lurker | dragonfly_nymph | Approved six-leg nymph and shell lifelines; shallow root-bank composition with clear whole-body read.
marsh_wisp | moth | Retain liked moth ancestry and current variant; no swarm count increase to fill the fen.
cinder_wisp | moth | Retain established Ember catalyst moth; warm accent remains below immediate attack-warning salience.
hollow_knight | tortoise | Approved irregular ossified shell and deep channels; side profile reads as an animal, not a boulder.
valley_elk | stag | Approved stag/grazer, browsing/resting art poses with open head/antler background; no new fauna spawns implied.
""")

INPUTS = [
    "data/tuning/construction.json", "data/tuning/crafting.json",
    "data/tuning/worldgen.json", "data/tuning/world.json",
    "game/extensions/wroughtwild_sim/src/strange_frontier_bindings.inc",
    "game/extensions/wroughtwild_sim/src/wroughtwild_sim.cpp",
    "sim/src/tuning.cpp", "game/scripts/contraption_site.gd",
    "game/art/contraption_look.gd", "game/art/contraption_look.tres",
    "game/scenes/station_body.tres",
]


def read_json(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def exact(label, authored, actual):
    missing, extra = set(actual) - set(authored), set(authored) - set(actual)
    if missing or extra:
        raise ValueError(f"{label}: missing {sorted(missing)}, stale {sorted(extra)}")


def vector(text):
    return [float(v.strip()) for v in text.split(",")]


def catalogue():
    construction = read_json(INPUTS[0])
    crafting = read_json(INPUTS[1])
    worldgen = read_json(INPUTS[2])
    world = read_json(INPUTS[3])
    nodes = {k: v for k, v in worldgen["nodes"].items() if isinstance(v, dict)}
    exact("shape briefs", SHAPES, [s["id"] for s in construction["shapes"]])
    exact("material briefs", MATERIALS, [s["id"] for s in construction["materials"]])
    exact("resource briefs", RESOURCE_BRIEFS, nodes)
    exact("fauna briefs", FAUNA, [s["id"] for s in world["enemies"]])
    bridge = (ROOT / INPUTS[4]).read_text(encoding="utf-8")
    base = re.search(r'machine_kinds\[\]\s*=\s*\{([^}]+)\}', bridge).group(1)
    native_kinds = set(re.findall(r'"(\w+)"', base))
    function = bridge.split('String WroughtwildSim::contraption_kind_for_kit', 1)[1].split('bool WroughtwildSim::contraption_place', 1)[0]
    native_kinds.update(re.findall(r'return "(\w+)";', function))
    station_ids = {s["id"] for s in crafting["stations"]}
    exact("station/fixture briefs", DEVICES, station_ids | native_kinds)
    kit_recipes = {}
    for recipe in crafting["recipes"]:
        for output, quantity in recipe["outputs"].items():
            if output.endswith("_kit"):
                if output in kit_recipes or quantity != 1:
                    raise ValueError(f"Review kit recipe ownership: {output}")
                kit_recipes[output] = recipe
    station_kits = {s["kit_item"]: s["id"] for s in crafting["stations"] if s.get("kit_item")}
    mappings = {f"{kind}_kit": kind for kind in native_kinds} | station_kits
    exact("craftable vs native placeable kits", kit_recipes, mappings)

    look = (ROOT / "game/art/contraption_look.gd").read_text(encoding="utf-8")
    bounds = {key: vector(value) for key, value in re.findall(r'var (\w+_bounds)\s*:=\s*Vector3\(([^)]+)\)', look)}
    # Resource overrides, if introduced later, must take precedence over defaults.
    overrides = (ROOT / "game/art/contraption_look.tres").read_text(encoding="utf-8")
    bounds.update({key: vector(value) for key, value in re.findall(r'^(\w+_bounds)\s*=\s*Vector3\(([^)]+)\)', overrides, re.M)})
    site = (ROOT / "game/scripts/contraption_site.gd").read_text(encoding="utf-8")
    cases = site.split('static func bounds_for', 1)[1].split('static func find_site', 1)[0]
    kind_bounds = {}
    for choices, key in re.findall(r'((?:"\w+"(?:,\s*)?)+): return LOOK\.(\w+)', cases):
        for kind in re.findall(r'"(\w+)"', choices):
            kind_bounds[kind] = bounds[key]
    default = re.findall(r'^\s*return LOOK\.(\w+)', cases, re.M)[-1]
    station_body = vector(re.search(r'size = Vector3\(([^)]+)\)', (ROOT / INPUTS[-1]).read_text()).group(1))

    materials = []
    shapes = []
    for material in construction["materials"]:
        materials.append({"id": material["id"], "name": material["display_name"],
                          "source_item": material["source"], "traits": material["traits"],
                          "only_for_trait": material.get("only_for_trait"), "brief": MATERIALS[material["id"]][0]})
    for shape in construction["shapes"]:
        traits = set(shape.get("requires_traits", []))
        allowed = [m["id"] for m in materials if traits <= set(m["traits"]) and
                   (not m["only_for_trait"] or m["only_for_trait"] in traits)]
        shapes.append({"id": shape["id"], "name": shape["display_name"], "size_m": shape["size_m"],
                       "element": shape["element"], "form": shape.get("form", "box"),
                       "oriented": shape.get("oriented", False), "cells_tall": shape.get("cells_tall", 1),
                       "cells_long": shape.get("cells_long", 1),
                       "fine_of": shape.get("fine_of"), "material_cost": shape["material_cost"],
                       "requires_traits": sorted(traits), "requires_world_effect": shape.get("requires_world_effect"),
                       "allowed_materials": allowed, "brief": SHAPES[shape["id"]][0],
                       "board": "04-stations-and-home" if shape["id"] in ("chest", "campfire") else "03-building-family"})
    devices = []
    for key, (board, brief, states, method) in DEVICES.items():
        station = next((s for s in crafting["stations"] if s["id"] == key), None)
        kit = next((k for k, value in mappings.items() if value == key), None)
        recipe = kit_recipes.get(kit)
        devices.append({"id": key, "kit": kit, "upgrade_from": station.get("upgrade_from") if station else None,
                        "name": station["display_name"] if station else recipe["display_name"].removesuffix(" Kit"),
                        "recipe_id": recipe["id"] if recipe else None,
                        "recipe_inputs": recipe["inputs"] if recipe else None,
                        "minimum_era": recipe.get("minimum_era", 1) if recipe else None,
                        "upgrade_cost": station.get("upgrade_cost") if station else None,
                        "profile_filter": recipe.get("world_profile") if recipe else None,
                        "bounds_m": station_body if station else kind_bounds.get(key, bounds[default]),
                        "board": board, "brief": brief, "review_states": states.split("; "), "method": method})
    resources = [{"id": key, "name": nodes[key]["display_name"], "item": nodes[key]["material_family"],
                  "habitat": fields[0], "brief": fields[1], "existing_visual": nodes[key]["visual"],
                  "review_states": ["intact", "native work stages where present", "native depleted/felled aftermath"],
                  "method": "Reuse approved source where available; organic source/Blender finishing; matched finite work states."}
                 for key, fields in RESOURCE_BRIEFS.items()]
    support = [{"id": key, "role": fields[0], "habitat": fields[1], "brief": fields[2],
                "status": "reuse approved family" if fields[0] == "retained_source" else "proposed art brief; no new simulation identity"}
               for key, fields in SUPPORT.items()]
    fauna = [{"id": key, "ancestry": fields[0], "brief": fields[1]} for key, fields in FAUNA.items()]
    return {"schema_version": 1, "status": "ART-07A design proposals; no runtime adoption",
            "source_hash_policy": "SHA-256 of UTF-8 input text after CRLF-to-LF normalization; images use exact bytes",
            "sources": {path: hashlib.sha256((ROOT / path).read_bytes().replace(b"\r\n", b"\n")).hexdigest() for path in INPUTS},
            "constraints": {"grid_m": construction["grid_size_metres"], "lattice_divisions": construction["lattice_divisions"],
                            "normal_profiles_kits": len(station_kits) + len(re.findall(r'"(\w+)"', base)),
                            "living_frontier_supported_profiles_kits": len(mappings),
                            "legal_material_shape_pairs": sum(len(s["allowed_materials"]) for s in shapes),
                            "station_body_m": station_body,
                            "scope": "Concept coverage only. Profile/era/unlock gates still apply; no new rules or universal kit availability."},
            "materials": materials, "shapes": shapes, "devices": devices,
            "resource_nodes": resources, "nature_support": support, "fauna_presentation": fauna}


def table(headers, entries):
    return ["| " + " | ".join(headers) + " |", "| " + " | ".join("---" for _ in headers) + " |"] + [
        "| " + " | ".join(str(cell).replace("|", "/").replace("\n", " ") for cell in entry) + " |" for entry in entries]


def document(data):
    c = data["constraints"]
    lines = ["# Wroughtwild — complete environment and placeable design catalogue", "",
             "Generated from current game data plus the authored briefs in `tools/wroughtwild-world-design/catalogue.py`.",
             "This is an art backlog, not evidence of model completion or a change to recipes, spawns or saved geography.", "",
             f"Coverage: **{len(data['shapes'])} shapes, {len(data['materials'])} material families, {c['legal_material_shape_pairs']} legal material/shape pairs, "
             f"{c['living_frontier_supported_profiles_kits']} craftable kits and one in-place forge upgrade**. Ordinary profiles expose {c['normal_profiles_kits']} kits; the four coloured kits require a supported Living Frontier profile.",
             f"Nature: **{len(data['resource_nodes'])} existing resource node types and {len(data['nature_support'])} supporting art roles**. Wildlife briefs retain all {len(data['fauna_presentation'])} existing overworld actor/host IDs, using approved ancestries.", "",
             "The boards illustrate families. The tables cover every item, including small pieces not separately pictured. Incidental furniture in a scene does not add a recipe.", "",
             "## Material families", ""]
    lines += table(["ID / collected item", "Traits / restriction", "Proposed material construction"], [
        (f"`{m['id']}` / `{m['source_item']}`", ", ".join(m['traits']) + (f"; only shapes requiring {m['only_for_trait']}" if m['only_for_trait'] else ""), m['brief']) for m in data['materials']])
    lines += ["", "## Every building shape", "", "Direct Blender modules, using the existing face/edge/block pivots and dimensions. Preserve coarse/fine alignment, grain scale, every allowed rotation and both sides of exposed pieces. Placement preview and installed geometry must share the same source.", ""]
    lines += table(["ID / size in metres", "Visual brief", "Legal material families / gate"], [
        (f"`{s['id']}` / {' × '.join(map(str,s['size_m']))}", s['brief'], ", ".join(s['allowed_materials']) + (f"; world unlock `{s['requires_world_effect']}`" if s['requires_world_effect'] else "")) for s in data['shapes']])
    lines += ["", "These pairings are computed from the native material-trait contract, including `only_for_trait`. Examples: fieldstone is footing/dry wall only, charcoal is fuel only, cinderglass is the integral fixed window, and the arch requires a malleable material. Material eligibility does not bypass a world unlock. Existing recipe and shape costs are retained in the JSON inventory.", "",
              "## Every station and fixture", "", "Bounds below are current engine bodies, not an artistic resizing suggestion. Feet/pivot and rotating/extending parts need actual placement and movement checks before adoption. Station kits use a 0.96 × 2 × 0.96 m body, including reserved air above low tables. Profile filters remain authoritative. A forge upgrade has no separate kit.", ""]
    lines += table(["ID / kit / bounds in metres", "Design / production route", "Actual-state review poses"], [
        (f"`{d['id']}` / `{d['kit'] or 'upgrade in place'}` / {' × '.join(map(str,d['bounds_m']))}", d['brief'] + " " + d['method'], "; ".join(d['review_states'])) for d in data['devices']])
    lines += ["", "Every kit additionally needs a readable pack/palette thumbnail, grounded placement preview, occupied outline, local interaction focus and faithful dismantle/reload presentation. A failed placement retains its kit; success creates exactly one usable fixture. Native counts and work progress drive contents and motion; idle decoration must not invent stock, energy or items.", "",
              "## Existing finite resource art", "", "Every current worldgen resource type has its own brief. Art variants do not add resource identities or duplicate yields. Original positions, collision/work targets, stock and saved partial progress remain. Model depletion rather than hiding missing stock behind an intact glowing source.", ""]
    lines += table(["Node / recovered item", "Habitat art context", "Host → worked appearance"], [
        (f"`{r['id']}` / `{r['item']}`", r['habitat'], r['brief']) for r in data['resource_nodes']])
    lines += ["", "## Supporting nature and world feel", "", "These IDs belong to this art catalogue only. Habitat labels are composition briefs, not new biome definitions or spawn assignments. Decorative reeds, wood and rocks must not misrepresent finite work targets. Existing pressure and coloured sources retain their separate native ledgers.", ""]
    lines += table(["Art role", "Context", "Proposed form / reuse"], [(f"`{s['id']}` ({s['role']})", s['habitat'], s['brief']) for s in data['nature_support']])
    lines += ["", "## Approved wildlife in the landscape", "", "Retain current actor/host IDs and all existing encounter rules. Habitat poses below are visual staging/animation briefs. No new species, loot, enemy cap or ecological AI is introduced. The dedicated human Conservator and other boss finishing remain in the existing separate backlog.", ""]
    lines += table(["Existing actor", "Approved ancestry", "Presentation brief"], [(f"`{f['id']}`", f['ancestry'], f['brief']) for f in data['fauna_presentation']])
    lines += ["", "## Cross-kit handoff requirements", "",
              "- Organic hero forms: approved concept, local TRELLIS where suitable, Blender topology/anatomy/support inspection, deliberate deep scar geometry and contained pulse.",
              "- Repeated foliage: attached branch/leaf clusters, species silhouette variants, wind weights, tiling/atlas review, tested middle/far detail. Large generation meshes are sources, not automatic runtime assets.",
              "- Hard surfaces: directly model exact modules, frames and mechanisms; shared material family surfaces and independently movable parts. Use sockets at existing engine attachments.",
              "- Resource and device states: compare intact/empty, working, blocked/paused and spent using actual native data; no visual stock owner or hidden duplicated kit.",
              "- Scene composition: near/middle/far continuity, clear cave/work/home routes, readable threats, lighting in day/shade/dusk and local sound with quiet gaps.",
              "- Adoption evidence: source provenance, packed Blender reopen, scale/pivot/body fit, renderer comparison and measured cost in an isolated retained world/save. Numeric budgets follow measurements, not this concept image.", ""]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    data = catalogue()
    outputs = {"asset-catalogue.json": json.dumps(data, indent=2, ensure_ascii=False) + "\n",
               "asset-catalogue.md": document(data)}
    for name, content in outputs.items():
        encoded = content.encode("utf-8")
        path = OUT / name
        if args.write:
            path.write_bytes(encoded)
        elif not path.exists() or path.read_bytes() != encoded:
            raise SystemExit(f"FAIL: {name} is missing/stale; inspect source changes before --write")
    print(json.dumps({"result": "written" if args.write else "PASS", "shapes": len(data['shapes']),
                      "materials": len(data['materials']), "kits": sum(bool(d['kit']) for d in data['devices']),
                      "upgrades": sum(bool(d['upgrade_from']) for d in data['devices']),
                      "finite_resource_types": len(data['resource_nodes']), "supporting_art_roles": len(data['nature_support']),
                      "actor_ids": len(data['fauna_presentation']), **data['constraints']}, indent=2))


if __name__ == "__main__":
    main()
