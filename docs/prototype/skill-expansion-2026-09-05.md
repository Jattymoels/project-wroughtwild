# Skill vocabulary and build progression — 5 September 2026

Owner-directed work item: move on from combat presentation into skill expansion,
progression, catalysts and Kinds that support bow and melee alongside fire/cold.
This is a bounded playtest expansion under D-016/D-019/D-023, not finished classes.

## Implementation plan and assumptions

1. Add six discoverable skills with complementary geometry and timing.
2. Add two physical catalysts and three sustain/tempo Kind variants to the
   existing four families, using the same crafting and Foundry flow.
3. Make the existing progression legible: unknown pages, mastery milestones,
   Kind sources and current plate/era ambitions in the pack's build guide.
4. Verify native rules, real spatial combat, old-save compatibility and UI
   at 720p/1080p; capture actual Godot scenes for review.

Class starting kits, four bar slots, saved mastery and plate layouts remain.
All six skills enter the existing unknown-only page pool, open to every class.
No automatic unlock or reset is applied to an existing character. The era and
alloy gates already in the game remain the progression structure. This pass
does not decide the class hall, a new element/status, a talent tree or recoup.

## First playtest vocabulary

These are implementation designs for the requested expansion; their names and
numbers are provisional tuning for playtesting, not permanent balance decisions.

| Skill | Opportunity | Cost/trade-off |
| --- | --- | --- |
| Fan Shot | Three arrows cover a spreading front | Each arrow is weaker; a cast can hit an enemy once |
| Bodkin Shot | Pierce a column of pursuers | Narrow aim and slower recovery than Bow Shot |
| Driving Blow | Reach forward and stagger/shove a narrow line | Longer recovery and little sideways coverage |
| Reaping Sweep | Bleed a broad close front, then keep it moving | Modest direct damage and limited reach |
| Cinderburst | A projectile bursts at first contact or range end | Slow flight; one area hit, never direct plus splash twice |
| Ashfall | Mark a visible surface, then detonate there after a delay | Fixed position; lead the train into it; cover blocks the blast |

The last two share a bounded, line-of-sight checked area-hit implementation.
The simulation owns their hit and status numbers; Godot owns contact, time and
space (ADR-0003). Their areas support Reach, added elemental packets and links.
No self damage is added. Delayed effects do not follow the cursor after casting.

## Kinds

Piercing and Impact Catalysts retain the offence family's common reactions and
add variant-specific physical forms. Their gear crafts aim the first roll at
projectile and physical modifiers respectively. Sipping Marrow restores a small
flat amount on landed hits; Striking/Casting Quicksilver specialise recovery in
attacks/spells. These use existing hooks, with no new damage-percentage leech rule.
All have named mob sources and the existing three-for-one peddler exchange;
Ember remains outside exchange. Foundry placement costs and return rules remain.

## Tuning and playtest targets

All skill rules are in `data/tuning/skills.json`; spatial values are in
`combat_realtime.json`. Damage is the base hit before equipment and defence.
The new skills each have relative unknown-page weight **0.8**, with milestones
at **40 / 140 committed uses**. Refused surface casts spend no use or cooldown.

| Skill | Hit / recovery | Space and payload | Mastery, first / second |
| --- | --- | --- | --- |
| Fan Shot | 10 / 1.6 s | 3 arrows, 14° between arrows; 26 m/s, 0.18 m collision radius, 22 m range | +10% reach / +1 pierce |
| Bodkin Shot | 18 / 1.8 s | 2 pierces, 30 m/s, 0.16 m radius, 30 m range | +10% reach / +20 bleed buildup |
| Driving Blow | 22 / 1.8 s | 3.4 m reach, 0.45 m half-width; 0.5 s stagger, 1.4 m shove; 12 armour for 0.5 s | +10% reach / +0.15 s stagger |
| Reaping Sweep | 9 / 2.2 s | 2.7 m radius, 155° front, 55 bleed; 0.12 s stagger, 0.4 m shove; 8 armour for 0.4 s | +20% bleed buildup / 10% cooldown refund on kill |
| Cinderburst | 16 / 2.5 s | 12 m/s, 0.22 m radius, 18 m range; 2.3 m blast, 50 ignite | +10% flight and blast reach / +25% ignite buildup |
| Ashfall | 26 / 3.4 s | 14 m aimed range, 0.85 s delay, 2.8 m blast, 70 ignite | +10% blast/aim reach / 10% cooldown refund on kill |

Travel speed controls leading, hit radius controls clearance, and range controls
safe distance. Fork acquisition ranges are 7 / 7 / 6 m for Fan / Bodkin / Cinder;
each generation uses the existing 0.7 damage fraction. Fan shares its visited
targets across its arrows. Cinderburst replaces the direct hit with a blast;
added pierce permits later contact blasts, but its visited set prevents repeated
hits on the same enemy. Solid cover blocks these blasts. Ashfall can mark a wall
or floor, fixes the point at cast time and uses full 3D distance for damage.

The 0.08 m surface offset keeps marks/blasts outside solid faces. The cap of 12
live marks refuses excess casts without spending; cosmetic flashes reuse the
existing 12-effect budget and 0.25 s fade. Death and save restoration cancel
pending player shots and marks. Presentation reuses `combat_feel.tres` gesture
timings and palettes; authored arrow, coal and charred-splinter meshes are
cosmetic, with no new art dependency.

Status pacing includes decay during cooldown: a bare Cinderburst ignites on
three successive hits, Ashfall on two. A bare Reaping Sweep needs three sweeps
to bleed; its first mastery crosses to two. These are targets for ordinary
non-resistant enemies. Equipment, bosses, movement and misses change them.

| Kind | Additional source / chance per kill | New reading |
| --- | --- | --- |
| Piercing Catalyst | Cinder Archer / 8% | Reach → Throughline, +1 pierce; Edge → Barbed Flight, +15 bleed on projectiles |
| Impact Catalyst | Stone Husk / 6% | Edge → Concussion, +0.15 s stagger; Reach → Follow Through, +0.5 m shove on attacks |
| Sipping Marrow | Bog Lurker / 7% | 0.5 flat life on landed hit while its chain flows inward |
| Striking Quicksilver | Ash Hound / 7% | +8% attack cooldown recovery while connected |
| Casting Quicksilver | Cinder Wisp / 7% | +8% spell cooldown recovery while connected |

Kind source chances are independent additions to the existing enemy loot lists;
existing gear/page chances and base family drops remain. Each pays one unit.
The two Catalysts are pack materials; the other three stack in the purse.
`crafting.json` adds optional `craft_tag` (default: family) and player-facing
descriptions. Craft targeting is restricted to the base's existing allowed pool;
an incompatible base retains the established fallback roll. `foundry.json`
holds the four new variant forms and three connected bases; `items.json` holds
their tag-scoped modifiers, excluded from random gear generation. Recovery
adds to its existing bucket: 8% recovery divides cooldown by 1.08.

## Save correction approved during this work

The audit found reloads granting every class the generic pre-class kit, including
Frost Orb and Heavy Strike for a Ranger. This contradicted D-004/D-016 starting
kits. The owner explicitly selected **“Fix future reloads; keep all owned
skills.”** Reload now restores the selected class's starting kit plus saved
discoveries. Old accidental grants remain owned if saved. No save schema or
automatic skill reset is introduced.

## Validation record

Completed: **5,033 native checks, zero failures**; the full Godot regression
pipeline passed, followed by the final focused **64 skill-expansion checks**.
Ten rendered captures were inspected, including the actual guide/Foundry and
new casts. Existing unit-harness off-tree/RID cleanup warnings remain; the
focused suite and rendered inspection report no engine errors. The local DLL
has been rebuilt. No owner save was modified.

Native checks cover all six unknown-page acquisitions, mastery boundaries,
scoped Kind readings, physical/projectile aimed-roll pools across 40 seeds each,
exchange, retained skills, class kit reloads and new Kind/mastery persistence.
Godot checks cover swept piercing collision including thin cover and long frames,
fan coverage without point-blank stacking, narrow driving geometry, bleeding
sweeps, covered blasts, timed ignite breakpoints, fixed delayed targeting,
sky refusal, budgets, linked-cast guards, death/reload cancellation, guide filters
and expanded Foundry/pack layout at 720p and 1080p.

Reproduce the focused tests and ten actual game captures with
`tools/codex_visual_review.ps1 -Skills`; `-Checks` runs the full regression suite.
The review scene grants fixture discoveries/equipment and pauses motion for
inspection; it never saves or reads the owner's character. Captures are in
`build/codex-aesthetic/skills/` and the local review gallery.

## Limits and next design work

This is the first playable tuning pass, not a sustained progression balance
study. Pages still come from the shared unknown-only pool: players can see the
catalogue but cannot target-farm one particular skill. Existing milestones,
class rails, alloys and eras provide progression; no character-level/talent tree
has been added. Moving persistent hazards, compound Kind-on-Kind reactions,
new elements/statuses and additional specialisation choices remain separate
design work. Effects remain procedural prototype art and sound is still absent.
