# INT-04A — Hear the work, recognise the result

Status: **Implemented, owner listening/comfort review pending.** Baseline: `bb4667e`.

The owner's continuation accepts the next queue slice. Audit the existing local
audio, then complete one gathering-to-workshop feedback pass under D-013 and the
accepted weathered frontier mood. Use the existing procedural PCM approach;
external assets/services, music, voice and a production sound library are outside
this slice. Footsteps and broad environmental ambience follow separately.

## Outcome and audit

Common work is currently silent. Rare work sounds follow visual progress refresh,
which can replay work during restoration; final release has no distinct cue.
Collecting a physical material drop and completing a manual craft are silent.
Existing finite rare-site discovery cues already respect saved stock and remain.

Make accepted work, material release, actual collection and manual craft completion
distinct without adding HUD text. Wood/fibre, earth and mineral contact should
sound physical; rare hosts retain their restrained unusual resonance. Recipe
batches produce one confirmation per successful operation. No success cue plays
for refusal, a full pack, selection, panel refresh or save restoration.

## Small implementation plan

1. Preserve production and prepare isolated projects/user data under ignored
   `build/interaction-feedback/`; identify authoritative successful-action hooks.
2. Add a bounded cached set of short, locally synthesized contact/release and
   collection/station sounds. Give presentation controls plain-language purposes;
   keep cosmetic variation separate from all game RNG and native state.
3. Move rare work playback out of visual refresh. Dispatch accepted gathering
   and positive material hauling at their existing result boundaries; correct
   timber-type flakes without changing yield, interaction or mob noise.
4. Give successful manual crafting a station-specific sound and short cosmetic
   work response. Do not animate a whole station body or imply an idle forge is
   consuming fuel. Keep failures and browsing quiet; preserve atomic batches.
5. Test accepted/refused work, physical drops and partial hauling, exact saves,
   station batches and bounded playback. Export a local listening reel and
   capture actual interaction states; measure active feedback cost and report
   human listening/comfort review separately. Update the queue and specifications,
   commit and push to the owner's confirmed main destination.

## Systems, assumptions and limits

Player work results, Pickup's positive native haul and WorkPanel's successful
native craft are the boundaries. Resource art owns appearance only. Audio lives
under the current scene, survives the source's depletion and is never saved.
Existing Kinds, costs, work speed, fuel, XP, ownership, discovery stock, world
profiles and mob-noise calls remain. D-017/D-018 construction and the known
timber-demolition conflict are unaffected. Automated pressure-feeder controls
remain the separate INT-06 review. No native rule or save schema change is planned.

Assume short material contact and restrained completion feedback fit the accepted
mood; final timbre, volume and repetition comfort await the owner. This pass
establishes truthful action feedback rather than final production audio.

## Implemented behaviour and presentation controls

The finite palette has 23 event identities: work/release for four common host
types and five rare hosts, material collection, and field/bench/yard/forge
completion. Each has three repeatable PCM variants. Private synthesis RNG and
cosmetic selection never consume native or gameplay RNG. No binary source asset,
third-party package or external service is needed.

The scene owns short voices, so freeing a depleted resource or absorbed pickup
cannot truncate its release. All scene roots share an eight-voice budget; the
actual oldest voice yields first. Collection alone coalesces arrivals over
160 ms. Failed/empty work and nonpositive hauling never dispatch a success cue.
Rare visual updates only change appearance. Station completion uses the active
recipe's existing grade/potency station and never moves station bodies or meshes.
Three small noncolliding flecks are replaced on rapid repeat and expire in 0.38 s.

Purpose comments live alongside all new presentation controls in
`game/art/interaction_sound_look.gd/.tres` and
`game/art/workshop_feedback_look.gd/.tres`. Principal defaults:

| Control | Purpose / default |
| --- | --- |
| PCM | Cached mono 16-bit, 22,050 Hz; three variants and at most 69 cached clips, approximately 1 MB of PCM. |
| Work/release duration | 0.19 / 0.49 s: contact stays brief; release has a separate settling tail. |
| Craft/collection duration | 0.38 / 0.11 s: one completed operation versus quiet actual ownership. |
| Local gain | Work -18, release -16.5, craft -17, collection -22 dB. With a 0.68 PCM peak, eight coherent loudest voices total about 0.814 before spatial attenuation; this does not certify the complete game mix. |
| Distance | Work 9, release 14, craft 11, collection 5 m; full close gain around 1.5 m. These never change mob hearing. |
| Voice/cadence limits | Eight shared voices, three cosmetic variants, 0.16 s collection coalescing; no progress or rewards are throttled. |
| Station response | Three 18 × 12 × 40 mm flecks, 0.10 m spread / 0.11 m rise, 0.38 s lifetime; material colours and mounts follow existing surfaces. |

Host friction, filtering, resonance, damping, short attack/fade and small pitch
variation are documented synthesis controls. No gameplay tuning was introduced.

## Verification and reproduction

Godot 4.5 stable ran in isolated copies with separate APPDATA under ignored
`build/interaction-feedback/`. Rendered checks use hidden/offscreen windows and
Dummy audio; no sounds were sent to the owner's speakers. Source WAV exports
provide listening samples, not proof of hardware output quality. Normal saves
and running playtests were not used or stopped. No native rebuild was needed.

| Check | Result |
| --- | --- |
| `interaction_feedback` | 417 headless / 448 rendered checks pass. Real work/refusals, eleven common/rare work-to-release cases, timber flakes, positive/partial/full/duplicate hauling, repeated silent partial saves, exact private RNG, deterministic distinct PCM, 69-clip cache, shared cross-root voice budget and expiry. |
| `workshop_feedback` | 328 headless / 356 rendered checks pass. Field/bench/yard/forge, atomic batches, input/fuel refusals, equipment grade and Kind potency, exact native costs/XP/item RNG, remote knowledge, unchanged bodies/meshes, save/read/restore and expiry. Actual E and craft buttons drive the rendered captures; title/Close stay inside the viewport. |
| `interaction_route` | Same baseline-compatible fixture passes 18 checks on both versions. Sixteen accepted work/release/haul/bench cycles keep exact stone and woven-reed output; timing is separate from the ownership checks. |
| `first_hour_journey` | Ranger, Warden and Kindler each pass 290 checks in V6 seed 77, including actual first-home entry. Accelerated travel and inspection conditions do not establish pacing or combat balance. |

Affected regressions pass: gathering feedback **22**, loose-drop saves **148**,
finite discovery sites **183**, crafting catalogue **52**, forge progression
**58**, integration **273**, pressure workshop **60**, door persistence **467**,
materials **158**, trial lifecycle **6,217**, panel density **60**. The two new
functional scenes join the ordinary headless pipeline. Import and whitespace
checks pass.

The first wider run caught a plain `Node` scene root in integration. Playback now
accepts both ordinary and spatial scene roots; its child owns the 3D position.
The workshop fixture initially reproduced the prior home audit's automatic-node
name sanitization during load; explicit stable fixture names retain the full
exact-save assertion. Initial panel captures were taken before the existing
two-frame layout settling finished; the final fixture waits for layout and
asserts the full panel/title/Close bounds. Neither fix changes saved game rules
or production panel layout.

Reproduce current preparation with `tools/home_review.ps1 -ReviewSet
interaction-feedback -Prepare -Import -Scenes interaction_feedback,workshop_feedback`
(pass a PowerShell array when invoking directly). Use `-Rendered -ExtraArguments
'--feedback-review --crafted-look'` to export the reel, 23 individual clips and
actual authored first-person views. `-Scenes interaction_route -Rendered`
measures the shared active sequence. `-Phase baseline` uses the preserved
pre-edit production and copies only the common route fixture, never new runtime.

Logs live in `build/interaction-feedback/logs/`. Current `captures/feedback/`
contains the labeled reel, listening manifest, PCM/check report, timber and rare
work views. `captures/interaction-feedback/` contains six station panel/surface
views and the atomic workshop checkpoint. The local review entry point is
`build/interaction-feedback/index.html`; generated evidence is not committed.
Gathers use the normal player camera/E; station captures use real E and the
catalogue's craft button. All images use disclosed authored inspection ground
and stock, not a new environmental art treatment.

## Active performance and remaining review

The serial common route uses Forward+ at 1280 × 720, disabled VSync, 120 warm
frames and 720 sampled frames, with 12 measured work/haul/craft cycles. It is
deliberately faster than ordinary play and uses Dummy audio; it does not measure
device latency, generation/startup, streaming or a full ambient/combat mix.

The first pair's frame p95 increased from 0.606 to 0.699 ms (15.3%), so it was
investigated with a serial repeat without image inspection. Original reports
remain as `active-route-initial.json` in each phase. Repeated results:

| Measurement | Baseline | Current |
| --- | --- | --- |
| Frame median / p95 | 0.348 / 0.623 ms | 0.345 / 0.594 ms |
| Warm combined cycle median | 49.308 ms | 49.445 ms |
| Warm combined cycle maximum | 58.746 ms | 50.724 ms |
| First combined cycle | 58.716 ms | 69.353 ms |
| Peak active voices | 0 | 8 |

The repeated frame increase does not reproduce; warm cycle median adds 0.137 ms.
This supports sample variation, not a claimed performance improvement. The
first combined cycle adds 10.637 ms: newly requested cue variants synthesize
synchronously, then cache. That first-use cost remains explicit; most combined
cycle time already belongs to native work and catalogue rebuilding. The PCM
fixture's first-access report includes both warm and previously unused variants
and must not be described as a wholly cold palette benchmark.

Human listening still needs to assess timbre, relative volume, repeated-use
comfort and how the cues sit alongside combat and rare discovery. First-use
synthesis on slower hardware remains unmeasured. Footsteps and nearby ambience
are the next proposed INT-04B slice; broader music/UI audio, graphics, automated
workshop state presentation and combat tuning remain separate.
