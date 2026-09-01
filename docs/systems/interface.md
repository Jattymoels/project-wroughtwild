# Interface and In-Game Experience

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
- [ ] Wave 2: item cards with rarity colour and per-modifier sentences; a
      compare view against the worn item.

## Open questions

- Whether the holdings strip stays once the pack screen exists, or the HUD
  shows only the four construction families.
- Whether the action bar should also host `E` (context action) as a fifth
  slot, mirroring the crosshair state.
- Sound: none in the prototype; the first UI sounds should come with the
  first character art pass (D-013).
