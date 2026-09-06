# Loose material drops at the save boundary

Status: **Resolved by [INT-07A](loose-drop-persistence-2026-09-07.md).** INT-07 follow-up found
during the approved [first-hour checks](first-hour-clarity-plan-2026-09-07.md).
This is a pre-existing save issue, not an intended reward rule or a consequence
of the interface changes.

## Original evidence before the fix

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

## Bounded reliability follow-up

The audit proposed saving each uncollected amount with its remaining lifetime
and motion state, validating the full payload before mutation, then replacing
the live drop set. Finite sources, pickup capacity, ordinary expiry and atomic
save replacement were to remain unchanged. Compatibility with older files,
gear/pages, death and suspension was left for the implementation work item.

The implemented follow-up records all existing physical reward kinds and death
packs, validates before import and replaces the world's saved set. Both original
cases are now regression assertions in `first_hour_journey`'s separate-process
pickup probes. Current passing evidence and compatibility details are in the
linked work item. Older files cannot recover yields that were never recorded.
