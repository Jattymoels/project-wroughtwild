# Interface and In-Game Experience

**INT-02A continuation, 7 September 2026:** the existing Source/use entry now
covers the five rare wild components as well as early materials. Native use
previews and recipe consumers supply the payoff and navigation. During work,
the compact progress line uses the saved resource's native harvest stages;
required presses, yield, refusal and wedge rules retain authority. Looking at
an existing smithy wall gives one neutral observation about the abandoned
hearth and accidental impact, without an E prompt, highlight or lore panel.
[Scope and evidence](../prototype/exploration-storytelling-2026-09-07.md).

**Implemented INT-01 update, 7 September 2026:** the pack's **Guides** button
opens optional **Getting established** ambitions for a first home, working
stone and setting up a forge. Each shows one next step using current native
requirements and links to the existing recipe or building controls. Skills,
Kinds, Progression/Foundry and Wild finds remain separate reachable pages.
Twelve early material, tool and station-kit entries share source/work/use
information between pack tiles and recipe ingredients. These explain physical
collection, carried versus stored stock, refinement and placing a crafted kit;
they add no objectives, rewards or gates.

Recipe **Make** pins retain the chosen batch, workpiece grade and Kind/potency
for the session. Their requirements refresh from the corresponding native
preview, including fuel after ingredient reservation. Ingredient Back restores
the parent selection and operation. References do not permit work at a remote
station, and browsing or pinning does not spend anything.

Primary views lead with the action, current effect and immediate requirements.
Long explanations, roll bands, mastery lists and debug information use explicit
**Details** controls instead of dense default text or hover essays. Current gear
modifier sentences, selected Foundry effects, costs, refusals and action risks
remain visible where the player makes the decision. The pack and guide wrap and
scroll within 1280×720 and 1920×1080 views; expanded details keep navigation and
Close reachable. These presentation changes add no costs, gameplay gates or save
fields. This update supersedes earlier guide/navigation descriptions below;
the original interface history is retained. See the
[INT-01 implementation record](../prototype/first-hour-clarity-plan-2026-09-07.md).

Owner-approved D-032, 6 September 2026: the initial class chooser shares its
existing decision with a random or chosen new-world seed and Continue for the
saved world/suspended trial. Generation waits for that choice so Continue does
not build a disposable world first. Seeds accept whole numbers from 0 through
2,147,483,647; invalid input keeps launch disabled. Continue validates saved
identity and finite stock before importing the player. Existing Help (`H`)
shows the active seed/profile. No persistent seed overlay or separate startup
screen is added. The chooser scrolls within the viewport when its content is
tall. [Implementation and review](../prototype/wide-frontier-intensive-2026-09-06.md).

Owner playtest update, 6 September 2026: crafting cards are limited to the current station family and hand work, with native-ready recipes first. Locked local progression remains visible; Improved Forge cards also retain its existing higher-grade wooden equipment work. Explicit ingredient references keep their back path and destination station. See the [station catalogue implementation](../prototype/crafting-catalogue-station-pass-2026-09-06.md).

Owner-approved update, 6 September 2026 (D-026): Ordinary crafting now follows the building catalogue: category/search cards, selected details, grade inspection and a fixed cost/Make footer. Ingredient navigation preserves a back path; a recipe can be pinned during play. Kinds and potency are selected explicitly; exhaustive roll bands remain inspectable. See the [forge implementation record](../prototype/forge-clarity-and-early-pacing-2026-09-06.md#implemented-outcome--6-september-2026) for tuning, sources and save compatibility.

**Status:** Proposed (Wave 2 kickoff, 1 September 2026) — awaiting owner review as D-015; first slice implemented  
**Owner:** Unassigned  
**Related decisions:** D-008 (mouse and keyboard), D-012 (first person), D-013 (art direction), D-015 (proposed)  
**Related documents:** [items-and-modifiers.md](items-and-modifiers.md), [art/art-direction.md](../art/art-direction.md)

## Purpose and player fantasy

The interface is the **test instrument** for everything Wave 2 adds: if a
tester cannot see what they hold, wear, and have active, itemisation cannot
be judged. In first person the world is the primary interface (D-012: the
crosshair reads the target, harvestables glow, statuses are silhouettes), so
overlays stay minimal, consistent and instantly legible. Owner's complaint
that started this spec (1 Sep 2026): "inventory, action bars, crafting
pop-ups are all quite difficult to test with".

## Prototype scope

Four layers, nothing else:

1. **HUD** (always on, never takes the mouse): life bar with armour and
   resistance; the **action bar** (skills with key caps and cooldown
   sweeps, plus the build-mode chip); a right-aligned **holdings strip**
   (non-zero materials and currency); notices and the pickup ticker; the
   crosshair and target line; a one-line "H help · I pack" reminder.
2. **Pack screen** (`I`): materials and currency as tiles, what is worn per
   slot with its properties, derived vitals, and the active modifier set
   (spike mods as toggles until gear carries them). Wear armour from here.
3. **Work panels** (stations, order board, trial doors and offers): one
   panel type, rows as cards — what it is, what it needs with have/need
   coloured, one button — inside a scroll area so long forges never push the
   close button off screen.
4. **Help overlay** (`H`): the full control list, replacing the permanent
   hint paragraph that used to sit over the top-left of the view.

Excluded: controller (D-008), drag-and-drop, hotbar re-binding, minimap,
quest log (no quests: D-011), diegetic 3D inventory props.

## Inputs and outputs

| Inputs | Outputs |
| --- | --- |
| Sim views (`inventory`, `currency`, `equipment`, `derived_stats`, `skill_mod*`, `recipe`, `station`, `order`, `trial_*`) | Nothing computed: panels only *show* what the rules say and route buttons back into the sim |
| Player state that the engine owns (cooldown timers, build selection, life) | Cooldown sweeps, build chip, life bar |
| Keys `I`, `H`, `Esc`, panel buttons | Open/close, sim calls, mouse capture changes |

## Rules and state transitions

1. **Mouse is captured unless a panel that needs it is open.** Opening the
   pack screen or a work panel releases it; closing any panel recaptures.
   The HUD never has a mouse-stopping control (the 1 Sep bug: a spacer
   swallowed mouse look).
2. **One panel at a time.** `Esc` closes the top-most; `I` while a work panel
   is open does nothing; a station interaction closes the pack screen first.
3. **Panels never compute a rule.** Every number, availability flag and
   failure reason comes from a sim view; a button calls one sim method.
4. **Every panel is a headless test surface:** `open_*`, `close_panel`,
   `is_open`, `refresh` and each action are plain methods the integration
   test drives without input events.
5. **Colour carries meaning, consistently:** grass-light = ready / affordable
   / positive; cinder red = missing / cannot; ember = danger and warnings;
   frost = cold and information; iron rust = currency and crafting.
6. **Scale, not scroll, for the HUD; scroll, not overflow, for panels.**
7. **The active building tool owns X.** In build mode it removes the aimed
   piece with the existing refund, even when a horn is carried. A miss never
   sounds the horn. Outside build mode X blows a carried horn. Interactive
   panels block either action (owner-reported conflict fixed 5 Sep 2026).
8. **Landed damage has a bearing, when known.** A brief arc around the
   crosshair points toward the incoming hit (rear is below). It remembers
   the hit rather than tracking a live enemy; camera turns reorient it.
   Non-directional damage uses a faint ring. See the
   [combat presentation pass](../art/codex-combat-presentation-2026-09-05.md).

## Layout

```
┌───────────────────────────────────────────────────────────────┐
│ Blacksmithing 2 (60/125)            wood 12 · stone 3 · iron 2 │
│ notice line                                                    │
│ +3 wood · +1 iron ore                                          │
│ H help · I pack                                                │
│                                                                │
│                            +                                   │
│                     wood ×12 — E to gather                     │
│                                                                │
│ ▮▮▮▮▮▮▮▮▮▯▯ Life 34/40 · armour 20 · fire 25%                  │
│              [1 Area] [2 Heavy] [3 Orb] [⇧ Dash]  B Wall Panel │
└───────────────────────────────────────────────────────────────┘
```

The pack screen and work panels are centred cards over a darkened ground,
never full-screen: the world stays visible so the player keeps their
bearings (first-person disorientation is a real cost of every full-screen
menu).

## Theme

One `Theme` built in code from the master palette
(`ui_theme.gd`): ink ground `#1A1714` at 92%, ash cards `#342E2E`,
parchment text `#F2E6CC`, muted `#B8AC98`; the meaning colours above are
palette tokens (`meadow_grass_light`, `cinder_red`, `ember`, `frost`,
`iron_rust`). Material tiles take their swatch from the family
(bark for wood, stone, iron rust for ore, frost for kits, ember for
catalysts, sun-warm for currency). Default font, sizes 13–22.

## Tunable parameters

| Parameter | Meaning | Expected player effect | Initial test value |
| --- | --- | --- | --- |
| HUD refresh interval | how often labels re-read the sim | responsiveness vs cost | 0.1 s |
| Notice duration | how long a notice stays | readability vs clutter | 3 s |
| Pickup ticker window | aggregation window for absorbed drops | one line instead of spam | 2.4 s |
| Panel max height | scroll threshold | long forges stay usable | 60% of viewport |

## Feedback and interface

Building usability continuation, 5 Sep 2026: the building selection panel uses
the existing work-panel style. Tab opens it while building; shape cards and
material selection are separate, the detail view rotates the real piece geometry,
and close/use recaptures the mouse. Long catalogues and details scroll without
moving the close/use buttons. The crosshair adds specific placement refusals;
the build chip separates cost, orientation and controls. See the
[building UI report](../art/codex-building-usability-2026-09-05.md).

Owner-prioritised gathering pass, 5 Sep 2026: a compact meter below the target
line reads each resource's existing work count and next yield. It hides on target
loss, depletion, digging, build mode, death and open panels. Successful work has
a hand gesture and brief material flakes at the ray hit; refusals retain their
explanation without success effects. A completion notice distinguishes freed
drops from collected inventory; the pickup ticker includes the actual carried
total after absorption. Presentation tuning and verification are in the
[playtest work list](../prototype/playtest-priorities-2026-09-05.md).

This *is* the feedback spec; the rule is that every state a tester might ask
about — "what do I have, what am I wearing, what is active, what can I make
and why not" — is answerable from one screen without scrolling the HUD.

## Failure cases and exploits

- A panel that takes the mouse but forgets to release it on close: covered
  by the `closed` signal → recapture path, tested.
- A HUD control that intercepts input under the captured cursor: every HUD
  control is set to ignore the mouse recursively after build.
- Text-only panels that overflow (the forge with tempering rows): scroll.
- Colour as the only signal: every colour state also has text
  ("have 0" in red, "ready" under a bright slot).

## Acceptance criteria

- [x] Aiming at any world object never affects mouse look or clicks.
- [x] Skill readiness and cooldowns are visible without reading text.
- [x] The pack screen shows materials, currency, worn gear and active mods;
      armour can be worn from it.
- [x] A forge panel with every row available fits on a 720p window with the
      close button reachable.
- [x] Every panel is driven headless by the integration test.
- [x] Wave 2: item cards with rarity colour and per-modifier sentences; a
      compare view against the worn item.

Owner-approved comparison continuation, 5 Sep 2026: each carried equipment card
offers Compare. Current and candidate item cards sit beside each other, followed
by life, armour, resistances, area bonus and changes to known skills' hit payload,
cooldown, reach, projectile count and pierce. The native view uses a copied
equipment set and the existing stat/modifier functions; previewing never changes
inventory or saves. Payload excludes enemy defence, critical rolls and temporary
trial boons, and is explicitly not DPS. Conditional effects remain item-card
sentences. Equip candidate is a separate action, revalidates the item, and returns
the previous equipment through the existing pack rule. Back/close retain mouse
capture behaviour; scrolling leaves equip/back accessible at 720p and 1080p.
See [verification](../art/codex-frontier-continuation-2026-09-05.md).

## Build guide (owner-directed, 5 Sep 2026)

`I → Build guide` opens Skills, Kinds and Progression inside the pack. The skill
catalogue includes undiscovered pages, tactical descriptions, tag filters,
mastery thresholds/use progress and four-slot assignment for learned skills.
Kinds list connected effects, actual enemy drop sources and exchange rates even
when none is held. Progression describes current era/plate/rails and the existing
milestone, alloy and curio loop. The expanded Foundry tray scrolls while the
plate and close control remain visible. Both panels are checked at 720p/1080p.
This view exposes existing/new tuning; it grants no skills or progression.

## Open questions

Owner-authorised presentation continuation, 5 Sep 2026: enemy and peddler
overhead labels now cap their projected size within six metres, remain
depth-tested, and appear within 24 metres and sixteen degrees of view centre.
Names, life numbers and elite gold remain; the existing aimed-target HUD is
unchanged. Values and explanations live in `game/art/character_look.tres`
(font 32, pixel size 0.006). This controls clutter, not detection or aggro.

- Whether the holdings strip stays once the pack screen exists, or the HUD
  shows only the four construction families.
- Whether the action bar should also host `E` (context action) as a fifth
  slot, mirroring the crosshair state.
- Sound: none in the prototype; the first UI sounds should come with the
  first character art pass (D-013).
