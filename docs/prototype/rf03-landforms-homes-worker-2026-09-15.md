# RF-03 — landforms that make you want to build

Status: completed by worker `b8d884c` and integrated on main as `d4aa817`,
15 September 2026. See the [result and playtest](rf03-landforms-homes-result-2026-09-15.md).
This brief is retained as history; do not restart RF-03. Ground continuity is next.

Worktree: `D:/Wroughtwild/work/rf03-landforms-homes`
Branch: `codex/rf03-landforms-homes`
Setup: `build/rf03/SETUP.md` (exact base, baseline DLL and native build inputs).

## Player experience first

The owner approved the next landform scope and added:

> Yep let's do it - maybe add some focus about having generations that gives
> excitement/creativity to have your base there

An ordinary fresh world should offer places that make the player imagine a
home: where the entrance would face, how a workshop might nestle into a bank,
where a terrace could overlook the valley, and how a base could grow over time.
Terrain, vegetation, views and useful approaches should help create that desire.
The existing four clearings are largely circular flat pads arranged around spawn;
give their surroundings distinct character while preserving their practical use.

Keep Wroughtwild's years-after landscape: rolling green land, established
woodland, weathered old impact shoulders and selected surviving scars. Give the
player interesting places between the major discoveries as well as at them.
One impact need not dominate every outlook. Surface materials and grass from
RF-01/RF-02 are already adopted and should help the new landforms read in play.

## Bounded landscape and home-site brief

- Keep the finite 1,024 x 1,024 m world, one-metre editable cells and 96-cell
  depth. Improve broad rises, gentle dips, sheltered shoulders and transitions
  around existing old impact geography. Concentrate creative work on the
  meadow/woodland heartland and its outward connection to an existing impact.
  Fen and mountain keep the established content/treatment; no all-biome redesign.
- Keep four reachable starter home opportunities, the current quiet opening,
  useful buildable cores and finite starter supplies. Compose the surrounding
  land so at least three have meaningfully different siting possibilities:
  a woodland pocket with an opening, a meadow overlook above a gentler valley,
  and a terrace/bank with an obvious route and expansion direction are useful
  examples. These are design intentions, not three fixed prefabs or new biomes.
- Let an approach reveal the site and its outlook. Preserve room for a modest
  house, workshop, movement and future extensions. Natural margins can suggest
  courtyards, a raised veranda, a split-level extension or a sheltered work area.
  Only use ideas supported by existing terrain and construction mechanics.
- Retain the existing home core's useful size (current radius 14 m) and supply
  guarantees. Change contour/shoulder/position/approach composition in the new
  profile to make each setting feel part of the landscape. Avoid pronounced
  circular platform edges or compulsory jumps on ordinary supply/home routes.
  Broader outlook, enclosure and extension space can vary beyond the core.
- Home choices offer different views, shelter and layouts without new stat
  bonuses, plot ownership, resource types, free starter buildings or gates.
  The player may still build elsewhere under the existing rules. No home-site
  selector UI or map-marker system is required.
- Use deterministic, bounded seed-driven generation and varied local terrain.
  The same seed/profile reproduces the world; different seeds change how the
  opportunities sit in the landscape. No privileged picture seed or fixed map
  catalogue. A modest candidate search with a safe fallback is fine; no unbounded
  search for a mathematically perfect view or hidden scenic-score framework.

## Compatibility contract for this slice

This is a **fresh normal-world successor**, `frontier_v7`. Make the ordinary
New World random/chosen-seed flow select it when complete. Continue must restore
the saved profile and seed before generating, so existing homes, edits, finite
resources, pressure ownership and progression stay exactly where they belong.
No existing-world terrain conversion or save-schema migration is requested.

Keep V1-V6 and both existing Living Frontier geography identities frozen.
Existing LF launch flags continue to select their established worlds and policies;
RF-03 does not move their laboratories, sources or campaign transformation areas.
Bringing the new generator to fresh LF worlds can be separately scoped later.
Retain all current gameplay available in a normal world, including era changes,
trials, habitats, finite discoveries and the pressure workshop.

The smallest compatible input arrangement is a separate V7 tuning table/file and
generation route. **Leave `data/tuning/worldgen.json` and its V6 meaning intact**:
`tuning.cpp` currently derives both LF world tables from it. Add V7 inputs such
as `worldgen-frontier-v7.json`; do not silently feed changed terrain inputs into
V6/LF. Retain existing native default semantics used by old callers; the normal
game can explicitly select V7. Do not edit frozen algorithms in place to make
old worlds adopt the new shapes. Narrow derivation or a new versioned composer
is appropriate; a general generation framework is unnecessary.

Compose changed physical land before dependent sites/resources/routes are
finalised, or consistently reseat/rebuild every affected native record in the
new generation path. Never apply a decorative height deformation to an already
populated world while leaving collision, resource anchors or saved data behind.
Preserve cave functionality, digging, supported approaches, critical progression
opportunities and the quiet/patrol boundary. This work is not PLAY-03 diagnosis.

V7 must opt into the applicable adopted world art, RF-01 support/scatter and RF-02
ground/grass, existing wide-world streaming and ordinary gameplay consumers.
Trace profile allowlists deliberately; a new identity must not silently fall
back to primitive art, eager old-world streaming or missing pressure ledgers.
Keep LF-only mechanics exclusive to their existing policies. Do not globally
replace every V6 string, weaken profile validation or accept unknown identities.

## Reading and implementation sequence

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and its required
reading order; reuse applicable prior reading. Then follow only these active links:

- `docs/prototype/reclaimed-frontier-intensive-2026-09-14.md`, this RF-03 selection,
  and the original owner reference gallery/wording under
  `docs/art/references/environment/2026-09-14-reclaimed-frontier/`.
  Inspect relevant landscape originals, especially ENV-005/006/008. References
  are influences; their pixels never become runtime assets.
- D-013/D-030/D-032, relevant world-generation and construction specification
  sections, and `docs/prototype/wide-frontier-intensive-2026-09-06.md` for the
  current world/opening guarantees. Historical large verification programmes
  in those files are superseded by current AGENTS.md and this bounded task.
- `sim/src/worldgen_profiles.cpp`, the V6 base/landscape/opening/pressure
  composers, relevant worldgen/tuning declarations and load paths, then actual
  V7 consumers: Sandpit, SaveManager, terrain/site/resource/pack presentation,
  contraption/pressure identity and RF-01/RF-02 eligibility.
- RF-01/RF-02 results and relevant existing native generation/placement helpers.
  They establish unchanged art, footprint and ownership behavior; do not replay
  the entire art/economy/campaign history.

First identify the small generation changes and home-site compositions, with
their tuning purposes. Implement V7's separate input/identity path and native
landforms, then connect the normal game and complete a usable home visit/build.
Keep new native code/tests and `tools/wroughtwild-rf03/` focused. A native rebuild
from this worker's current source is required; reuse the existing godot-cpp ABI
library/headers listed in SETUP. Put compilation and all tool output on D:.
Do not rebuild the old baseline, engine or third-party library by default.

## Three focused verification jobs

Name the concrete risk before checking. There is no hard ten-minute cutoff,
and no renderer/seed/camera matrix or performance gate. Fix concrete failures;
stop when the scoped playable result is supported by enough evidence.

1. **Native generation and old identity:** use seed 77 as the primary new-world
   fixture, repeat it for determinism, and one fixed second seed for basic
   variation. Check the existing world/content guarantees, four supported home
   cores, required approaches/supplies and quiet boundary. Check unchanged V6
   and LF3 identity at one relevant seed each, reusing retained fingerprints
   where possible. If needed, obtain only these small identity records once
   from the prepared unchanged DLL before replacing it. Keep LF1's unchanged
   inputs/routing explicit. No full historical seed sweep or baseline rebuild.
2. **One ordinary Forward+ visit:** one useful daylight walk on the new primary
   world, with real player physics and world work active. Show two contrasting
   home choices and the nearby landscape that gives them character. Use one
   route, not a camera tour; explain honestly if an impact is not visible from
   that route. Keep up to three stills and one short clip. Briefly say what the
   player might build at each shown site and which visible feature suggests it.
   Actual views and walking matter more than a top-down elevation metric.
3. **Build, save and return:** at one new-world home, use paid ordinary materials
   for a small usable footprint including an octagonal part and a station.
   Check actual support/movement, one local dig and grass/building clearance,
   then private save and fresh-process Continue with exact identity/ownership.
   Include a small existing V6 private-save load check to show it stays V6 after
   New World defaults change. Reuse unchanged economy/art/LF campaign evidence;
   do not build complete houses in every home/seed or replay the campaign.

Native compile/import setup supports those jobs; do not disguise an expanded
matrix inside a job. Use hidden headless checks where possible. Render only with
the verified no-mouse opt-out, BOM-free no-focus override and shared
`Local\WroughtwildArtRender` mutex. Never move the desktop mouse, alter remote
access settings or stop an owner/peer process. Put private user/temp state and
logs on D:, keep owner saves untouched, and end owned checks before handoff.
R9 stays stopped; underground lag remains parked pending owner evidence.

## Completion

Deliver a playable V7 normal New World plus working old/new Continue, a checked
worker commit SHA, the exact built DLL path/hash and build recipe/source revision,
and a short result at `docs/prototype/rf03-landforms-homes-result-2026-09-15.md`.
The ignored DLL must match the delivered native source; the coordinator needs
it for local main integration. Do not commit binaries/build caches or copy a
multi-GB package. Update affected specs/identity documentation accurately.

Start the handoff with what changed for a player choosing/building a home, then
remaining limits, checks actually run and publication status. Explain tuning in
plain language. Give exact New World/Continue launch steps, seed and site route.
Show selected actual images/clip directly in chat using absolute paths. Owner
playtesting and excitement/creativity remain human feedback, not a numeric pass.
Standing approval covers scoped choices and adoption; no further visual gate.
Stop after RF-03. The coordinator integrates/pushes; no successor worker or review.
