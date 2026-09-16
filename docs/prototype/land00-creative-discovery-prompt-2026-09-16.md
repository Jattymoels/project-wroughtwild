# LAND-00: creative discovery, research and world vision

Act as Wroughtwild's creative director, game designer and research partner for
one high-effort ideation session. Think deeply, explore unusual possibilities,
research relevant precedents, then make clear recommendations. This session
comes BEFORE LAND-01 and the provisional implementation slices, and informs them.

Workspace: `D:/Wroughtwild/work/land00-creative-discovery`, branch
`codex/land00-creative-discovery`. Read `build/land00/SETUP.md`.
Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and follow its
required reading order. This newer owner-authorised discovery task supersedes
the narrower LAND-01 planning brief for this session. The six-slice outline and
fractured-highland starting region are suggestions to challenge, not fixed answers.

## Context and ambition

Wroughtwild is a one-person indie prototype combining exploration, survival,
building, crafting and character-build expression. A meteorite catastrophe
carrying alien augmentation technology transformed the landscape and ordinary
animal hosts. The present world is years later: established life has reclaimed
much of the damage, while coloured currents and living fractures remain.

White/Impulse, Red/Excitation, Blue/Retention and Green/Propagation are existing
working foundations. Their influence should connect land, growth, fauna and the
capabilities the player eventually learns to use. Read the current world premise
and implemented systems; old roadmap proposals may already be superseded.

The recent RF-01–09 wave delivered playable foundations, lakes, vegetation and
material improvements, but the world still lacks the desired awe and distinctness.
I want memorable environments, more biome types, substantial magical fractures,
interesting discoveries and places that make me excited to build a home.
World generation, terrain form, asset design, ecology, lighting and gameplay may
all contribute. Better scatter and texture alone are unlikely to fulfil this.

Use `docs/world-premise.md`, the current coordination sheet, RF-09's actual game
pictures, the original owner environment references/wording and relevant system
specs as grounding. Inspect enough code to understand consequential constraints.
Avoid turning discovery into a full-project audit or merely defending the current
implementation. Understand both the fantasy and the actual player loop.

## Creative exploration

Begin with what the player should see, feel, discover and decide. Explore broadly
before converging. Consider landscape-scale spectacle, biome identity, altered
ecologies, readable magical causes, fauna relationships, traversal, discovery,
base siting and how the player learns to work the force that changed the world.
Include distinctive new mechanics or encounters where they create meaningful play.
Distinguish those proposals from already approved gameplay.

Look for a few signature ideas that could make Wroughtwild recognisable. Explain
the player action or decision each creates, how it connects to existing systems,
and why it remains interesting after the first reveal. Include introductions to
these ideas through exploration and early play, as well as their later payoff.
Avoid a collection of unrelated gimmicks or a disguised list of familiar features.

Give biome proposals more than names and palettes: landform, vegetation structure,
fauna, sound/motion, resources or opportunities, hazards where useful, transitions
and reasons to explore or settle. Distinguish biome identity from local influence
and era/history. Explore how the same force changes different hosts, how it is
recognisable across rock, roots and creatures, and where quiet/recovered areas
provide contrast. Do not default to a version of every creature in every colour.

Preserve the game's underlying identity while allowing bold proposals. If an idea
requires changing an accepted rule, identify that explicitly rather than quietly
rewriting it. Greater visual ambition can come from composition, scale and strong
design as well as production complexity. Seek disproportionate player value for
a solo developer. Allow an ambitious stretch idea when its payoff merits it.

## Research that informs original design

Browse the web for relevant game-design, environment-art and procedural-world
precedents. Prefer developer talks, postmortems, technical/art breakdowns and
official material. Natural geology/ecology or other creative fields may supply
useful ideas too. Select sources for what they teach this project; avoid a broad
link collection or generic list of popular games.

For each useful precedent, explain the underlying principle, the player experience
it supports, how Wroughtwild might adapt it, and the costs or tradeoffs. Cite
specific sources with links. Separate documented facts, your interpretation and
your original proposals. Do not claim originality merely because an idea was
generated here, or claim that an unseen video/source was reviewed. Synthesize
influences into a coherent identity rather than copying another game's package.

## Develop alternatives, then make a recommendation

Develop three meaningfully different creative directions. For each, provide:

- Its central promise and two or three signature world/gameplay ideas.
- A short player journey: a first encounter, a discovery, a reason to return,
  and an attractive building opportunity.
- An evocative region/biome example showing land, growth, fauna and influence
  working together, including how the player learns what the place is doing.
- The generation, art and gameplay work it needs; the main uncertainty and a
  plausible smallest playable demonstration.

Compare the directions for distinctiveness, discovery/building appeal, coherence,
seeded variety, production burden and ability to expand. Then recommend one
direction or a disciplined synthesis. Make choices and explain tradeoffs; do not
return every possibility as equally desirable. List attractive ideas deliberately
left out so they do not silently inflate the selected vision.

Define how the recommended world gets composed across random seeds: large forms,
biomes, influence distribution, landmarks, useful paths and appealing home sites.
Distinguish authored reusable pieces from procedural rules. Explain the relationship
to existing normal V8 play and Living Frontier systems. Preserve existing saves
as an implementation constraint; future changed geography may need a new profile.
Plan the concept/Blender/material/game pipeline where substantial new art is needed.
Do not select a new service, paid dependency or engine migration by implication.

## Output and working style

Use this as a substantial thinking/research session, not a ten-minute triage.
Prototype limits still rule out exhaustive verification and speculative engineering.
There is no need for game tests, imports, new benchmark runs or package rebuilding.
Use retained runtime evidence. No mouse control or automatic game launches.

Deliver a concise owner-facing recommendation backed by a fuller design record:

1. The recommended creative vision and the player experiences that make it matter.
2. Research findings with useful sources and explicit Wroughtwild adaptations.
3. The three alternatives, their comparison and your reasons for choosing.
4. The recommended biome/influence/ecology relationships and signature ideas.
5. One or two useful annotated layouts or visual direction boards. Follow the
   imagegen skill if generating concepts; label targets clearly as concepts,
   separate from actual game screenshots. Display visuals directly in chat.
6. A revised, prioritised slice roadmap with a visible outcome per slice. Treat
   the previous six-slice estimate as provisional. Identify a strong first playable
   demonstration and the concrete brief LAND-01 should resolve next.
7. The few consequential owner choices still needed, each with your recommendation.

Save the main record as
`docs/prototype/land00-creative-discovery-result-2026-09-16.md`, retain useful
visuals beside it, and update the coordination sheet briefly. Keep scratch and
large outputs in this D: workspace. Commit only the useful planning deliverables
after link/source/diff checks and return the SHA for coordinator adoption.

Ask only when a missing answer would materially change the exploration. Otherwise
make labelled assumptions and continue until the recommendations are concrete and
reviewable. Do not rush to the first plausible idea or ask me to invent the vision
for you. Be candid about weak ideas, uncertainty and production cost.

Stop after research, ideation and planning. Do not implement features, mark your
proposals as accepted decisions, start LAND-01/other workers or resume historical
ART R9. I will assess this direction with the coordinator before implementation.
