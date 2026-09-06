# Crafting at the current station

Implemented from the owner's [6 September playtest feedback](playtest-feedback-2026-09-06.md): put recipes that can be made first and stop mixing unrelated benches into the current catalogue. This is a presentation change within D-026's existing crafting and ingredient-navigation rules.

`ForgeCatalogue` now lists hand recipes and the current station family. A forge retains its basic and improved recipe previews, including skill-, era- or ingredient-locked work. Undiscovered rare-component recipes remain visible at their workbench. Field crafting shows only hand recipes and starts in a category containing actual hand work.

An Improved Forge also lists its existing higher-grade work on wooden equipment whose Rough recipe belongs to the workbench. Those cards say **Sound forging** and open at that native grade. Their visibility does not depend on owning ingredients or meeting smithing progression; the normal preview explains unmet requirements. This preserves the approved ability to improve a favourite wooden base without mixing its ordinary bench assembly into the forge list.

Within the selected category and search, recipes whose default local native `craft_preview` is ready come first, then blocked recipes. Each group uses display-name order, with recipe ID as the tie-break. Readiness uses the native plan, including wood reserved as an ingredient before spare fuel is counted. Opening another station family clears the previous search, selection and navigation history. Crafting refreshes the cards against the remaining stock.

Explicit ingredient and better-grade links still open a reference with the existing back path and station instruction. Such a reference does not add unrelated recipes to the ordinary card list, and its Make button retains the existing physical-station check. Pins, handcraft costs, batch validation, recipes, inputs, XP, grades, save data and native crafting rules are unchanged. No tuning values or new gates were introduced.

Implementation: `game/scripts/forge_catalogue.gd` and the two crafting-open hooks in `game/scripts/work_panel.gd`.

Verification used an isolated project and existing DLL, without touching the owner's running game or saves:

- `crafting_catalogue.tscn`: **34 checks, zero failures**. Actual cards cover bench/yard/forge/hand membership, craftable-first ordering and refresh, locked local projects, explicit cross-station references, fuel reservation, exact Make payments, and higher-grade wooden forging at the Improved Forge.
- Existing `forge_progression.tscn`: **35 checks, zero failures**, including catalogue bounds at 720p/1080p, grade/ingredient navigation, pins, payment and mastery.
- Existing `build_usability.tscn`: **39 checks, zero failures**.

All three error logs were empty. These checks establish catalogue behaviour and existing layout bounds; the owner's next playtest will establish whether the smaller lists and clearer ordering are sufficient guidance.
