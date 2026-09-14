# ART-07R2 publication - 14 September 2026

R2's isolated loading/residency candidate is checked and integrated by exact
fast-forward. The repair shares 723 byte-and-import-equivalent texture references,
retains complete material cache identities and reuses repeated tree-fit/terrain
queries. It introduces no production tuning values. The normal game is not switched
to this pilot by publication.

| Renderer | G1 median setup | R2 median setup | Reduction | Loaded textures saved |
| --- | --- | --- | --- | --- |
| Forward+ | 91.559 s | 58.742 s | 35.84% | 440.69 MiB |
| Compatibility | 87.130 s | 56.785 s | 34.83% | 498.67 MiB |

The publisher recomputed these results from 24 retained fresh processes with
three observations per version/mode/backend. These are current RTX 5090 measurements,
not minimum-hardware acceptance. R2 remains roughly 57-59 seconds to set up.

The [machine-readable record](publication-r2.json) contains the source pins,
complete publisher results, exact job arguments/log hashes and composition limits.
The [worker receipt](receipts/r2.md) retains its implementation evidence.

## Independent verification

All 5,701 G1 input files and 772 G2 evidence files were fully rehashed. The R2 seal
passed exact file-set, size and hash verification: 6,411 payload files and
9,091,108,107 bytes. The 38 Git paths are exclusively R2-owned. The implementation
commit matches sealed tools/documents exactly or by recorded CRLF normalization.

All 238 modified original files, two production additions and 53 evidence additions
agree with the change ledger. For 226 interchange derivatives, every non-image JSON
field and every GLB non-JSON chunk remains exact. All 723 texture aliases preserve
PNG bytes and complete import parameters. Nineteen inherited assertion replays and
display wrappers retain their original logic.

The publisher verified 110 successful worker process logs and seven retained failed
attempts, recalculated all 60 image/geometry comparisons, and inspected actual home
renders. Fifty-nine image pairs are byte-identical; the remaining pair differs by
one channel level at one pixel, with exact alpha and geometry. Existing G2 visual
findings remain open for their assigned repairs.

A fresh cache-free version was prepared and the exact sealed delta applied at
`D:/project-wroughtwild-art07-r2/build/art07-repairs/r2/v05/runtime`.
The unchanged GPU guard/private-state runner executed these actual publisher jobs:

| Job | Wall seconds | Exit |
| --- | --- | --- |
| import | 61.74 | 0 |
| reload-release-forward_plus-b | 198.41 | 0 |
| reload-restart-forward_plus-b | 76.07 | 0 |
| reload-release-gl_compatibility-b | 188.79 | 0 |
| reload-restart-gl_compatibility-b | 72.42 | 0 |

Each backend passed 43 native flow checks across three reload cycles and 14
separate-process restart checks. Real partial work, release/re-entry, depletion,
all six persisted owner fields and the saved geography agree. All 4,842 declared
runtime source files still match after the engine runs. The publisher replay is
verification, not another timing benchmark or an hours-long soak.

## Integration and remaining gates

Implementation: `ca370f52a20637548da0cf1fd04cdc9dbeb9c440`. Worker receipt: `96853630e714477f6ade849a0323a0af97cb033a`.
Both original commits are retained on main by fast-forward from `473ae76`.
Publication notes and the shared delivery index accompany an ordinary non-force
push to the approved `origin/main`; remote-tip verification is reported separately
after the push. [Publication checks](publication-r2-checks.json) cover the required
validators and preservation of unrelated checkout work.

G2-C01 is **partially addressed**, with the isolated repair technically verified.
Streaming spikes remain (single-run maxima about 437/456 ms), as does the
same-frame retirement error reproduced in unchanged G1. The Forward+ reload buffer
difference and sequential benchmark ordering remain documented. Duplicate PNG disk
bytes were retained; the saving is loaded texture memory. Owner visual acceptance,
minimum-device acceptance and combined R8/R9 measurements remain open.

R8 must compose R2's tree fit, surface projection, material keys and image references
with the other repairs by file/function and regenerate the final alias map.
All 273 legal building pairs, octagonal/chamfer/triangle support, native bodies,
finite stock, paid ownership and saved geography remain constraints.

R2 is the first published repair. R5-R7 remain gated until R1, R3 and R4 are also
checked and published. Their completion is not inferred from R2's delivery.
