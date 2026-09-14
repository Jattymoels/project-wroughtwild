# R4 ownership analysis

Status: attribution and candidate verification complete; owner review pending.

The prepared G1 runtime is pinned at
6bb2e044dcd0bf1788896aa2c19cdf56fee93522. All work happens in the R4 runtime copy.
Original package payloads were fully hashed before consumption.

## Lifetime being tested

The reported source fixtures are B3, C1, C2, C3, C4, E1, F2 and F3. Their
successful terminal paths call SceneTree.quit immediately after work/save checks.
E1 already queues its children for deletion and awaits two process frames.
Accelerated fixed-fps process frames do not establish that an asynchronous audio
mixer has processed the corresponding stop requests.

Verbose shutdown evidence identifies AudioStreamWAV and AudioStreamPlaybackWAV.
InteractionSound owns a finite shared PCM cache. Each call creates an
AudioStreamPlayer3D below the supplied fixture/world or station node. These
player nodes are fixture descendants; the cached PCM palette is reusable
presentation state. Stopping completed fixture voices and releasing completed
fixture descendants is within R4. Clearing the palette, changing the voice
budget, editing native ownership, or altering save restoration is not necessary.

The diagnostic observer records scalar instance IDs and cue/parent names. It
holds no resource references. The repeated exercise retains only WeakRef
observations of playback objects.

## Pinned engine explanation

Godot 4.5's AudioStreamPlayerInternal stops playback on pre-delete. AudioServer
marks a stopped stream for fade-out deletion; its mixer removes the playback
entry, and the main thread later retires the reference. These are separate
lifecycle steps. R4 tests the fixture's completion of this handoff before normal
quit rather than changing engine ownership.

Sources:
- [AudioStreamPlayerInternal 4.5-stable](https://github.com/godotengine/godot/blob/4.5-stable/scene/audio/audio_stream_player_internal.cpp)
- [AudioServer 4.5-stable](https://github.com/godotengine/godot/blob/4.5-stable/servers/audio_server.cpp)
- [SafeList 4.5-stable](https://github.com/godotengine/godot/blob/4.5-stable/core/templates/safe_list.h)

## E1 deferred presentation work

E1's unchanged restore opens and closes 18 station work panels in one flow.
The unchanged WorkPanel.refresh schedules _settle_catalogue, which waits for
two process frames while retaining its layout continuation. E1's old terminal
path frees the player/UI before those deferred layout callbacks finish.
Its original and initial-repair restart logs retain orphan StringNames
process_frame and Node. The final fixture helper lets the queued callback start
and its two waits finish before freeing descendants; it records the process_frame
connection count before that wait and immediately before deletion. No shared
work panel or inventory implementation changes. The final native restart audit
must reject any remaining orphan StringName, even with exit code zero.

The exact unchanged InteractionSound, WorkPanel and InventoryPanel sources are
retained as hashed attribution references in evidence/ownership-source/. They
are not changed-source masters or reusable runtime changes.

The leak is sensitive to timing. Original naked repeats, clean and leaking,
are all retained. Scalar observers add work and can change whether a particular
process exposes the shutdown race; buffered C1 traces reduce printing during
the fixture flow. IDs are matched only inside their own process, never between
a baseline and a repaired run.

## Candidate boundary for R8

The checked delta is eight fixture finish functions and a shared fixture-only
cleanup helper/options file. It is not an ordinary-game audio or resource-cache
patch. The helper is called only after existing successful work, ownership,
depletion and persistence assertions. Failure paths and diagnostics remain
intact. Exact hashes and functions are recorded in the sealed changes.json after
verification.

No meshes, textures, LOD selection, shape/material pairs, native DLL, gameplay
script, palette, body, target, seed, world profile, saved identity or save schema
is changed. Existing source art is used for visual evidence, with native posed
work explicitly distinguished from a human playtest.

A short repeated lifecycle exercise can demonstrate retirement and bounded
counts in that sample. It cannot establish a long-session memory bound, a
minimum-hardware budget, or ordinary-world rollout acceptance.
