# Dispatch-pack checks — 9 September 2026

This verifies the planning/prompt delivery only. No ART-07 production source,
runtime asset, session or GPU job is produced by this step.

| Check | Observed result |
| --- | --- |
| `session_plan.py` | PASS: 26 worker prompts, one publisher prompt, 131 current catalogue entries owned exactly once, 60 valid ordered dependency edges, 28 existing additional reading files |
| Catalogue categories | 26 shapes, 19 materials, 15 station/device appearances, 22 resource types, 33 support roles, 16 retained actor/host IDs |
| `catalogue.py` | PASS: current data/native kit mapping and dimensions; 273 legal material/shape pairings; 14 kits plus one forge upgrade |
| `verify_art.py` | PASS: six PNGs/exact prompts, six unchanged local generator copies, one edit parent, unchanged original reference and 25 current local links |
| New prompt pack links | All local targets resolve; prompt generation/freshness check passes |
| Tools and source locations | CLI/model directory, Blender, Python, Godot, grove/boar/lifeline and all four ART-04 handoff directories exist at documented local paths |
| Git whitespace/scope | Checked; only prompt/plan documentation and their verifier are selected for publication |

The CLI flags and script limitations were checked against the existing local
TRELLIS generation wrappers. Blender/native/review commands were checked against
their actual scripts and reports. Skeleton commands in PROCESS are labelled
patterns requiring slice paths/scripts; they were not run as new generation or
claimed to be working generic scripts. No package install, paid inference, game
test, native rebuild, save load or normal playtest interruption occurred.

Publication uses the owner's standing checked-main/non-force-push permission.
The resulting commit and remote push are reported separately in the planning
session's final response. Worker branch and main publication status remain
unstarted until the corresponding sessions are explicitly enacted.
