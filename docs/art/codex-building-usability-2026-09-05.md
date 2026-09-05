# Building usability — 5 September 2026

Owner-approved follow-through after gathering feedback. This is the second
item in the [playtest priorities](../prototype/playtest-priorities-2026-09-05.md).

## Player controls

- **B** enters or leaves building. **Tab while building** opens the visual
  catalogue; outside build mode Tab retains the earlier cycle shortcut.
- Choose a shape card, a separate material family, and optionally half-size
  basics. Categories group corners and roof transitions, walls/floors, frames,
  and furnishings/held station kits. Locked shapes remain inspectable.
- The selected shape shows its ordinary cost, carried quantity, existing hint
  and unlock/material failure. Missing material does not prevent planning a
  selection; payment happens only when placing in the world.
- Left/right buttons turn the selected oriented shape. Its large geometry
  preview and front arrow update together. **Use selection**, **Tab**, or **Esc**
  closes the picker and recaptures the mouse. **R** turns the world preview;
  doors retain their two hinge choices, surfaces/edges retain automatic alignment.
- **Q** cycles carried materials and **G** toggles existing half-size twins.
  Corners/roofs with no twin stay full size and are named accordingly.

The world preview carries the same front arrow as the catalogue. Shape images
are orthographic drawings of the actual piece mesh triangles, with neutral
shading, rather than separate icons that can drift from the geometry. Held kits
use the shared station models. The world retains its ordinary materials.

## Placement feedback and correctness

The crosshair explains a locked shape, incompatible material (with alternatives),
missing materials/kits, occupied address, buried terrain, blocking resource,
station or creature, generic obstacle, or absence of a target within reach.
Colour still distinguishes valid and invalid ghosts; text adds the next action.
The bottom build chip separates selection/cost, orientation and controls into
short lines rather than one long line.

The station-kit ghost now turns with the eventual station. Its overlap probe
also uses the displayed box centre, fixing a false floor obstruction caused by
testing the taller kit box at a cube's lower centre. Door thumbnails use a
180-degree hinge flip, matching the existing placed door rather than showing
a misleading quarter turn.

Every placement rechecks the displayed address before payment. Rapid repeated
clicks on an occupied preview and a new blocker cannot consume materials. This
does not search for a different address at click time: the visible target remains
the one being requested. No placement input passes through the catalogue.
Ordinary movement input is suppressed while selecting; the world is not paused.
Death or another asynchronously opened panel dismisses the catalogue.

No construction costs, unlocks, material traits, collision shapes, lattice
addresses, snap rules or save fields changed. The known D-018/siege demolition
conflict remains outside this UI pass. No new skill or combat rule was introduced.

## Presentation tuning

`game/art/build_ui_look.tres` exposes the defaults from its resource script:

| Parameter | Default | Effect |
| --- | --- | --- |
| panel_size | 1000 × 580 px | Catalogue working area, constrained by viewport |
| tile_size | 150 × 116 px | Shape card density and label room |
| thumbnail_colour | #b29a73 | Neutral geometry colour |
| thumbnail_view | (-0.45, 0.65, 0) radians | Shared three-quarter inspection angle |
| thumbnail_fill | 0.85 | Fraction of thumbnail space used for geometry |
| arrow_length | 0.5 m | World front marker length |
| arrow_lift | 0.08 m | Clearance above the ghost |
| arrow_colour | #eadbad | Direction marker colour in both views |

Four cards fit each row at standard desktop widths; narrower windows use three.
The catalogue and longer detail text scroll independently, with close/use controls
remaining outside the scroll areas. Verified target resolutions are 1280×720 and
1920×1080. Favourites/search, arbitrary-angle rotation and controller UI are not
part of this pass. The arrow is depth-tested and may be hidden behind geometry;
the orientation line remains available.

## Reproduction

`tools/codex_visual_review.ps1 -BuildPicker` runs the dedicated interaction checks
and captures the normal player catalogue over the existing modular workshop.
The review supplies building materials and the existing roof unlock; it does not
alter a user save. `-Checks` also includes the dedicated check scene.

Checks cover real card selection, material choices, costs, fine twins, locked
roofs, category contents, four-way orientation, door/surface behaviour through
the existing construction suite, menu isolation, 720p/1080p layout, blocker
messages, stale-preview payment protection and saved corner orientation.

Validation completed: 39 dedicated building-interface checks passed, as did
the full engine headless regression pipeline. The rendered workshop review
passed 801 checks including capture exports. Final catalogue images were
inspected at both 720p and 1080p. Existing unit-harness engine warnings remain;
native rules code and tuning JSON were unchanged, so no native rebuild was needed.
