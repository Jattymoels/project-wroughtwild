# R8 tuning and evidence controls

R8 introduces no gameplay or visual tuning numbers. Every inherited production
value and its purpose remains with the selected owner: R1 fit/burial/LOD controls;
R3 material and face roles; R5 cabinet/feet fit; R6 surface projection; R7 group,
colour and attached sway controls. The package retains complete parent receipts,
selected settings resources and packed-master metadata. R2 aliases require exact
map bytes and complete importer parameters; filtering, mipmaps and colour spaces
are preserved. Native stock, timing, costs, capacities, collision, placement and
F4 recovery order remain pinned.

R8-only evidence controls:

- `--r8-no-mouse-capture`: explicit test-only opt-out; absent flag executes normal
  mouse capture. Test-only `window/size/no_focus=true` keeps automated windows from
  taking focus. The override is excluded from normal-play runtime.
- Fixed 60 FPS for deterministic native checks and paired paid routes. This is
  fixture pacing, not a cost measurement. The inherited route settles 45 physics
  frames and allows 180 frames per waypoint with its original 0.55 m threshold
  and >100 m success assertion. Additive trace samples occur every 20 frames.
- The comfort check observes 120 actual rendered player process frames; every
  observation requires visible mouse mode and the real window no-focus flag.
- Cost runs use the unchanged R2 harness: 1440 x 900, 4x MSAA, vsync off, max_fps 0,
  120 warmup frames and 300 settled samples per camera/light; three independent
  art-on and three art-off processes per backend for both original and combined
  runtimes. No fixed-FPS flag, imports, generation or captures overlap benchmarks.
- Three R2 home/route/reload cycles retain the published two-process-frame plus
  rendered-frame boundary between visits. They retain real partial native work,
  release/re-entry, exhaustion and fresh-process restore. They are bounded evidence.
- R4 mixer/main-thread terminal handoff keeps its published controls unchanged;
  `game/r4/cleanup_options.gd` explains each value. This runs after assertions and
  saves and applies only to completed fixtures.

Acquisition and address selection are harness-paced. Route movement, home entry,
finite work and transactions use native controls/rules. Explicit catalogue/source
inspection stock is separate from the no-grants paid-home flow. Captured frame
sequences are inspection-paced playback, not real-time or human-session evidence.

Motion previews resize actual frames to at most 800 x 500 pixels and quantize to
128 colours for reviewable file sizes. F4 uses 100 ms per frame and controller
motion 80 ms; these are illustrative looping previews. Raw 1440 x 900 PNGs stay
in the handoff. Neither preview timing is used as a performance measurement.
