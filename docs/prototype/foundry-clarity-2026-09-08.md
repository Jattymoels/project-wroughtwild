# INT-01B — Read the flow and understand progression

Status: **Implemented, owner review pending.** Baseline: `6937405`.
Owner: Matty. Delivery: Codex.
The owner's “Let's continue” selects the next bounded slice after INT-04C in
the [playtest plan](playtest-iterations-2026-09-07.md).

## Outcome and small plan

Make CURRENT FLOW readable while preserving the plate, right-hand workings,
native effects, previews and exact costs. Record short/shared and long/branching
routes in isolated baseline/current copies at 1280×720, 1920×1080 and the two
supplied image sizes (2307×1345 and 3453×1789). The owner's exact arrangement
is unknown; these are representative legal layouts, not a recovered save.

Provide a concise current/preview summary and intentional full detail with
independent scrolling, sufficient contrast and readable text. Verify pointer
and keyboard inspection, no spend while browsing, placement/refusal and native
effect equivalence. Keep the useful workings column and existing mutation rules.

Explain automatic mastery practice, the one-time post-Tyrant specialisation,
and freely set/cleared rail patterns in their existing panels. Specialisation
must show its changes and permanence before committing. Native conditions and
limits remain authoritative; this slice adds no perk-choice or currency system.

Affected: FoundryPanel, its route overlay if responsive geometry requires it,
the pack's skill/progression guide and bounded class/help wording. D-004,
D-023, D-025 and D-026 govern behaviour. No combat/mastery tuning, save schema,
geography, resource, production or progression changes are selected. Presentation
sizes may be adjusted and documented after baseline inspection. No material
design question blocks this bounded presentation work.

Use copied projects, separate APPDATA and owned hidden processes under ignored
`build/foundry-clarity/`. Preserve ordinary saves and running playtests. Finish
and check INT-01B, update queue/specs, then commit and push through the standing
main workflow. INT-05B stays outside this slice; comprehension remains a human
review after functional and rendered checks.

## Reproduction and implementation

The unchanged baseline reproduced a cramped inspector in all eight matched
cases: a shared Kind route feeding two skills, and a branched Frost/Preserving
route, each at 1280×720, 1920×1080, 2307×1345 and 3453×1789. The body stayed
536×88 pixels at every resolution. Its current text required 437 pixels for
the shared reading and 1,196 for the branch. The initial visible portion was
largely role metadata, leaving the consequence below the fold. Body type was
already 16 pixels; reducing introductory text and allocating reading space
address the reproduced issue. The baseline fixture failed all eight minimum
reading-space checks while passing its other native/layout assertions.

The inspector now defaults to CURRENT FLOW with cell coordinates, each named
form and every receiving skill. A single description appears once; several
forms offer their complete descriptions through Details. AFTER PLACEMENT and
PLACEMENT REFUSED explicitly identify hypothetical results and no spend. Native
current readings, native effect descriptions, lifting cost and the original
placement/lifting transactions remain available. The fixed instruction line
keeps the cost visible even when the body is scrolled.

The body has opaque Ink backing, 16-pixel text, wrapping and its own scrollbar.
Right-click pins a cell while moving across the plate to read Details; Pin
reading also toggles this state. Hover and keyboard focus inspect other cells
when unpinned. A changed selection resets the disclosure. The complete plate,
its outer rails, close/help controls and useful right-hand workings remain
visible. Route arrows adapt to compact cells and retain branch paths before
deduplicating repeated descriptions.

| Matched reading | Baseline body / text height | Current body at 720p / taller sizes | Current summary height |
| --- | --- | --- | --- |
| Shared, two skills | 88 / 437 px | 144 / 240 px | 92 px |
| Branched, four forms | 88 / 1,196 px | 144 / 240 px | 161 px |

The long summary still needs a small scroll at 720p; complete multi-form prose
intentionally needs more scrolling in Details. No claim that every reading
fits without scrolling is made. The whole Foundry measures 1,048×682 at 720p
and 1,048×862 on the tested taller displays.

Progression wording now distinguishes three existing systems:

- Skills gain mastery automatically through qualifying practice. The guide
  names the next native milestone and explains empty casts, automatic repeats
  and secondary ticks. The pack's mastery disclosure uses the same distinction.
  Learned tablets can be laid before mastering them; no new prerequisite exists.
- Each class has its two native post-Tyrant specialisations. Compare opens the
  selected choice's unchanged conditions and current/grown rule descriptions,
  scrolled into view. Choose **[name] permanently** is a separate action after
  that explanation; Keep comparing spends nothing. All six choices are covered.
- Rail patterns can be set and cleared freely within the native era/uniqueness
  limits. The line must hold. A chosen specialisation grows existing patterns
  without applying every pattern globally.

The longer class introduction exposed a 720p chooser overflow. Its existing
choices now scroll below the fixed introduction, with all three class actions
reachable. This is presentation only; initial class, mastery, rail and
specialisation domain rules are unchanged.

## Presentation values

These are panel geometry and existing palette values, not gameplay tuning.
They follow the existing code-built UI theme and panel layout conventions.

| Location / value | Purpose |
| --- | --- |
| Foundry cells: 56–76 px high; `(height − 496) / 4` | Reserve readable inspection space at 720p while retaining all four plate rows. |
| Inspector: 144–240 px high; `height − 576`, width 536; font 16 | Grow the reading area on taller displays without shrinking text or hiding the plate. |
| Workings scroll: `min(740, height − 160)` px | Use spare height for the existing right-hand content, keeping panel controls reachable. |
| Inspector: Ink backing, Muted border at 0.6 alpha, radius 5 | Separate the reading from the world behind the panel using the existing palette. |
| Flow arrow: central 12 px of each neighbour gap | Keep responsive route arrows clear of cell names. |
| Class choice scroll: `min(620, height − 190)` px | Keep the introductory choice/permanence explanation outside scrollable class descriptions. |

## Checks and evidence

Copied game/data, separate APPDATA, hidden owned processes and Dummy audio were
used throughout under ignored `build/foundry-clarity/`. The normal save and any
running playtest were not loaded or stopped. The preserved baseline copy is
still available. No native library, tuning table or save schema changed; this
slice does not claim a native rebuild.

| Check | Result |
| --- | --- |
| Baseline `foundry_flow_review`, rendered | 67 checks, 8 expected reading-space failures. |
| Current `foundry_flow_review`, rendered | 67 passed: eight matched layouts, exact native state/effects, retained destinations, readable body and unobstructed plate/workings. |
| Current `foundry_clarity`, rendered | 334 passed: actual hover/focus, right-click pin, disclosure, independent wheel scrolling, free previews, exact placement/paid lift, refused lift, six comparisons/cancellations/confirmations, actual rail controls and broken-line conditions, guide controls, 720p/1080p captures. |
| Final headless `foundry_clarity`, `foundry_flow_review` | 315 / 59 passed. |
| `foundry_clarity --foundry-restore-only` | 28 passed in a fresh process after the final control run. |
| `run_tests` | 398 passed; expected malformed-save warning from its negative case. |
| `integration` | 273 passed. |
| `foundry_mutations` | 452 passed. |
| `skill_expansion`, `forge_progression` | 64 / 58 passed, including the existing combat eligibility checks for meaningful mastery practice. |
| `panel_density`, `establishment_guide` | 60 / 138 passed. Refusal retains its original current-reading assertion after opening the new intentional Details disclosure. |

Six saves, one per specialisation, contain a holding grown rail and an earned
native Frost Orb milestone. The separate restart run compares the entire native
export and effect list exactly after SaveManager restoration, including owned
materials, skills, mastery and rails. UI confirmation is checked against a
separate native simulation loaded from the exact pre-choice state. Breaking
each class's representative line removes its conditional benefit and retains
the native “Not lit” explanation; clearing/setting a rail is free.

Local evidence:

- `build/foundry-clarity/{baseline,current}/captures/flow/`: eight PNGs per copy
  and `flow-review.json` with exact text, geometry, route count and measurements.
- `build/foundry-clarity/current/captures/clarity/`: inspector detail, valid and
  refused previews, all six comparisons at 720p/1080p, class chooser and guides.
- `build/foundry-clarity/logs/{baseline,current}/`: bounded process results.
- `build/foundry-clarity/appdata/current/`: isolated review saves only.

```powershell
./tools/home_review.ps1 -ReviewSet foundry-clarity -Phase current -Prepare -Import -Scenes foundry_flow_review,foundry_clarity -Rendered
./tools/home_review.ps1 -ReviewSet foundry-clarity -Phase current -Scenes foundry_clarity -ExtraArguments '--foundry-restore-only'
./tools/home_review.ps1 -ReviewSet foundry-clarity -Phase current -Scenes foundry_clarity,foundry_flow_review,integration,foundry_mutations,skill_expansion,panel_density,establishment_guide,forge_progression -Scripts run_tests
```

The two new focused scenes and fresh-process restore are also listed in the
existing headless runner. Representative rendered outputs were visually
inspected; no owner playtest was needed to reproduce or check this slice.

## Limits and publication boundary

The owner's exact Foundry layout and intended “mastery” screen remain unknown.
These are representative legal arrangements with supplied review stock and
milestones, not a reconstruction of the owner's save or a balance/acquisition
test. Native practice was supplied for persistence coverage; the existing
combat suite independently verifies which actions can award it. Comprehension
and visual comfort in ordinary play remain owner review, including unusually
dense future layouts. Displays below 1280×720 were not targeted by this slice.

No damage/sustain tuning, encounter pressure, generator profile, resource,
geography or save-rule change is included. The timber-demolition conflict and
earlier equipment-preview limitation remain outside scope. INT-01B is the only
slice delivered here; INT-05B is next in the queue and has not begun. Commit
and ordinary push outcomes are reported separately after publication checks.
