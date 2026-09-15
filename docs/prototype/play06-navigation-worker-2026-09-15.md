# PLAY-06: bearings and optional coordinates

Prepared after the owner's direction/coordinate question and request for the
next slice, under standing prototype approval. The owner starts this worker.

Workspace: `D:/Wroughtwild/work/play06-navigation`.
Branch: `codex/play06-navigation`. Read `build/play06/SETUP.md` for the exact base
and inherited native runtime. Preserve RF-05 and both mob-arrival corrections.

## Player outcome

The owner could not use coordinate-based lake directions: H shows seed/profile,
but there is no compass or live player position. Add a small navigation display:

- A discreet compass, visible by default, showing the current viewing bearing
  with cardinal/intermediate directions. Fit the existing earth/parchment/ink HUD.
- Optional live coordinates, off by default, enabled through existing
  **H -> Display -> Show coordinates**. Label horizontal **X**, **Z** and vertical
  **Y / height** in metres. Show actual player position, not camera offset or chunks.
- **Show compass** beside that option. Store both through the existing
  PlayerPreferences/settings definitions. Missing/malformed values and Reset use
  the stated defaults. Preserve other preferences; add no world-save fields.
- Brief Help text explains these options and the convention: north -Z, east +X,
  south +Z, west -X; Y increases upward. Future lake/home directions become usable.

Heading follows viewing yaw in both existing camera modes. Pitch must not flip
the bearing; handle the north wrap and near-vertical look consistently. Coordinates
update during walking, swimming and underground movement, including negative
values. In a trial, label positions **Trial** local coordinates and hide the
geographic compass for this slice. Do not imply those are overworld coordinates.
Hide navigation before a world exists. Continue and trial return read the actual
current player/context, with no cached initial spawn position.

The display never intercepts the mouse or adds a new modal/input action. Use
existing settings controls and binding-aware Help prompts; retain the separate
damage-direction cue. Do not cover the crosshair, target/work text, damage tells,
life/action bar or status/holdings. Select an unobstructed compact placement;
reuse existing layout/refresh facilities without redesigning the whole HUD.

No minimap, map screen, fog of war, waypoints, auto-navigation, quest guidance,
home/death markers, fast travel, compass item or progression gate. Read existing
transforms/context; do not add terrain queries, actor scanning, world generation,
native simulation changes or per-frame resource loading. No external assets.

## Reading and implementation

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and its required
reading order. Then read `docs/systems/interface.md` and relevant parts of
`docs/prototype/controls-comfort-2026-09-08.md`. D-008/D-012/D-013 and INT-08A's
preference/input contracts apply. D-015's four interface layers remain: this is
a HUD/help addition, not the excluded minimap. Current prototype guidance replaces
the old controls-review matrices.

Inspected starting points:

- `game/scripts/hud.gd`: CanvasLayer, UiTheme, refresh cadence, Help text and
  input-ignoring HUD. Choose a placement that preserves current readability.
- `game/scripts/comfort_controls.gd`, `player_preferences.gd`, `game/settings.json`:
  Display checkboxes and validated saved defaults already exist. Reuse them.
- `game/scripts/world_seed_controls.gd`: preserve H's WorldIdentity and ordinary
  New World/Continue flows; identity is distinct from live player position.
- `game/scripts/player.gd`: active camera/player transforms and trial context.
  Preserve normal mouse capture, movement and RF-05 swimming.

Implement the smallest complete behavior. Update the interface specification with
delivered controls/defaults and document display/format choices. Use engine UI
primitives. A native rebuild or further art production is unnecessary.

## Focused checks and delivery

Concrete risks: wrong bearings/coordinates, settings/modal-input regressions,
HUD overlap and stale state after world/trial transitions. Default to two jobs:

1. One headless HUD/preferences interaction check: actual view turns and negative/
   live positions, actual settings control/save/reset, fresh preference read and
   relevant world/trial context. Assert unchanged player/native ownership. Cover
   these integration boundaries, not a matrix of formatting helper tests.
2. One short Forward+ ordinary-world look/move/settings check at 1280x720. Show
   default compass and enabled-coordinate views, confirm no important overlap,
   and retain one or two real HUD images. No full campaign or performance benchmark.

Reuse current save/gameplay evidence. Use the verified `--r8-no-mouse-capture`
option, BOM-free no-focus override and `Local\WroughtwildArtRender` mutex; never
move the desktop pointer. Adapt an existing focused runner, keep private saves,
logs/imports on D:, and end owned jobs. Extra focused checks require a concrete
change/failure. No camera/renderer/resolution matrix or renewed art review.

Write `docs/prototype/play06-navigation-result-2026-09-15.md`: actual gameplay,
controls/defaults, limitations, checks, playtest steps and commit/DLL status.
Show actual HUD pictures directly in chat using absolute paths. For `.ps1` play
instructions use process-scoped `powershell.exe -NoProfile -ExecutionPolicy Bypass
-File "<absolute path>"`; do not change persistent policy or launch the game
automatically. Preserve owner saves and disclose any private playtest slot.

Commit the checked slice on this branch; give its SHA for coordinator integration
and push. Stop after PLAY-06. R9 stays stopped.
