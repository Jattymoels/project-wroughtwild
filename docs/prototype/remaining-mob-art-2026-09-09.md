# ART-06 — Remaining mob design and local generation

**Design/source and ART-06B surface stages delivered; rigs remain open — 9 September 2026.** The owner deferred the proposed ART-05B
route polish and requested that the other existing mobs be properly designed
and generated through the liked concept → local TRELLIS → Blender process.
Asked about the four humanoid-looking regular enemies, the owner selected:
**“Reimagine them as augmented animals.”** The Conservator remains the established
human antagonist. The owner reviewed the six concepts, including the revised
ram, and selected **“Approve these six directions.”** This selects their visual
ancestry, not new attacks, lore history or native body shapes.

The owner then requested more grotesque augmentation and clarified **“more
extra augments per era.”** Their subsequent answer explicitly selected **“Push
these six further now.”** Both directions apply: keep the six approved animal
identities, make the starting forms more structurally altered now, and add
further physical augmentations in each later era. Preserve the earlier cleaner
concepts and raw candidates as comparison history; they are not the selected
finish target. Do not use a simple colour/size change as an era design.

## Outcome, authority and scope

Bring the remaining roster toward ART-01/03's anatomical and material quality.
Recognisable animals carry grown, recessed fractures with narrow living light;
the ordinary host must remain convincing without emission. Preserve the liked
boar, wolf, stag and moth. This is an isolated art-production continuation under
D-013/D-030, with D-010/D-012 combat and the current LF campaign authoritative.

The inspected baseline is `4f0886b`. `data/tuning/world.json` contains sixteen
enemy records: eleven ordinary roles and five LF host variants. Six ordinary
roles lack the new approved quality. The Tyrant/Warden boss family and dedicated
human Conservator also need later complete handoffs. Existing LF Red/Blue/paired
boar, White stag and Green moth reuse the approved hosts with distinct native
state presentation; they are not five new animal species.

Only art sources, concepts, recipes and evidence are affected here. World stock,
spawns, damage, AI, attack clocks, body shapes, saves and normal game assets stay
authoritative. Generation runs in fresh ignored build folders and independent
processes. No new package, external service or paid inference is required.

## First production batch: six regular enemies

| Existing ID / role | Approved ordinary animal | Design and existing role connection |
| --- | --- | --- |
| `cinder_archer` / mark, fire projectile | Porcupine | Grounded broad-nosed animal; a few reinforced shoulder quill rows act as a grown launching comb. Charred keratin and narrow ember fractures. No carried bow, hands or new volley. |
| `stone_husk` / frontal guard | Bighorn ram | Upright lean animal with longer visible legs, a tucked belly and two substantial curling mineralised horns. Frontal protection lives in horn roots and forehead; the torso stays unarmoured. No new ram-charge mechanic. |
| `shrieker` / recruit | Crane | Grounded long-legged bird with folded wings and a supported expanded throat resonator. Readable beak, ordinary eyes, sparse recessed throat/keel scars. No flight or sonic damage. |
| `gloom_crawler` / swarm | Ground beetle | Low quick insect, six distinct jointed legs, supported mandibles and a split dark carapace carrying thin mineral scars. No spider anatomy or new tunnelling. |
| `bog_lurker` / root | Dragonfly nymph | Heavy aquatic insect with six short strong legs, squat segmented abdomen and compact folded labium. Bog-iron encrustation and mineralised seam margins; no wings, new grab range or bleed change. |
| `hollow_knight` / ward | Tortoise | Living reptile beneath a weathered hollow-ribbed mineral shell. Broad open arches above intact scutes express a protective mantle; supported neck/feet, pale narrow seams. No floating armour or new shield rule. |

The first armadillo concept was rejected in chat as too close to the boar.
Preserve that v01 as rejected history; the distinct bighorn ram v02 establishes
the approved ancestry and v03 is its stronger source. The rejected armadillo
was not sent to TRELLIS.

Names and inherited Kind associations remain. Scar palette is an aesthetic
proposal and does not classify an ordinary enemy into an LF colour policy.
Anatomy must not imply that the existing attack is a new combat mechanic.
The old upright 0.35 m radius / 1.3 m height enemy capsule has known mismatches;
do not claim these new silhouettes fit or alter it to make a test pass.

## Small production plan and review boundary

1. Generate one clean full-body concept/source per regular enemy; retain exact
   prompts, originals and hashes. Check anatomy, silhouette, natural ancestry,
   negative space and scar construction before local generation.
2. Generate untouched resolution-1024, seed-42 candidates through the installed
   pinned local TRELLIS runtime. Preserve the input/cutout/export, logs and hashes.
3. Inspect actual imported geometry in Blender from front, side, rear and three
   quarters, in clay and source materials. Record missing/fused anatomy and
   compare against the concept. Reopen the editable inspection source.
4. Show concept and actual mesh evidence in chat. Owner selection of the
   individual designs precedes expensive deformation/animation finishing and
   normal-world adoption, as in the existing reference-library process.
5. Continue selected candidates through anatomical repair, attached scar/flow
   masks, fitted rigs/poses, measured detail levels and Godot native adapters.
   Source generation alone does not complete those later checks.

Boss continuation stays tracked: give the Tyrant and Ash Warden distinct
animal-based major forms within their existing claw/breath/guard roles; finish
the Conservator as an intentionally augmented human with readable channel
gestures. Do not invent another boss, origin story, phase or encounter. The
current regular-mob batch establishes the remaining animal vocabulary first.

## Deferred environment work

The proposed ART-05B ground/understory/scenery and distance-cost polish remains
noted, explicitly deferred by the owner. ART-05's isolated route remains
technically delivered; no visual approval or global adoption is inferred from
this change of priority. Preserve its results and the original high-quality
authoring process.

## Approved era-art direction; concrete variants still to design

Use the existing three-era campaign. Preserve ordinary anatomy recognisability
while adding increasingly uncomfortable structural growth: scar lips become
raised, plates displace, organs distort and secondary scar branches cross into
previously quiet tissue. Reserve visual space and separate attachment regions
for additions during source finishing. Do not make all silhouettes spiky.

Candidate progression for later visual comparisons, not installed game rules:

| Base host | Era two proposal | Era three proposal |
| --- | --- | --- |
| Porcupine | A second distorted dorsal growth ridge extends behind the already swollen shoulder roots | Additional hip/tail keratin growth and a deeper connected flank scar network, preserving ordinary face and coat |
| Ram | An uneven occipital/upper-neck brace grows to support the altered horn load | Secondary horn buttresses and mineralised shin ridges extend the distortion while retaining a lean unarmoured torso |
| Crane | Hollow enlarged feather roots and small pneumatic ribs spread into the folded wing shoulders | Additional keel/back resonator growth connects to the already distorted throat, retaining two legs and grounded habits |
| Beetle | Thick joint collars and mineralised mandibular roots add to the already displaced wing case | Secondary shell folds expose deeper abdominal layers, retaining exactly six mobile legs |
| Nymph | A mineralised ventral keel and thoracic plaques supplement the ruptured abdomen | Rooted lateral crust lobes and deeper connective seams spread between body segments, retaining six legs without abdominal limbs |
| Tortoise | A second ossified collar and pelvic shell growth supplement the irregular upper mantle | Uneven buttressed underside/upper shell layers surround the same visible living reptile |

Keep the existing LF host influences and statuses separate from campaign-era
augmentation. Extra anatomy is presentation: no extra hit, projectile, limb
hurtbox, density, new era or saved geography is implied. The original animal,
existing warning footprint and actual work/combat clocks remain legible.

## Evidence and limitations

The [actual source report](../art/leyline-studies/2026-09-09/roster-art06/README.md)
and [concept history](../art/concepts/creatures/2026-09-09-roster/README.md) retain
the full result. Six stronger textured GLBs, six packed Blender inspection
sources and a twelve-source earlier/stronger Godot comparison are delivered in
`build/roster-art06/roster-source-handoff/`. All raw/input hashes remain exact;
42 packed-source reopening checks and 102 static-source checks in each renderer
pass. The first stronger nymph generated eight legs and was rejected; a revised
dorsal input produced the inspected six-legged v04. Tests were not weakened.

Current sources range from 282,612 to 296,116 triangles and have no rigs,
animations or emission maps. Porcupine whiskers, ram coat/growth joins, crane
throat asymmetry, insect fine cavities and tortoise cleanup remain explicit
finishing work. Extra era anatomy, boss art, deformation quality, body fit,
native gameplay adoption and populated-world performance are not complete.
The design/source stage is ready for review; the entire roster is not marked
finished merely because generation and static import succeeded.

The subsequent “Continue next” selects further finishing from the actual source
gallery. [ART-06B](roster-scar-materials-2026-09-09.md) now delivers individually
fitted dark damage, shallow safe incisions, narrow travelling light and an
isolated six-creature comparison. Raw sources remain unchanged; the new surface
exports and editable Blender files are separate. Source/map, actual pixel,
pause and both-renderer checks pass. Detailed anatomy repair, rigs and later-era
forms remain open before native adoption.
