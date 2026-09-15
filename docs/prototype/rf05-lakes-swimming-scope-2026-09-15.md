# RF-05 — first lakes and simple swimming

Status: next implementation worker prepared after RF-04 adoption, 15 September
2026. [The final worker brief](rf05-lakes-swimming-worker-2026-09-15.md) settles the
choices below. Workspace: `D:/Wroughtwild/work/rf05-lakes-swimming`, branch
`codex/rf05-lakes-swimming`, setup `build/rf05/SETUP.md`. The owner starts it.
No lake/swimming implementation is claimed yet.

## Owner decision and intended experience

After RF-03 the owner said water is now a must, either lakes or small sea biomes.
When asked whether the first lakes should stay shallow or support swimming,
the owner chose: **"Lakes with simple swimming fine"**.

The first slice is lakes with shallow wading, simple swimming at the surface in
deeper water and easy shore exits. Water should make exploration and base siting
more appealing: a dry lakeside clearing, an outlook across the water, a bank that
suggests a veranda or workshop, and useful room to extend. Preserve the earlier
request for generation that inspires excitement and creativity about a base.
Small seas/coasts remain a possible later expansion; they are not this first slice.

This explicit work-item decision supersedes historical swimming/hydrology
deferrals for this bounded feature. It does not authorise a full water simulation.
The following implementation boundaries are the coordinator's ordinary prototype
interpretation under standing approval, not additional verbatim owner requests.

## Small complete playable boundary

- Generate one modest, seeded lake initially, with an actual basin, readable
  shallow margins and a deeper centre. The worker brief starts around 50–90 m
  across, 4 m deep and 6–10 m shallow margins, with documented feel tuning.
  Compose shorelines into the surrounding broad landforms;
  avoid a decorative blue plane floating above land or flooding every low cave.
- Include at least one useful dry home opportunity near a lake. Preserve four
  useful starter cores, finite supplies, opening pressure, progression routes and
  the freedom to build elsewhere. Shores should offer accessible dry approaches
  and room for ordinary paid buildings; no free dock, plot bonus or new resource.
- Walking transitions into wading and then surface swimming using ordinary
  movement input. Swimming keeps the character supported at the water surface;
  coming back onto a gently sloped shore should work naturally. Keep existing
  controls away from water. No boats, diving, oxygen meter, drowning timer, new
  swim skill or fluid simulation is needed for this first pass.
- Water state must be bounded and authoritative enough for movement and saves,
  not inferred only from a decorative mesh. Ground movement, teleport/respawn,
  Continue and loading a player in water must settle into a valid position/state.
- Keep paid items and death recovery reachable with exact ownership. Pickups and
  death packs released into the lake volume float at the surface at their existing
  horizontal position, with ordinary age/contents/collection preserved. Do not add a
  parallel inventory, duplicate drops or silently destroy submerged ownership.
- Use fixed lake extents/levels and original bed limits, with local terrain/build
  refresh and solid-volume rejection. Water neither spreads nor drains with
  digging; tunnels beyond/below the generated basin stay dry. Preserve legitimate
  caves, digging and ordinary paid support. Record the static boundary honestly.
- Give the water restrained colour, motion and readable shores in ordinary play.
  Existing `strange_sites.gd::_pools` and `strange_water.gdshader` may provide visual
  ingredients; current fen discs are decorative and do not supply basins/swimming.
  No new third-party art, reflection framework or separate showcase requirement.

## Generation and save boundary

Changing basin geometry requires the separate fresh normal-world identity
`frontier_v8`, with separate tuning inputs/composition. Prepare it from RF-04's
adopted continuity result. Keep the finite 1,024 x 1,024 x 96 extent and established
editable cell size. Old V1–V7/LF generation, saved geography, anchors, excavation,
paid ownership and campaign terrain policies must retain their meaning.

Normal fresh random/chosen-seed worlds should receive the new profile. Continue
restores its actual saved identity; no lake is retroactively carved through a
player's existing home. Keep V7 inputs frozen. A fresh-LF successor and existing
campaign-event redesign are outside this slice. Carry all applicable adopted
art, surface continuity and normal gameplay into the new profile explicitly.

## Worker preparation and focused evidence

RF-04 worker `5c421b3` is integrated as `27fc34d` with its matching native DLL.
Scoping inspected player movement/death, generated map records, `Pickup`,
`DroppedBundle`, `WorldDrops` and SaveManager restoration. The final brief selects
a compact generated lake record and a shared bounded water query, transient swim
state derived from world/pose, and existing drop save fields for floating recovery.
The D: worker is prepared from adopted RF-04 and the final brief; no implementation
or extra engine run was started for scoping. The coordinator adopts its checked
result under standing approval.

Default to three focused jobs on one renderer: deterministic lake/shore/supply
generation checks; water entry/swim/shore exit and water-related Continue/recovery
behavior; one short Forward+ ordinary lake/home route with a few screenshots and
a motion clip. Reuse applicable legacy and paid-building evidence. No exhaustive
seed/camera/performance matrix, R9 restart or mouse capture during automation.
Broader balance, hardware cost and owner atmosphere feedback remain playtest work.
