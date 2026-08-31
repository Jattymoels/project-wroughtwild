#!/bin/sh
# Runs every in-engine check headless. Requires the pinned Godot binary
# (4.5-stable); point GODOT at it, e.g.:
#   GODOT=~/godot/Godot_v4.5-stable_linux.x86_64 ./run_headless_checks.sh
set -e
GODOT="${GODOT:-godot4}"
cd "$(dirname "$0")"

echo "== import =="
"$GODOT" --headless --path . --import

echo "== unit tests =="
"$GODOT" --headless --path . --script tests/run_tests.gd

echo "== integration test (physics + placement loop) =="
"$GODOT" --headless --path . res://tests/integration.tscn

echo "== main scene smoke run (120 frames) =="
"$GODOT" --headless --path . --quit-after 120

echo "All headless checks passed."
