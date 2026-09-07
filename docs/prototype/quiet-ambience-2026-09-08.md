# INT-04C — Quiet gaps and ambience control

Status: **Implemented, owner listening/comfort review pending.**
Baseline: `1849c4f`. Owner: Matty. Delivery: Codex.
The owner's “Continue to next” selects the next bounded slice in the
[playtest plan](playtest-iterations-2026-09-07.md), after completed INT-03D.

## Outcome and initial small plan

The baseline four three-second seamless broadband loops play continuously through
two crossfading voices. That matches the rejected drone; prior passing playback
checks did not establish listening comfort. Preserve that baseline and measure
continuous occupancy before editing the production sound path.

Replace the loops with short non-looping air and vegetation textures, one
retained voice, soft sample envelopes and meaningful irregular quiet gaps.
Initial candidate: 1.6–2.4 second clips, 12–24 seconds of silence after each,
three private deterministic variants per existing surface family, outdoor gain
−36 dB (formerly −32 dB). Shelter retains its existing 18 dB attenuation.
No animal calls, water splashes, machinery or resource signals are implied.

Add an ambience level slider and mute checkbox to the existing H help overlay.
Save those two preferences independently of world saves; changing/loading worlds
must not reset the owner's volume choice. Keep Master, footsteps, interaction,
rare discovery and combat audio unchanged. The help controls must receive mouse
and keyboard input while preventing gameplay actions from passing through them.
Keep the overlay within the existing four-layer interface and small resolutions.

Verify sampled native V1–V6 maps, actual PCM, several minutes per local context,
bounded voices/cache, transitions, mute/restart, save/death/trial boundaries,
unchanged game RNG and working controls. Export labelled normal-gain listening
evidence with existing work/footstep/combat context. Use only local synthesis,
copied projects, separate APPDATA and owned processes under ignored
`build/quiet-ambience/`. Normal saves and running playtests remain untouched.

## Systems, assumptions and limits

Affected: `environment_sound*`, `EnvironmentAmbience`, the existing H overlay,
its input handling, and a bounded audio-preference file. D-013 presentation and
the accepted INT-04C work item govern the change; interface guidance explains
the controls. Existing geography, finite resources, progression, save schemas,
mob hearing and combat rules remain authoritative. No broader settings/rebinding
system or external asset dependency is selected.

Assume restrained, unpitched gust/rustle textures suit the current frontier.
Owner timbre, device output and repetition comfort remain human judgments;
automated quiet-gap/PCM checks and offline listening reels cannot certify them.
Complete this slice, record evidence and limitations, then commit and push using
the standing main-branch workflow. INT-01B remains next, outside this change.

## Implementation and reproduced behaviour

`ambient_quiet_review` ran against the preserved production baseline before the
replacement was implemented. In each 180-second meadow, vegetation, exposed
stone and shelter context, the actual listener occupied all 180 seconds with
sound and supplied no quiet gap. Eight of nine new acceptance checks failed;
the native-state preservation check passed. The same fixture now passes all
nine checks. Its time dispatch is accelerated and uses Dummy audio: this
reproduces continuous scheduling, not the owner's subjective timbre judgment.

The delivered candidate uses twelve cached, locally synthesized, non-looping
clips across the same four surface families. One retained player emits at most
one clip per update. Each clip ends at silence and is followed by a fresh
12–24 second wait, including after unmute, world changes and discontinuities.
Adjacent variants differ. Crossings discard the previous sound instead of
carrying it into another biome; delayed frames never replay missed events.
The listener and synthesis have private cosmetic random generators. Existing
V1–V6 geography, shelter lookup and trial/death/restore exclusions remain.

H now displays **Controls & sound**: an ambience slider, independent Mute
checkbox, saved percentage and scrollable controls. Mouse and keyboard changes
apply immediately. Mute preserves the selected percentage; 0% is also silent.
`AudioPreferences` reads/writes only `user://audio-preferences.cfg`, outside
world saves, and preserves unrelated fields in that file. Missing settings use
the quieter new default. Invalid values use defaults or clamp into range; a
failed write keeps the live choice and displays the persistence error plainly.

Making help interactive exposed an overlap bug in the first implementation:
the pack drew above help and could receive clicks. Three focused GUI assertions
reproduced it. Help now draws above existing panels and owns input across the
viewport while open. H/Esc returns to the existing panel or mouse look; gameplay
keys, movement, buffered jump and digging cannot pass through. The always-on
HUD still ignores mouse input. This is an input boundary, not a pause feature.

## Tuning delivered

All acoustic values live in `game/art/environment_sound_look.gd` through the
existing resource. No engine-neutral game-rule data changes.

| Setting | Value | Player experience controlled |
| --- | --- | --- |
| `clip_seconds` | 1.6–2.4 s | Length of each isolated gust/rustle |
| `quiet_seconds` | 12–24 s | Meaningful irregular silence after every clip |
| `variants` | 3 per surface, 12 cached | Small non-repeating adjacent palette |
| `edge_seconds` | 0.45 s | Soft entry/exit, with exact silent PCM endpoints |
| `outdoor_gain_db` | −36 dB, formerly −32 | Restrained default beneath action feedback |
| `shelter_attenuation_db` | 18 dB, retained | Quieter outdoor textures inside shelter |
| `fade_seconds` | 0.3 s | Smooth live shelter/level adjustment during a clip |
| `sample_rate`, `pcm_peak_fraction` | 11,025 Hz mono; 0.58, retained | Bounded bandwidth and source headroom |
| `sample_interval_seconds`, `teleport_distance_m` | 0.25 s; 12 m, retained | Local surface sampling and discard on relocation |
| `bed_profiles` | air 950/240/.08/.15; foliage 2100/480/.22/.25; reeds 2800/700/.32/.22; stone 1400/360/.12/.12 | Low-pass Hz / lower band cut Hz / high-band blend / swell depth; remove persistent low rumble without implying animals, water or machinery |
| H ambience level / mute | 0–100%, 5-point UI steps; default 100%, unmuted | Scale only this already-restrained ambient layer, or silence it independently |

## Measured listening schedule and performance

The seeded `quiet_ambience` review exports the actual listener's emitted clips
at their playback gains. Each context lasts 180 simulated seconds. Playback
timestamps are quantized to the fixture's 0.1-second dispatch, while occupancy
below uses actual PCM durations. Complete inter-clip gaps remain within the
12–24 second setting, allowing that dispatch quantization.

| Context | Baseline sounding | New sounding | New quiet share | Events |
| --- | ---: | ---: | ---: | ---: |
| Meadow | 180 s | 14.17 s | 92.1% | 8 |
| Vegetation | 180 s | 20.54 s | 88.6% | 9 |
| Exposed stone | 180 s | 17.66 s | 90.2% | 10 |
| Shelter | 180 s | 14.33 s | 92.0% | 8 |

Ignored local evidence: `build/quiet-ambience/current/captures/quiet-ambience/`.
Each context has a three-minute `*-ambience.wav` and `*-work-and-walking.wav`;
`listening-manifest.json` records every event, variant, duration and gain.
Mixed copies add existing footsteps at 30–64 s and work at 95–104 s. They are
offline, at configured gain without normalization or spatial/Master/device
processing. The older twenty-second `environment_mix` palette comparison was
corrected to stop repeating the new clips; it is explicitly not gameplay cadence.
`help-540.png`, `help-720.png` and `help-1080.png` capture the actual UI; layout
was visually inspected at all three sizes.

The same rendered 60 m walking route, 720 physics frames after warmup, ran in
both copies at 1280×720 Forward+ on the RTX 5090, VSync off and Dummy audio:

| Measurement | Baseline | Current |
| --- | ---: | ---: |
| Cold player setup, including palette | 88.67 ms | 128.00 ms |
| Steady process-frame median | 0.341 ms | 0.340 ms |
| Steady process-frame p95 | 0.633 ms | 0.634 ms |
| Retained ambient voices | 2 | 1 |

Cold synthesis of the twelve-clip palette separately measured 79.03 ms. The
larger prepared palette costs about 39 ms more at player creation in this
single matched pair; it does not synthesize on terrain crossings or placement.
Steady differences are within this sample's noise. These lightweight route
timings exclude generated-world startup, dense fighting and device mixing.

## Checks and reproduction

All runs used copied game/data, separate APPDATA, hidden owned processes and
Dummy audio under `build/quiet-ambience/`. No normal save or running playtest was
loaded, stopped or modified. Baseline logs and copy remain preserved.

| Check | Result |
| --- | --- |
| Baseline `ambient_quiet_review` | 9 checks, 8 expected continuous-occupancy failures |
| Current `ambient_quiet_review` | 9 passed |
| `environment_ambience` | 337 passed; 350 with PCM export |
| `quiet_ambience` | 169 passed; four three-minute actual schedules, bounded variants/gaps/voices, exact native and gameplay/global RNG |
| `audio_controls` | 54 rendered / 48 headless passed; actual GUI input, mute independence, failed persistence and world restore |
| `audio_controls --audio-restore-only` | 4 passed in each fresh rendered/headless process |
| `environment_mix` | 3 passed |
| `footstep_palette`, `grounded_footsteps` | 216 / 47 passed |
| `interaction_feedback`, `workshop_feedback` | 417 / 328 passed |
| `discovery_sites`, `trial_intensive` | 183 / 6,218 passed |
| `loose_drop_save`, `integration`, `panel_density` | 148 / 273 / 60 passed |
| `run_tests` | 398 passed |
| Matched rendered `footsteps_route` | 6 passed in each copy; 60 m actual movement |

The final overlay fix was followed by repeated control/restart, script,
integration, panel-density and grounded-contact checks. The native library and
tuning are unchanged; this slice does not claim a new native rebuild.

```powershell
./tools/home_review.ps1 -ReviewSet quiet-ambience -Phase current -Prepare -Import -Scenes audio_controls,quiet_ambience -Rendered
./tools/home_review.ps1 -ReviewSet quiet-ambience -Phase current -Scenes audio_controls -Rendered -ExtraArguments '--audio-restore-only'
./tools/home_review.ps1 -ReviewSet quiet-ambience -Phase current -Scenes environment_ambience,ambient_quiet_review,environment_mix,footstep_palette,grounded_footsteps,interaction_feedback,workshop_feedback,discovery_sites,trial_intensive,loose_drop_save,integration,panel_density -Scripts run_tests
./tools/home_review.ps1 -ReviewSet quiet-ambience -Phase current -Scenes footsteps_route -Rendered
```

## Limits and next boundary

Human timbre, repetition comfort and acoustic masking during ordinary fights
remain unaccepted. No hardware audition or several-minute live mixed-fight
recording is claimed: the delivered files are offline audition material and
the automated runs use Dummy audio. Existing `PlayerCombat` danger feedback
does not emit a separate audio stream to add to these reels; inventing a new
combat cue belongs outside this slice. Actual trial/combat regressions pass,
and ambience remains silent in trials. Work, footsteps, rare clues, Master,
hearing rules, progression and finite ownership are unchanged.

Only INT-04C is delivered here. Queue and affected interface/acceptance guidance
are updated; INT-01B remains the next bounded slice. Publication is reported
separately after the checked commit and ordinary main push.
