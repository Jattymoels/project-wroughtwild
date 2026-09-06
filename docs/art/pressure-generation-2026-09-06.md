# Native pressure-site generation — 6 September 2026

Native slice of the newly approved [pressure workshop](../prototype/leyline-extraction-proposal-2026-09-06.md), with the owner's siting correction: the place is an **old pre-cataclysm blacksmith ruin struck by an asteroid**. Its empowerment is accidental; no post-impact civilisation built a powered workshop there.

`frontier_v5` retains the finite 512 × 512 × 48 cell world. It reuses V4's complete supported landscape, finite resource population, existing approaches and six ruin foundations. The Ventlung-linked ruin becomes `ruv5_old_blacksmith`, with a small `imv5_blacksmith_strike` at its breached side and one short exposed `lyv5_blacksmith_accident` channel entering the old hearth. The sole pressure pocket is `ppv5_old_blacksmith`. These stable identities are scoped by world profile and seed.

The source record contains position, radius, old-smithy origin, accidental flag, ruin/impact/trace/discovery associations, an ordinary work position and its complete approach. **Generation contains no pressure stock.** Initial capacity, extraction, depletion, machinery drive and save transactions belong exclusively to `MachineWorld`; generating or displaying the source cannot replenish it. V5 has four impact records, ten traces, six ruins and one pressure pocket. Other visible traces remain decorative.

Seed 1: smithy centre `(127,14,160)`, source `(125,14,158)`, work position `(125,14,160)`, strike `(124,14,156)`, all native cells. Godot adds 0.5 m to X/Z for cell-centred points. The work position has a full supported 3 × 3 footprint and is 2 m from the source. It lies in the existing central three-metre strip; the side-wall presentation must keep the interaction ray open. The source-side asteroid uses the small strike composition, not generic scatter.

## Frozen compatibility

The exact previous live table is now `data/tuning/worldgen-frontier-v4.json`; only V5 selects live `worldgen.json`. The V4 helper file is unchanged. Legacy, V2, V3 and V4 select separate historical inputs and return no pressure pockets. Existing saved terrain, resources, excavation and depletion are not retrofitted.

Pre-change SHA-256 values, verified after the V5 implementation:

- V4 inputs: `BCA786C65CEAA3B149666CA292F9A1B0B1859817EE5B8976F619BE976C70734B`.
- V4 helper: `4C71EA6AC14D68AC2E31741A129E889B4F0B7C3351096BD655BBDE46D8DCFEDB`.

The complete V4 history fingerprints on seeds 1, 7, 24 and 91 are respectively `2777892313851358114`, `3704407159615029765`, `74627671584911170` and `16539691791317643557`. The new test also preserves all twelve earlier profile/seed fingerprints while deliberately corrupting live V5 inputs.

## Verification and limits

`pressure-generation` passes **16,831,577 checks** over 64 seeds: 1–32 and 32 widely separated larger seeds. Checks cover historical fingerprints, exact V4/V5 terrain/resource/ordinary-route equality, one reachable grounded source, the old-smithy strike association, exposed physical connection, native work clearance, unchanged Ventlung stock/workspace, finite normalized influence and definition-order independence. The shared historical fingerprint encoding was extracted without changing its behaviour; the existing V4 fixture now selects the frozen table explicitly.

The complete frozen V4 suite also passes **25,959,555 checks**, unchanged. Evidence: `build/pressure-native/baseline-fingerprints.txt`, `build/pressure-native/native-tests.log` and `build/pressure-native/frozen-v4-tests.log`. Builds use the established C++17 compiler with `-Wall -Wextra -Werror -O1`.

The `pressure_site` group in live worldgen tuning gives plain-language purposes and bounded validation for the pocket/strike radii, local influence, short trace width and three authored local offsets. It contains no economy or machine throughput numbers. Godot site bodies, feeder placement, source save restoration and actual operation belong to the integration review, not these native checks. No extra era, new world size, renewable source or broad factory is introduced.
