# Foundry: finish every existing input

**Owner approved, 6 September 2026:** “Lets do it then - cover all inputs”,
following the confirmed Cinder Wake / Afterimage identity gap. This continues
D-025 and supersedes the remaining-family deferral. All 72 missing roles are
implemented; coverage counts alone do not establish enjoyable play.

## Outcome and scope

Finish the nine outstanding Kind families: 72 individual ingot readings alongside
the 24 completed Ember, Frost and Preserving readings. Retain the twelve Kinds,
eight ingots, three alloys, catalyst-grade aliases and sixteen skill shells.
No new currency, skill, plate geometry, progression gate or equipment pool.
Owned pieces, coordinates, grade identity and earned mastery remain intact.
Existing layouts acquire the revised derived behaviour on next launch/load.

Direct ingots remain straightforward additions. An individual mutation changes
a trigger, spatial relationship, timing, target choice or recovery obligation.
Distinct colours or subsidiary stat bonuses alone do not complete a reading.
Keep early damage modest and let the chosen skill supply the original action.
Piercing retains its accepted travelling-melee capability; Impact now makes
authored contact events while preserving the original delivery.

## Implementation slices

1. Author every missing reading, including its actual combat role, description,
   limits, visual tell and focused behavioural fixture.
2. Integrate four bounded event groups for passage/impact, defence, sustain and
   tempo. Simulation resolves numbers and capability scaling; Godot owns spatial
   recipients, actual contact, time and cover.
3. Verify all base inputs, legal alloy/grade aliases, skill compatibility and
   composition. Compare actual events and prerequisites, not just distinct IDs.
4. Run native and engine regressions, review representative same-skill builds,
   and record remaining balance or presentation limitations honestly.

## Composition and compatibility

Separate operations coexist with their own gates and a bounded live-node budget.
Repeated identical investments reinforce that operation within its numeric cap;
they do not produce unlimited extra copies. Existing explicit ordered evolutions
(including consuming Steam Plume) remain. Other ordered Kind pairs compose their
individual operations deterministically; this does not claim a bespoke new recipe
for every permutation or every possible board.

Striking Quicksilver remains attack-specific and Casting Quicksilver remains
spell-specific. Movement can perform positional/cast mechanics but cannot invent
a damaging contact or hit packet. Incompatible inputs must be explained in the
inspector. Ordinary direct ingot effects continue independently.

New secondary events are terminal: no mastery, linked cast, further mutation,
duplicate recovery or recursive echo. Contact-dependent sustain and tempo read
pre-hit ailments but require actual positive direct hostile damage. Enemy damage
reactions require a real positive post-mitigation hit; environmental damage and
dodges cannot pay them. Charges expire, die with the player and clear on save
application. Safe trial suspension retains its established clear-boundary contract.

All new numbers live in `foundry.json` with a plain-language purpose. Read-only
`items.json` modifiers stay outside random loot pools. No external package or
asset service is involved.

## Acceptance

- Every base pair has a concrete distinct role and an accurate description.
- Cinder Wake and Afterimage produce visibly and mechanically different events
  on the same melee skill, including when both are installed.
- Supported deliveries, alloys and grades resolve correctly. Branches, shared
  supports, repeated Kinds, ordered evolutions and previews preserve ownership.
- Runtime fixtures exercise each of the 72 new roles and their prerequisites;
  representative cover, expiry, boss and duplicate-event checks pass.
- Existing 24 roles, typed gear scaling, save identities and economy remain valid.
- Human enjoyment and final balance remain playtest judgements, reported separately
  from automated operation checks.

## Implemented result and verification

The role tables are in the [system specification](../systems/foundry-mutations.md),
[defence](foundry-guard-identities-2026-09-06.md),
[sustain](foundry-sustain-identities-2026-09-06.md) and
[tempo](foundry-tempo-identities-2026-09-06.md). The existing Foundry inspector now
shows each resolved form's full description, including the action that earns it.
Cinder Wake needs a positive contact and movement to draw its fire seam;
Afterimage requires recasting the same skill from elsewhere to discharge at the
old position. Both can coexist on Heavy Strike.

Native verification passes **195,279 checks, zero failures**, including:

- 4,608 base Kind/ingot/alloy/skill combinations and 13,824 grade aliases;
- 55,296 ordered-pair/alloy/skill combinations;
- 36 exact graded place/save/lift lifecycles;
- 72 duplicate, ceiling, scope and route-loss cases;
- 336 typed-packet and 79 compatible buildup-scaling fixtures.

The four new runtime suites pass 104 passage/impact, 385 guard, 273 sustain and
324 tempo checks. They include expired collection, corpse cover, positive direct
damage versus shatter-cascade attribution, and nearest-ward charge ownership.
The retained Foundry runtime suite passes 452 checks. Trial lifecycle passes
6,193 checks, including transient cleanup at entry and refusal to suspend with
fresh unrepresented effects at the boundary. Broader engine checks pass:
integration 268, grammar 72, feel 17, horde 43, skill expansion 64 and forge
progression 35. The engine unit fixture passes 398 assertions, with no engine
errors. Its invalid-input cases still deliberately emit native warnings. The
verification pass also corrected the bare pack system's unattached-tree check
and freed two fixture-owned cover nodes so engine errors can fail the runner.

Nine actual-renderer captures pass 70 checks, using legal committed plates,
real skill casts and deterministic enemy state. They show Cinder Wake,
Afterimage, both routes together, Frost Refrain and Wide Echo. The output lives
under `build/foundry-identity/captures`, with a gameplay manifest. These are
scripted inspection frames with controlled positions and elapsed clocks, not
an unscripted fight or a difficulty-calibration recording.
The existing 22-capture Foundry presentation review also completes with an empty
error log. The local `build/foundry-identity/index.html` gallery contains the nine
new frames and a searchable catalogue of all 96 canonical forms.
That first-person review also exposed an opaque Rime Veil band across aim.
Defensive ring meshes are now thin and translucent, controlled by documented
height-ratio and opacity limits; the interception volume is unchanged. The
22-capture review and 385 defensive assertions pass after this correction.
Older spawn-relative capture staging still overlaps some terrain and rocks;
those frames establish compatibility rather than finished encounter composition.

The final combined run repeated all four new suites, the retained Foundry suite,
integration, grammar and trial lifecycle after the expiry and direct-attribution
fixes; all passed. The isolated final renderer repeated its 70 checks and nine
captures. The verified native DLL was installed for the next normal launch,
retaining the prior DLL in ignored build output without stopping the running game.

## Reproducing the checks

Build the native extension using the existing instructions in `game/README.md`.
The ordinary runners now include all four new identity scenes:
`tools/codex_visual_review.ps1 -Checks`, `-Foundry`, and
`game/run_headless_checks.sh`. `-Foundry` also runs the new rendered comparison.

For isolated Windows checks without touching normal saves:

```powershell
& tools/foundry_identity_checks.ps1 -Prepare -Import
& tools/foundry_identity_checks.ps1 -Scene foundry_offence_identity
& tools/foundry_identity_checks.ps1 -Scene foundry_guard_identity
& tools/foundry_identity_checks.ps1 -Scene foundry_sustain_identity
& tools/foundry_identity_checks.ps1 -Scene foundry_tempo_identity
& tools/foundry_identity_checks.ps1 -Scene trial_intensive
& tools/foundry_identity_checks.ps1 -Rendered -Scene foundry_identity_review
```

Preparation copies game content and tuning into `build/foundry-identity/review`,
uses a separate review user directory and preserves its existing review DLL.
On first preparation it copies the built game DLL; supply `-NativeLibrary` to
explicitly refresh it from another compiled DLL. Logs, captures, binaries and
review saves remain ignored build output. Each invocation owns only its own
hidden process and timeout; it never closes an existing game or editor.

## Remaining judgement

All current base inputs have authored operations; ordered pairs normally compose
those operations and only existing explicit evolutions consume them. This does
not add a bespoke transformation for every possible plate. Final numerical
balance, readability in a crowded normal fight and the fun of each obligation
still need the owner's playtest. The pass uses bounded primitive effects and
existing art, leaving the eventual graphical finish separate.
