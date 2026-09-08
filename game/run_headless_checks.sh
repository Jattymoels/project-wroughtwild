#!/bin/sh
# Runs every in-engine check headless. Requires the pinned Godot binary
# (4.5-stable); point GODOT at it, e.g.:
#   GODOT=~/godot/Godot_v4.5-stable_linux.x86_64 ./run_headless_checks.sh
# The wroughtwild_sim GDExtension must be built first (see README.md).
set -e
GODOT="${GODOT:-godot4}"
cd "$(dirname "$0")"

echo "== import =="
# Godot 4.5 can segfault at the end of the very first import after a
# GDExtension appears (upstream godotengine/godot#111645, extension doc
# generation race). The import itself completes; a second run is clean.
"$GODOT" --headless --path . --import || {
  echo "first import exited $? (known upstream #111645 on a fresh .godot/); re-running"
  "$GODOT" --headless --path . --import
}

echo "== unit tests =="
"$GODOT" --headless --path . --script tests/run_tests.gd

echo "== Codex art regression checks =="
"$GODOT" --headless --path . --script tests/art_checks.gd

echo "== integration test (physics + placement loop) =="
# Numbered physics steps inspect process-owned trial rewards on the next step.
# Fixed cadence prevents catch-up physics steps from skipping that process turn.
"$GODOT" --headless --fixed-fps 60 --path . res://tests/integration.tscn

echo "== horde test (D-012 chase, training, cone, dash) =="
"$GODOT" --headless --path . res://tests/horde.tscn

echo "== INT-05C dead-target and reaction recovery boundaries =="
"$GODOT" --headless --fixed-fps 240 --path . res://tests/power_progression_review.tscn -- --boundary-only --expect-fixed

echo "== grammar test (frost orb fork, freeze breakpoints, shatter cascade) =="
"$GODOT" --headless --path . res://tests/grammar.tscn

echo "== feel test (pickup magnet, harvest feedback, jump buffer) =="
"$GODOT" --headless --path . res://tests/feel.tscn

echo "== common building loads and ownership =="
"$GODOT" --headless --path . res://tests/building_load_boundaries.tscn
"$GODOT" --headless --path . res://tests/building_load_boundaries.tscn -- --load-restore-only
"$GODOT" --headless --path . res://tests/building_load_review.tscn
"$GODOT" --headless --path . res://tests/building_load_review.tscn -- --load-restore-only

echo "== Codex faceted terrain =="
"$GODOT" --headless --path . res://tests/faceted_terrain.tscn

echo "== Codex crafted terrain, modular workshop and woodland checks =="
"$GODOT" --headless --path . res://tests/crafted_traversal.tscn
"$GODOT" --headless --path . res://experiments/roof_workshop.tscn
"$GODOT" --headless --path . res://experiments/woodland_comparison.tscn
"$GODOT" --headless --path . res://tests/weathered_save.tscn
"$GODOT" --headless --path . res://tests/presentation_checks.tscn
"$GODOT" --headless --path . res://tests/material_transitions.tscn
"$GODOT" --headless --path . res://tests/creature_motion_checks.tscn
"$GODOT" --headless --path . res://tests/frontier_continuation_checks.tscn
"$GODOT" --headless --path . res://experiments/station_review.tscn
"$GODOT" --headless --path . res://experiments/building_review.tscn
"$GODOT" --headless --path . res://tests/gathering_feedback.tscn
"$GODOT" --headless --audio-driver Dummy --path . res://tests/interaction_feedback.tscn
"$GODOT" --headless --audio-driver Dummy --path . res://tests/workshop_feedback.tscn
"$GODOT" --headless --path . res://tests/build_usability.tscn
"$GODOT" --headless --path . res://tests/home_station_placement.tscn
"$GODOT" --headless --path . res://tests/home_material_joins.tscn
"$GODOT" --headless --path . res://tests/home_headroom.tscn
"$GODOT" --headless --path . res://tests/home_workshop_review.tscn
"$GODOT" --headless --path . res://tests/home_terrain_placement.tscn
"$GODOT" --headless --path . res://tests/home_station_clearance.tscn
"$GODOT" --headless --path . res://tests/placement_transactions.tscn
"$GODOT" --headless --path . res://tests/placement_transactions.tscn -- --placement-restore-only
"$GODOT" --headless --path . res://tests/placement_generated_fixtures.tscn
"$GODOT" --headless --path . res://tests/placement_generated_fixtures.tscn -- --placement-restore-only
"$GODOT" --headless --path . res://tests/placement_scenery.tscn
"$GODOT" --headless --path . res://tests/home_door_persistence.tscn
"$GODOT" --headless --path . res://tests/save_recovery.tscn
"$GODOT" --headless --path . res://tests/crafting_catalogue.tscn
"$GODOT" --headless --path . res://tests/forge_progression.tscn
"$GODOT" --headless --path . res://tests/establishment_guide.tscn
"$GODOT" --headless --path . res://tests/panel_density.tscn
"$GODOT" --headless --audio-driver Dummy --path . res://tests/foundry_flow_review.tscn
"$GODOT" --headless --audio-driver Dummy --path . res://tests/foundry_clarity.tscn
"$GODOT" --headless --audio-driver Dummy --path . res://tests/foundry_clarity.tscn -- --foundry-restore-only
"$GODOT" --headless --path . res://tests/first_hour_journey.tscn
"$GODOT" --headless --path . res://tests/ranged_fairness.tscn
"$GODOT" --headless --fixed-fps 60 --path . res://tests/enemy_contact_review.tscn
"$GODOT" --headless --fixed-fps 60 --path . res://tests/enemy_contact_review.tscn -- --forge-contact
"$GODOT" --headless --fixed-fps 60 --path . res://tests/forge_pressure_review.tscn
"$GODOT" --headless --fixed-fps 60 --path . res://tests/forge_pressure_checks.tscn
"$GODOT" --headless --path . res://tests/loot_persistence.tscn
"$GODOT" --headless --path . res://tests/loose_drop_save.tscn
"$GODOT" --headless --path . res://tests/discovery_clarity.tscn
"$GODOT" --headless --path . res://tests/discovery_sites.tscn
"$GODOT" --headless --path . res://tests/smithy_story.tscn
"$GODOT" --headless --path . res://tests/loose_drop_save.tscn -- --write-checkpoint
"$GODOT" --headless --path . res://tests/loose_drop_save.tscn -- --read-checkpoint
"$GODOT" --headless --path . res://tests/first_hour_journey.tscn -- --pickup-probe
"$GODOT" --headless --path . res://tests/first_hour_journey.tscn -- --pickup-restore
"$GODOT" --headless --path . res://tests/world_intensive.tscn
"$GODOT" --headless --path . res://tests/material_intensive.tscn
"$GODOT" --headless --path . res://tests/trial_intensive.tscn
"$GODOT" --headless --path . res://tests/strange_frontier.tscn
"$GODOT" --headless --path . res://tests/terrain_stream_intensive.tscn
"$GODOT" --headless --path . res://tests/wide_terrain_stream.tscn
"$GODOT" --headless --path . res://tests/terrain_preparation.tscn
"$GODOT" --headless --path . res://tests/trace_surface_cache.tscn
"$GODOT" --headless --path . res://tests/stream_scheduling.tscn
"$GODOT" --headless --path . res://tests/focus_scheduling.tscn
"$GODOT" --headless --path . res://tests/stream_capacity.tscn
"$GODOT" --headless --path . res://tests/world_mesh_equivalence.tscn
"$GODOT" --headless --path . res://tests/ecology_buildings.tscn
"$GODOT" --headless --path . res://tests/contraption_intensive.tscn
"$GODOT" --headless --path . res://tests/pressure_feeder_presentation.tscn
"$GODOT" --headless --path . res://tests/custom_panel_refresh.tscn
"$GODOT" --headless --path . res://tests/feeder_visuals.tscn
"$GODOT" --headless --path . res://tests/feeder_controls.tscn
"$GODOT" --headless --path . res://tests/pressure_workshop.tscn
"$GODOT" --headless --path . res://tests/strange_art_review.tscn
"$GODOT" --headless --path . res://tests/strange_frontier_review.tscn
"$GODOT" --headless --path . res://tests/cataclysm_art_review.tscn
"$GODOT" --headless --path . res://tests/environment_target_checks.tscn
"$GODOT" --headless --path . res://tests/cataclysm_actor_craft.tscn
"$GODOT" --headless --path . res://tests/augmented_beasts.tscn
"$GODOT" --headless --path . res://tests/cataclysm_intensive.tscn
"$GODOT" --headless --path . res://tests/combat_presentation.tscn
"$GODOT" --headless --path . res://tests/skill_expansion.tscn

echo "== Foundry identities and composition =="
"$GODOT" --headless --path . res://tests/foundry_mutations.tscn
for identity in offence guard sustain tempo; do
  "$GODOT" --headless --path . "res://tests/foundry_${identity}_identity.tscn"
done

echo "== main scene smoke run (120 frames) =="
"$GODOT" --headless --path . --quit-after 120

echo "All headless checks passed."
