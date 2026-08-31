# ADR-0003: Who Owns Combat — the Sim or the Engine?

**Status:** Accepted, 31 August 2026 (owner approved the recommended split when
directing this build phase; see ADR-0001 for the delegation context).
**Decision owner:** Human project owner
**Related:** D-001, D-004, D-006, ADR-0001, `docs/systems/combat-and-builds.md`,
`docs/systems/dungeon-runs.md`

## The question, in plain terms

The rules library in `sim/` resolves combat as **rounds**: each round the
player picks one skill, every living enemy attacks on its own rhythm, and the
armour/resistance maths decides what gets through. It is deterministic,
regression-tested and drives the balance simulator (thousands of seeded boss
fights per gear stage). The design calls for **real-time third-person action
combat** in the engine. Those two models do not reconcile by themselves, so
before any combat is built in `game/` we must decide which side is the
authority for what — otherwise the numbers the balance sims prove and the
numbers the player experiences will drift apart.

## Options

### A. The sim's rounds are authoritative; the engine plays them back

The engine becomes a presentation layer over turn resolution: you pick a
skill, the round resolves, animations play.

- Keeps one truth, perfect balance parity.
- **Rejected:** it is not action combat. It contradicts the design pillar and
  every acceptance criterion about dodge windows, area versus single target
  and boss telegraphs.

### B. The engine owns combat entirely; the sim's combat becomes dead code

- Fastest to feel good in the hand.
- **Rejected:** every balance-relevant rule (mitigation, resistance cap, boon
  and weakness interactions, boss fire cadence) gets re-implemented in
  GDScript, untestable headlessly, and the balance simulator stops describing
  the real game. This is exactly the drift the sim exists to prevent.

### C. The sim owns the numbers; the engine owns time and space — **chosen**

| The sim decides (engine-neutral, headless-tested) | The engine decides (Godot, feel) |
| --- | --- |
| Derived stats from base + equipment (`deriveStats`) | Movement, dodge distance, camera |
| Mitigation per damage type (`mitigateDamage`) | Hitboxes, ranges, cones, who is inside an area |
| Boon/weakness interpretation (`buildMods`) | Attack wind-ups, telegraph animations, cooldown *timers* |
| Damage of one player hit given skill, mods, target isolation, hit index | When a hit happens and whom it touches |
| Damage of one enemy or boss hit, mitigated | Enemy pathing, aggro, spacing |
| Enemy and boss definitions (life, damage, type, cadence) | How cadence is expressed in seconds |
| Trial structure, offers, run loot, death contract (`TrialSession`) | Rooms as arenas, doors, the offer UI |

The bridge between the two clocks is one tunable, **`round_seconds`**: the
sim's `attack_period_rounds`, `breath_period_rounds` and skill cooldown rounds
map to real-time periods by multiplying by it. The round-based
`runEncounter` remains the **balance oracle** — if a real-time fight and its
round-based twin disagree materially on time-to-kill or damage taken, the
real-time tunables are wrong, not the sim.

## Consequences

- `sim/` gains a small **combat-numbers API** callable per hit (player hit
  damage, enemy hit damage, mitigated) that reuses the same code
  `runEncounter` uses internally, so a hit in Godot and a hit in the balance
  sim are computed by one function.
- Real-time-only tunables (speeds, ranges, wind-ups, `round_seconds`) live in
  `data/tuning/combat_realtime.json` with plain-language purposes, loaded by
  the sim like every other table, read by the engine, never defined there.
- The engine keeps **no combat state the sim cannot reconstruct**: life,
  cooldown timers and positions are engine state; life *maximum*, damage
  *values* and resistances are always asked of the sim.
- Boon offers, weakness acceptance and the death contract are driven through
  `TrialSession`; the engine presents rooms and offers, it does not decide
  them.
- Determinism: the sim's per-hit variance is seeded; the engine passes a
  per-fight seed and a running hit index so a recorded fight replays
  identically in tests.

## Prototype acceptance for this decision

- A headless Godot test can run a scripted real-time fight and assert every
  damage number against the sim's functions.
- The balance simulator and a real-time fight with identical gear land in the
  same qualitative band (boss unwinnable without fire resistance, winnable
  with it) — checked by hand during the first trial playtest and recorded
  here.

## Revisit when

- Real-time feel demands a rule the round model cannot express (e.g. damage
  scaling with movement); then extend the sim first, the engine second.
- A second combat archetype (spells, projectiles) is added: the API must stay
  tag-driven rather than growing per-skill branches.
