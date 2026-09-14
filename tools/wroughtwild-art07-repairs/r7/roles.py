"""Audit all 33 catalogue support roles against measured retained anchors."""
from common import *
roles=read(ROOT/'docs/art/concepts/environment/2026-09-09-frontier/asset-catalogue.json')['nature_support']
probe=read(OUT/'runtime/evidence/r7-source-probe.json')
report=read(OUT/'runtime/evidence/r7-views-after-forward_plus/report.json')
counts={}
for m in report['measurements']:
    for kind,count in m['cover']['counts'].items():counts[kind]=max(counts.get(kind,0),count)
# Counts are maximum per matched view, not sums that double-count retained anchors.
selection={
'canopy_broadleaf':('consumed R1','wood resource body','R1 lower trunk stays inside 0.343 m radius through 2.6 m, full crown above 4.2 m. Parent geometry/materials retained; no extra canopy roots.'),
'canopy_conifer':('consumed R1','pine resource body','Same published R1 body/crown fit and retained resource IDs; no new conifer placements.'),
'sapling_shrub':('composed','Habitat_shrub;shrub','B2 1.723 x 1.344 x 0.780 m source fits inside the original 0.944 x 0.810 x 0.924 m shrub envelope, with two crossed shrub forms and a lower fern or bramble sharing its root.'),
'fern_bracken':('composed','Habitat_fern_bed;fern;Cover_fern','Sparse/lush fronds and lower grass share existing roots. Habitat envelope 0.889 x 0.439 x 0.883 m; regional envelope 1.592 x 0.810 x 1.579 m; ordinary ground cap is much smaller.'),
'meadow_grass':('composed','Cover_tuft','Meadow and flattened-edge source forms share the retained approximately 0.300 x 0.158 x 0.296 m mesh envelope, before the unchanged per-anchor scale.'),
'upland_tussock':('retained, not reauthored','dry_sedge;Cover_tuft','Existing regional dry_sedge geometry remains distinct. Small hillside tuft anchors receive the same bounded grass grouping. No new upland asset or occupancy.'),
'fen_sedge':('retained, not reauthored','sedge;Cover_reed','The actual 1.335 x 0.809 x 1.104 m regional sedge and existing wet-ground reed anchors remain. They are not replaced by a grass mesh or a finite harvestable reed bed.'),
'wastes_scrub':('partial composition; scrub uncomposed','Cover_dead_grass','Two grass silhouettes fit the delivered 0.235 x 0.068 x 0.280 m dry-grass envelope. That height cannot support the selected substantial thorn scrub. Existing regional rules have no separate waste-shrub anchor.'),
'bramble_climber':('bramble composed; climber unsuitable','Habitat_shrub1;shrub','Bramble is the rooted low layer of shrub variant 1. The 3.316 m B2 climber requires its exact matching context deadfall; the retained 1.472 m short deadfall is a different support. No floating universal ivy is fitted.'),
'fungal_detritus':('deliberately uncomposed','deadfall;stump','No independent fungus source in the assigned B2/B4 candidate set or retained fungus anchor. Preserve the existing noncollectible deadwood; do not invent harvest silhouettes.'),
'moss_lichen':('retained moss; new surface sheets unsuitable','moss','Original regional moss stays. B2 lichen is a 2 mm sheet, while these anchors allow 0.7 m support rise; placing a flat sheet across them does not establish rooted contact. No arbitrary terrain-conformance system added.'),
'leaf_needle_litter':('deliberately uncomposed','Habitat_fern_bed;fern;shrub','The 23 mm thick source patches require fitted terrain across about 0.95 m. Existing plant-root anchors do not supply that continuous surface fit or branch-correlated litter identity. Do not spread a floating carpet.'),
'root_skirt':('retained parent contact','wood;pine;root_arch','R1 root burial and lower-body fit remain exact, as do original decorative arch feet. Adding a separate skirt would require a matching parent contact and envelope.'),
'deadwood_stump':('retained, not reauthored','Habitat_deadfall;Habitat_stump;deadfall','Retain 1.472 x 0.312 x 0.411 m deadfall and 0.686 x 0.512 x 0.683 m stump. B2 supported climber cannot be attached to their different topology by uniform fit.'),
'river_bank':('deliberately uncomposed','ShallowPool','B4 river bank is part of its authored study landform. Existing generated water/pool boundaries are retained; no matching whole river-bank anchor or new geography is created.'),
'talus_pebbles':('retained, not reauthored','scree;Cover_scree','Existing regional scree and ordinary chips already retain independent anchors and clearance. B2 supplies foliage, not a replacement pebble source.'),
'rock_shelf':('retained, not reauthored','low_outcrop;stone_rib','Existing 4.050 x 1.696 x 2.478 m outcrop and native geology remain authoritative. Wider foliage is not fitted into rock-support roles.'),
'cave_threshold':('retained G1/C6','cave/ruin native anchors','Existing C6 adapter remains installed; no relocated cave lip, new overhang or changed physical entrance.'),
'leyline_scar':('retained G1/R1','existing host and trace anchors','Retain approved host damage and moving light. All newly composed ordinary plant surfaces have altered=false and zero emission; source/work tells retain native meanings.'),
'red_source':('retained F5','red_home_margin','Existing body, finite lots, work and claim ledger retained; native paid Red extraction/restart is separately tested.'),
'white_source':('retained F5','white_home_margin','Existing host, source lot and transmission identity retained. No cover anchor becomes a second source.'),
'blue_source':('retained F5','blue_home_margin','Existing host/formation and held-request states retained; no new gameplay or cover replacement.'),
'green_source':('retained F5','green source anchor','Existing root host, finite ownership and resin work state retained; ordinary shrub roots carry no propagation mechanic.'),
'pressure_pocket':('retained F4','existing smithy pressure anchor','Existing visual/native source restoration remains synchronous; no new cover in its work/attachment space.'),
'ruin_wall':('retained C6','existing ruin pieces','No changed wall poses, collision or generation; original C6 presentation remains under the existing adapter.'),
'ruin_threshold':('retained C6','existing ruin entrance','No new lintel, stair or blocked doorway; native approach and body snapshots compare before/after.'),
'workshop_approach':('retained G1/C6','existing smithy/source route','Native paid workshop and controller route remain the evidence; new cover uses only retained envelopes and participates in original building clearing.'),
'trail_transition':('deliberately uncomposed','existing native source route','No continuous ground-sheet anchor exists along the full retained route. B4 layout and floor shader use its own study coordinates, which cannot be copied as new geography.'),
'water_surface':('retained existing water','ShallowPool','Keep actual pool geometry/material/motion and boundaries. B4 authored river surface is not substituted into unrelated terrain.'),
'wind_motion':('composed','Cover_tuft;Cover_fern;Cover_dead_grass;Habitat_shrub;Habitat_fern_bed;shrub;fern','Existing environment clock drives inherited 18 mm/m, 5.5 s B4 motion. Root-height subtraction fixes the base, and composed per-surface materials are no longer masked by the ordinary cover override.'),
'far_treeline':('consumed R1; distances retained','wood;pine;wildwood_tree;fen_tree','Published R1 canopy plus original decorative skyline anchors. Visibility and selected LOD2 remain; near/middle/far views expose loss of small cover without inventing a distant forest.'),
'far_rock_haze':('retained terrain/atmosphere','native skyline','Actual terrain, rock planes and inherited haze remain. Selected concept mountain mass is not authority to reshape the world.'),
'light_and_quiet':('retained G1/B4 language','existing atmosphere and quiet sound','Day/shade/dusk are matched inspection settings. No gameplay light rig, continuous audio, hidden source cue or new ambience rules.'),
}
assert len(roles)==33 and {r['id'] for r in roles}==set(selection)
rows=[]
for role in roles:
    status,anchors,reason=selection[role['id']]
    measured={k:v for k,v in counts.items() if any(k.startswith(a) for a in anchors.split(';'))}
    rows.append({**role,'r7_status':status,'retained_anchor_types':anchors.split(';'),'observed_counts_max_per_matched_view':measured,'assessment':reason})
result={'roles':rows,'source_probe':probe,'scope':'All 33 support-role briefs assessed. Empty observed cover counts mean a non-MultiMesh role or no such type in these four matched views, never an invented zero-world count. All regional anchor records are also retained in each raw report.','selected_sources':read(OUT/'evidence/selected-source-hashes.json')}
write(OUT/'evidence/role-audit.json',result)
dest=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r7';dest.mkdir(parents=True,exist_ok=True)
write(dest/'role-audit.json',result)
text='# ART-07R7 support-role audit\n\nAll 33 catalogue roles were assessed against the retained anchors and measured source envelopes. Counts and raw measurements are in role-audit.json.\n\n| Role | Treatment | Anchor and fit assessment |\n| --- | --- | --- |\n'
for r in rows:text+='| '+r['id']+' | '+r['r7_status']+' | '+r['assessment']+' |\n'
(dest/'role-audit.md').write_text(text,encoding='utf-8')
print('R7_ROLE_AUDIT',len(rows))
