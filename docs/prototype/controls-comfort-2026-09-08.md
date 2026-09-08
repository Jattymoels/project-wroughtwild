# INT-08A — Controls and comfort

Status: **Implemented, owner comfort review pending.** Baseline: `c2253fe`.
Owner: Matty. Delivery: Codex.
The owner's “Yep go” selects INT-08A from the [next-round proposal](away-work-review-2026-09-07.md).
INT-08B export remains separate.

## Outcome and small plan

Extend the existing H overlay with compact camera, audio, display and binding
pages. Keep current defaults and the existing ambience preference. Preferences
belong to the device, separate from world ownership and trial checkpoints.

1. Preserve the clean baseline and demonstrate fixed prompts after an input-map
   change; inspect existing camera, audio and modal-input behaviour.
2. Add validated saved sensitivity/inversion, field of view, optional landing
   dip/idle hand sway, master level/mute and window/VSync choices. Retain existing
   ambience level/mute. Add one keyboard or mouse-button binding per gameplay
   action, conflict refusal, cancellation and reset. X's removal/horn meanings
   remain one contextual binding; Escape and standard menu navigation stay fixed.
3. Make help, action bar, building, interaction and guide prompts use current
   bindings. Suppress gameplay behind settings and during binding capture.
4. Exercise actual controls, reset, malformed preferences, failure reporting,
   fresh restarts, isolated world/trial saves and supported window sizes. Record
   evidence and limits, update the queue, commit and make an ordinary main push.

## Authority, assumptions and scope

Affected: player camera/input, first-person cosmetic observers, existing H/HUD,
panel/interaction prompt presentation, device preferences and isolated checks.
D-008 keyboard/mouse, D-012 first person and D-013 presentation apply. This
approved item extends the earlier interface exclusion of hotbar key rebinding;
skill assignment, combat clocks, collision, recipes and native state are unchanged.

Assume a single binding per action is sufficient for this bounded prototype.
Refuse conflicts and leave the existing map intact; explain which action owns
the key. Permit standalone modifiers but no modifier chords, wheel bindings or
controller inputs. Escape always cancels capture/closes help, including after
remapping its normal shortcut. Display choices do not add quality profiles or
change geography, view distances or saved state. Cosmetic motion controls cover
landing dip and idle walking sway, retaining attack/work and danger feedback.

Verification uses copied game/data and separate APPDATA under ignored
`build/controls-comfort/`, hidden owned processes and Dummy audio. Normal saves
and any owner playtest are preserved. Human comfort/listening acceptance remains
separate from functional correctness.

## Implemented outcome

H now opens **Controls & comfort**, with Camera, Sound, Display, Bindings and
Help pages. Short pages fit their contents; long pages scroll while tabs,
Reset all defaults, Close and the existing world seed/profile remain reachable.
Opening settings is also possible over the class chooser, pack, station and
building catalogue. Escape returns to the underlying panel or captured mouse.
Settings do not pause the world. Help blocks gameplay input across the viewport;
binding capture also consumes menu shortcuts, repeat and release events. Closing
settings clears held gameplay actions so input cannot leak into movement.

`PlayerPreferences` extends the existing `AudioPreferences` file,
`user://audio-preferences.cfg`, with bounded comfort and binding sections. The
legacy filename is retained deliberately: the owner's existing ambience level
and mute need no migration or second competing preference store. Missing values
use current defaults, numeric values clamp, malformed values fall back, and a
conflicting/malformed map restores a complete usable default map with an explicit
message. The next deliberate save repairs those invalid records. Unrelated
sections survive. A write failure retains the live choice and reports that the
file is unavailable. World/checkpoint serialization has no new fields.

Twenty-eight control rows cover the existing gameplay and debug actions. A key
already owned by another row is refused with the owner's action name; there is
no silent displacement or unbinding. The removal/horn aliases stay together.
Capture permits one physical key (including a standalone modifier) or LMB, RMB,
MMB, Mouse 4 or Mouse 5. Escape cancels and remains a fixed close control.
Wheel, chord and controller bindings are outside this bounded slice. Standard
menu navigation and clicks stay fixed. Reset restores all known options and the
project's original bindings without changing skills assigned to bar slots.

`InputPrompts` reads the live InputMap for HUD/help, action-bar caps, building,
interaction, station and guide text. Physical-key labels use the current desktop
layout when available. Explicit tokens avoid replacing ordinary prose or compass
letters; data formatting precedes key substitution. Open panels refresh their
read-only views on rebinding. Camera/volume changes do not rebuild those panels.
Attack/work gestures, damage direction and danger presentation remain intact.

## Reproduction and verification

Before production changes, `controls_baseline` changed the actual interaction
map to J. Baseline help still said E and runtime comfort preferences were absent:
**two expected failures**. The same bounded fixture now passes both checks.
The first new 540p layout also reproduced an oversized card from initially
unmeasured wrapped text; minimum-size changes now refit and recenter the card.

All Godot runs used copied projects/data and separate APPDATA in
`build/controls-comfort/`, hidden/offscreen owned processes and Dummy audio.
The new controls fixture additionally writes its settings/world probes only to
its ignored build directory, even when invoked directly. No normal save or
running playtest was loaded or stopped; the final process audit found no Godot
processes remaining. The initial sandbox import could not access Windows
certificate/process services; the bounded helper was rerun with platform-approved
access. This was not a publication rejection.

| Check | Passed assertions |
| --- | ---: |
| `controls_baseline`, current | 2 |
| `controls_comfort`, headless / rendered | 142 / 159 |
| `controls_comfort`, fresh headless / rendered restart | 8 / 8 |
| Existing `audio_controls`, headless / rendered | 48 / 54 |
| Existing audio fresh headless / rendered restart | 4 / 4 |
| `run_tests` script | 398 |
| `panel_density`, `grounded_footsteps`, `integration` | 60 / 47 / 273 |
| `trial_intensive`, including new settings/checkpoint invariants | 6,221 |
| `loose_drop_save` | 148 |
| V6 `placement_generated_fixtures`, `home_station_placement` | 44 / 98 |
| `environment_ambience`, `interaction_feedback`, `workshop_feedback` | 337 / 417 / 328 |
| Matched rendered `footsteps_route`, each version | 6 |

The recorded current runs total **8,806 passing assertions**; baseline
reproduction failures and baseline walking checks are recorded separately.

Reproduction commands (each helper invocation owns only its isolated processes):

```powershell
./tools/home_review.ps1 -ReviewSet controls-comfort -Phase current -Prepare -Import -Scenes controls_baseline,controls_comfort -Rendered
./tools/home_review.ps1 -ReviewSet controls-comfort -Phase current -Scenes controls_comfort -Rendered -ExtraArguments '--comfort-restore-only'
./tools/home_review.ps1 -ReviewSet controls-comfort -Phase current -Scenes audio_controls -Rendered
./tools/home_review.ps1 -ReviewSet controls-comfort -Phase current -Scenes audio_controls -Rendered -ExtraArguments '--audio-restore-only'
./tools/home_review.ps1 -ReviewSet controls-comfort -Phase current -Scenes panel_density,grounded_footsteps,integration,trial_intensive,loose_drop_save,placement_generated_fixtures,home_station_placement,environment_ambience,interaction_feedback,workshop_feedback -Scripts run_tests
```

Actual input checks cover sliders, toggles, tab buttons, conflicting capture,
Escape cancellation, unsupported input, remapped movement, mouse casting and
station use, old-key inactivity, held-key suppression, reset and failed-write
feedback. Full world captures and native ownership match across settings changes.
An actual cleared trial boundary retains exact life, timers, native deposit,
loot and choices through settings changes, suspension and restoration. Fresh
processes retain camera, binding and ambience choices independently of loading
the isolated world checkpoint.

VSync selection uses a real OptionButton popup and its focused window-ID input
route, then checks the backend setting. The initial fixture incorrectly bypassed
Godot's Window-specific input handling; correcting its dispatch made the actual
selection pass without changing production behaviour. See the pinned engine's
[Window dispatch](https://github.com/godotengine/godot/blob/4.5/scene/main/window.cpp)
and [PopupMenu input](https://github.com/godotengine/godot/blob/4.5/scene/gui/popup_menu.cpp).

Two existing prompt assertions now require the active binding instead of a
literal E; their full handoff, station body and storage checks remain. Existing
audio checks select the explicit Sound page. Their restart protocol clears the
deliberately persisted mute before scheduling checks; running those checks before
that cleanup correctly reported silent ambience. No gameplay oracle was weakened.

The [evidence index](references/controls-comfort-2026-09-08/README.md) contains
all fifteen original UI captures at 960×540, 1280×720 and 1920×1080, both route
measurements and the recorded check results. These screenshots use the isolated
UI fixture, not a claim of a new generated-world art review.

## Preference tuning

The matched existing 60 m rendered route used 720 actual physics frames after
120 warmup frames, 1280×720 Forward+, VSync off and default preferences in both
copies. Baseline/current wall-frame median was **0.341 / 0.342 ms**, p95
**0.631 / 0.635 ms** (0.6% higher), with one retained ambient voice and at most
one footstep voice in each. Cold player creation was **140.10 / 125.50 ms**;
that single-pair difference is not an optimisation claim. The earlier current
sample was 0.631 ms p95. These samples show no material regression in this
lightweight route, not a portable FPS guarantee or a dense-fight benchmark.

Definitions, ranges, labels and explanations live in `game/settings.json`.
The original default key assignments remain in `game/project.godot`.

| Setting | Default / range | Player effect |
| --- | --- | --- |
| Sensitivity | 1.0×; 0.1–3.0 in 0.1 steps | Multiplies the existing 0.003-radian-per-pixel scene sensitivity |
| Invert Y | Off | Reverses only vertical mouse look |
| Field of view | 75°; 60–100 in 1° steps | Vertical camera view; leaves pitch limits and aiming origin intact |
| Landing dip | On | Optional existing hard-landing camera offset |
| Walking hand sway | On | Optional idle walking sway; retains attacks, work and wall withdrawal |
| Master volume / mute | 100% / off; 0–100 in 5-point steps | Scales or silences all game sound; retains each cue's own gain |
| Ambience volume / mute | 100% / off, unless already saved; existing 5-point steps | Independent occasional air/rustle layer |
| Window mode | Keep launch mode; windowed/fullscreen available | Opt-in desktop fullscreen; default respects the launcher |
| VSync | Keep launch setting; on/off available | Opt-in synchronization; default respects the launcher |

## Limits and next boundary

Human camera, listening and repeated-use comfort remain unaccepted. The checks
verify VSync through the actual backend, but do not exercise a desktop fullscreen
transition, multi-monitor placement, other keyboard layouts or another machine.
Fullscreen is wired to Godot's window mode API without changing desktop display
resolution; it was not activated during the offscreen review. No controller,
multiple bindings per action, modifier chords, graphics-quality profiles or
export/distribution work is included.

The native library, game tuning, save schema, geography, finite stock, progression
and combat rules are unchanged. The complete repository/native suite was not
rebuilt or rerun; the affected checks above passed. INT-08B remains a separate
proposed next slice. Local commit and successful remote push are reported
separately after the final checked diff.
