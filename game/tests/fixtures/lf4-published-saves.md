# Published LF4 checkpoints retained for Wave 5

Frozen before changing campaign/save code, from the independent LF4 review's
isolated `build/lf4/appdata/Godot/app_userdata/Wroughtwild` outputs. These contain
synthetic test worlds, no normal user saves. Gzip only compresses their bytes.

| Fixture | Origin / meaning | SHA-256 of uncompressed bytes |
| --- | --- | --- |
| `lf4-published-pending.json.gz` | `lf4-laboratory-boundary.json.previous`: real native first victory/return before publication | `b306449fd1d370f583a68372f97040fb3d96ceb479456d17eeed654450368d65` |
| `lf4-published-applied.json.gz` | `lf4c-campaign.json`: applied first event, spent Heart, depleted copper/partial tin, defeated Blue host | `748a3036f3720b80c1dfc6c6b488d61d352745d23d734afac9ff1c3ebde6fc22` |
| `lf4-published-paid-pending.json.gz` | `lf4a-pending.json`: isolated pending geometry proof with five paid pieces, open door/storage, excavation, cargo span and recovery | `7ffe334e16b4193763db1172ada50a12e6a08c1d85ea4d5aabea4c2bd2a12419` |
| `lf4-published-dormant.json.gz` | Controlled derivative of paid-pending: only first-event phase becomes dormant and seed becomes zero, using the original LF4 schema | `307d393ef63e3df03378e1df56e570991a9834ba744c6f324745073c2dad58fa` |

The dormant fixture is explicitly manufactured, not an archived ordinary
playthrough. The others retain the old harness's forced encounter outcomes or
supplied machine/recovery fixtures; they prove migration/ownership rather than
human combat. None contains a second-event field. See the
[Wave 5 verification contract](../../../docs/prototype/living-frontier-wave5-2026-09-09.md).

`lf5b-published-clear.json.gz` and `lf5b-published-boundary.json.gz` retain the
checked LF-5B intermediate format, before the second-event implementation.
They come from the complete Pairing controller walk's clear and suspended
boundary. The first has the once-only Eye/Pairing receipt, the second has no
victory and preserves the active deposit/loot boundary. These also deliberately
force outcomes; they are migration fixtures, not human combat evidence.
