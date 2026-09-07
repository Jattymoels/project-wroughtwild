# INT-04B — Hear the ground and the surrounding land

Status: **Implemented, owner listening/comfort review pending.** Baseline: `71c6d98`.

The owner's continuation authorises the next recorded INT-04 slice: grounded
footsteps and restrained nearby ambience. Use existing surfaces and biomes under
D-013's weathered frontier mood and D-030's devastated, augmented landscape.
No new gameplay or generation decision is needed for this presentation pass.

## Outcome, scope and assumptions

Walking sounds follow actual grounded travel and the surface supporting the
player, including constructed floors and exposed terrain after digging. Quiet
outdoor air and foliage beds give existing places a little presence; existing
shelter reduces them. Rare-resource discovery remains a separate finite-stock
cue. A marsh surface does not establish that the player's feet are in water.

Use a small cached palette synthesized locally, with private cosmetic RNG and
bounded voices. Assume understated material contact and broadband environmental
movement fit the current mood. Human timbre, repetition and volume review remains
pending while the owner is away. No external sound assets, music, voices, new
creatures or sounds suggesting functioning post-cataclysm industry are included.

Player movement, terrain/build colliders and the existing biome/shelter state
provide inputs. Godot resources own presentation tuning, with a plain-language
purpose for every control. Native rules, seed/profile geography, materials,
deposits, recipes, loot, mob hearing and save schemas stay outside this slice.
The reported D-018 timber-demolition conflict remains separate.

## Small implementation plan

1. Preserve production and isolated user data under ignored
   `build/footsteps-ambience/`; audit real support, map and player lifecycle hooks.
2. Add actual-displacement footsteps with distinct broad material contacts;
   prevent sounds from blocked walking, air, dash or discontinuous relocation.
3. Add a tiny local biome-bed palette, softened in existing shelter and silent
   during trials, disabled play and invalid world context. Preserve Master mute
   and pause, rare-site clues and existing interaction voice limits.
4. Verify actual walking, changed support, panels, save/load and trial lifecycle;
   export listening samples and matched rendered performance evidence. Keep
   synthesis startup costs distinct from steady travel cost.
5. Update the affected specifications and queue, record limits and evidence,
   then commit and push through the owner's standing main workflow.

## Review contract

Automated checks establish truthful dispatch, bounded playback and compatibility,
not convincing final audio. Compare baseline/current on the same actual walking
route, graphics settings and frame sample. Investigate regressions over 10%.
Owner review later: do steps match timber/stone/soft ground, is repeated walking
comfortable, and do quiet beds leave work, danger and rare discovery readable?

## Implemented presentation and tuning

`PlayerFootsteps` runs after the existing `move_and_slide`. Actual horizontal
distance and support select grass/brush, earth, stone, timber, fibre or metal.
Construction uses native material traits, so existing families keep their
meaning. Terrain uses its current voxel and faceted triangle source cell; the
biome surface supplies topsoil texture only. Authored unlabelled trial floors
use neutral stone contact. Six surfaces have three short deterministic variants.

`EnvironmentAmbience` reads the selected terrain profile and existing biome
surface without scanning resources. Four cached broadband loops represent open
air, foliage, reeds and exposed stone. Two retained Master players crossfade
within one combined outdoor gain; the existing shelter cache reduces it.
Trials, invalid world context, disabled player physics and death clear playback.
Same-position loads, explicit trial restores, floor changes and pauses reset
cosmetic state. There is no saved stride, ambient clock or new gameplay event.

The new Resources are `game/art/footstep_sound_look.tres` and
`game/art/environment_sound_look.tres`; their script exports explain every
parameter. Main controls are:

| Control | Initial value | Player-visible purpose |
| --- | --- | --- |
| Step distance / minimum interval | 1.85 m / 0.14 s | Tie a restrained rhythm to actual travel while bounding fast contacts. |
| Minimum movement | 0.001 m per physics tick | Keep collision settling and pushing a wall quiet. |
| External position discontinuity | 0.06 m | Discard a partial stride after relocation rather than cash it in at the destination. |
| Tick/motion/rise limits | 0.15 s / 1.25 m / 0.65 m | Reject stalled or discontinuous travel while allowing the existing half-metre step. |
| Support probe | 0.3 m above / 0.4 m below foot | Read actual floor contact rather than distant ground beneath a floor. |
| Edge probe inset | 0.02 m | Keep a valid narrow-edge contact ray just inside its supporting collider. |
| Footstep gain / range / voices | −22 dB / 6 m / 3 | Keep contacts local and leave the eight action-feedback voices independent. |
| Contact duration / variants | 0.24 s / 3 per surface | Short dry contacts with bounded repeat variation. |
| Ambient sample interval | 0.25 s | Follow local biome crossings without world or resource scans. |
| Ambient fade / gain | 1.4 s / −32 dB | Quiet continuous surroundings with softened transitions. |
| Shelter attenuation | 18 dB | Let an existing enclosure sound protected without inventing a room tone. |
| Ambient relocation threshold | 12 m | Discard the previous place after a large move, including vertical relocation. |
| Loop duration / join overlap | 3 s / 0.15 s | Four small reusable broadband loops without a hard repeat seam. |

Frequency/filter/envelope rows describe material contact and friction. PCM uses
22,050 Hz footsteps and 11,025 Hz ambience, with respective source peaks 0.54 and
0.58. This is a finite approximately 444 KiB combined PCM cache, not an audio
framework. Presentation numbers affect no movement, threat, economy or generation
rule. Hardware output, final combat mix and listening comfort remain unverified.

## Verification and evidence

All engine runs use copied projects and isolated APPDATA under ignored
`build/footsteps-ambience/`, with Dummy audio and hidden/offscreen review windows.
The preserved baseline remains `71c6d98`. No ordinary save or running playtest
was used. The existing native library was unchanged; no new package or asset
dependency was introduced.

The local review page is `build/footsteps-ambience/index.html`. Evidence includes:

- `current/captures/footsteps/footstep-listening-reel.wav`: all six surfaces and
  three variants at configured gain, with raw WAVs and a timing manifest.
- `current/captures/footsteps/environment-mixed-reel.wav`: a 20-second offline
  arrangement of walking, beds, work and two existing rare clues at configured
  gains. This is not a recording of the output device or a resource placement.
- `current/captures/ambience/`: four raw source loops and profile/lifecycle/PCM
  evidence. Raw WAVs are deliberately labelled as unscaled inspection audio.
- `baseline/captures/footsteps/` and `current/captures/footsteps/`: matched real
  60 m walking routes and technical captures of the neutral support fixture.
- `logs/`: complete import, functional and rendered check output. One harness
  invocation used `integration_test.tscn` instead of the existing
  `integration.tscn`; that missing-scene invocation is not a product failure.

The palette independently preserves global/native/combat/gathering RNG, all
existing construction-trait mappings, exact faceted voxel sampling, Master mute,
pause and teardown. Three contact voices cannot displace any of the eight
interaction voices. The coherent worst-case bound for those configured local
sources plus the combined ambient bed and one rare clue is 0.9851 of full scale;
this bound excludes combat and downstream Master/device processing.

| Check | Result |
| --- | --- |
| `grounded_footsteps` | 47 checks each, headless and rendered. Real ground/placed contacts, exposed strata, settled slope, narrow ledge, half step, blocked walking, air, dash, panels, relocation, save and actual trial traversal/extraction. |
| `footstep_palette --footsteps-review` | 237 rendered checks; complete family/PCM/voice/pause/RNG/mix-budget coverage and exported samples. |
| `environment_ambience --ambience-review` | 281 rendered checks; actual native V1–V6 maps, local/bounds queries, shelter input, death, trial, identity changes, pause, mute and fixed voices. |
| `environment_mix` | 3 checks; configured-gain mixed arrangement exports without clipping. |
| `footsteps_route` | 6 checks each baseline/current rendered; exact 60 m travel and unchanged native state. |
| `interaction_feedback` / `workshop_feedback` | 417 / 328 headless checks; existing accepted-action, crafting and restoration feedback remains intact. |
| `home_headroom` / `loose_drop_save` | 30 / 148 headless checks; movement clearance and exact loose ownership remain intact. |
| `trial_intensive` / `discovery_sites` | 6,217 / 183 headless checks; full story/repeatable/suspension lifecycle and finite rare cues remain intact. |
| `integration` / `first_hour_journey --journey-class=ranger` | 273 / 290 rendered checks; existing full integration and actual V6 gathering-to-home journey pass. |

Checks establish dispatch and lifecycle, not listening quality. The ambience
shelter test reads the existing cached enclosure result; this slice adds no
new acoustics, occlusion model or cave/shelter detector. The owner can review
comfort later while INT-05's Forge readability/traversal audit proceeds next.

Cold ambience preparation is 28.255 ms for all four cached loops in the recorded
run. Footstep synthesis is lazy: 1.763–1.796 ms per new variant, or 31.917 ms
across all eighteen. Those costs are measured separately from assertions,
exports and warmed travel. They are not claimed as end-to-end generation/startup
measurements. Higher-volume combat mixing, physical speaker/headphone response
and listening comfort await the owner.

The additional actual-contact probes reproduced one support-reading defect: a
ray on the exact outside boundary of a narrow ledge could miss although the
capsule remained supported. The contact normal now insets that probe by 2 cm.
The slope fixture initially included its airborne approach; it now requires
three consecutive real floor frames before walking, with a bounded settling
assertion. Both material checks remain, as do strict no-air/dash rules; no
player movement or collision behaviour was changed to make audio tests pass.

### Matched performance

Final baseline/current use Forward+ at 1280 × 720 with VSync disabled and Dummy
audio. Both walk the same 60 m in 720 physics frames, after 120 warmup physics
frames cross all four fixture surfaces. Roughly 34,000 rendered frames cover
each measured walk. The fixture uses authored support and the existing biome
map contract; it does not represent dense combat or generated-world startup.

| Measurement | Baseline | Current | Assessment |
| --- | --- | --- | --- |
| Median frame | 0.330 ms | 0.331 ms | +0.3%. |
| p95 frame | 0.539 ms | 0.538 ms | −0.2%; no steady regression above 10%. |
| Cold player instantiate/ready/class selection | 43.622 ms | 72.294 ms | +28.672 ms; one-time preparation investigated below. |
| Maximum walking / retained ambient voices | 0 / 0 | 1 / 2 | Actual ordinary walking stays within its separate budgets. |

Cold player preparation exceeds the 10% investigation threshold. Its additional
28.672 ms closely matches the independently timed 28.255 ms preparation of the
four ambient loops. That explicit first-player cost is retained to keep a new
biome crossing from synthesizing a loop during travel; later players reuse the
cache. This is a known bounded startup tradeoff, not a claim that complete game
startup has no regression. Footstep variants remain short lazy first-use costs
as measured above. Neither rendering test plays through or measures the owner's
real sound device. The earlier flat-route comparison also had no steady
regression; the final comparison includes the narrow-edge support correction.
