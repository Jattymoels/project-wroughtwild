# Loose material drops at the save boundary

Status: **Reproduced; reliability fix not implemented.** INT-07 follow-up found
during the approved [first-hour checks](first-hour-clarity-plan-2026-09-07.md).
This is a pre-existing save issue, not an intended reward rule or a consequence
of the interface changes.

## Evidence

The isolated V6 seed-77 fixture used an ordinary generated tree, contextual
work, physical drops, normal pickup absorption and SaveManager. No stock was
injected. Two separate processes exercised these cases:

| Case | Observed result |
| --- | --- |
| Capture before harvest; finish the tree without collecting; apply that earlier save; harvest again and collect | One 14-wood yield became 28 carried wood. The earlier loose drop survived restoration of the resource. |
| Write after releasing the 14-wood drop, before collection; restart the process and read that exact save | Zero carried wood and zero loose drops. The saved source was depleted; its released yield was absent. |

Evidence: `build/first-hour/logs/pickup-reload.out.log` and
`build/first-hour/logs/pickup-restart.out.log`. The diagnostic's successful checks
establish its preconditions and save operations; they do **not** endorse these
outcomes as passing persistence behaviour. The normal collected-material journey
separately verifies partial work, unplaced kits and stored resources.

## Next bounded reliability slice

Define and implement consistent loose-material ownership across save/restore.
The proposed direction is to save each uncollected amount with its remaining
lifetime and relevant motion state, validate the full payload before mutation,
then replace the live drop set during restoration. Loading must never combine
pre-load drops with restored source stock. Preserve finite sources, pickup
capacity and ordinary expiry; do not turn drops into automatic collection.

Before implementation, settle compatibility for old saves without drop records
and the interaction with gear/page drops, open-world death and trial suspension.
Those cases need explicit checks; this audit does not silently select new
persistence rules for them. Keep atomic save/last-good-file behaviour.

For current play, **collect freed materials before saving or loading**. This
avoids the reproduced loose-drop boundary; it is not a substitute for the fix.
