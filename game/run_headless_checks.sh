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
"$GODOT" --headless --path . res://tests/integration.tscn

echo "== horde test (D-012 chase, training, cone, dash) =="
"$GODOT" --headless --path . res://tests/horde.tscn

echo "== grammar test (frost orb fork, freeze breakpoints, shatter cascade) =="
"$GODOT" --headless --path . res://tests/grammar.tscn

echo "== feel test (pickup magnet, harvest feedback, jump buffer) =="
"$GODOT" --headless --path . res://tests/feel.tscn

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

echo "== main scene smoke run (120 frames) =="
"$GODOT" --headless --path . --quit-after 120

echo "All headless checks passed."
