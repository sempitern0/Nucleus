# Iteration 25 — Online Replication / Platform Services / Final Pre-Game Checkpoint

## Objective

Close the remaining broadly reusable online/platform gaps before moving Nucleus
into a real production prototype.

This iteration also fixes the productization CI failure where the release
packaging script existed locally but was absent from GitHub Actions.

## Audited base

Prepared read-only against:

```text
sempitern0/Nucleus
main
b5eb53138916d62681f16398b08eb37fde2c51fb
```

That commit contains Iteration 24 AI / Navigation.

## Productization CI root cause

The audit required:

```text
scripts/release/package_release.py
```

but the repository `.gitignore` inherited this Visual Studio pattern:

```text
[Rr]elease/
```

Therefore:

```text
local working tree
    script exists and executes

Git index / GitHub checkout
    scripts/release directory is ignored
    script does not exist

productization CI
    correctly reports missing file
```

The solution is not to weaken or remove the productization gate.

The canonical script is moved to:

```text
scripts/package_release.py
```

The productization audit, release workflow, release guide, and historical
Iteration 19 documentation are updated accordingly.

The audit also checks whether required productization source files are ignored
by Git when it runs inside a Git checkout.

## Online gameplay replication

Godot remains the source of truth for:

```text
MultiplayerAPI
MultiplayerSpawner
MultiplayerSynchronizer
SceneReplicationConfig
RPC
```

Nucleus adds only:

```text
NucleusNetworkIntentChannel
NucleusNetworkSequenceTracker
NucleusNetworkRateLimiter
NucleusTransformSnapshotBuffer2D
NucleusTransformSnapshotBuffer3D
NucleusNetworkTransformReplicator2D
NucleusNetworkTransformReplicator3D
```

### Intent model

Default:

```text
client request
→ server admission
→ game-specific validation
→ authoritative mutation
→ replication
```

The channel includes controlling-peer validation, monotonic sequences, payload
shape limits, and fixed-window rate limiting.

The game must still validate semantic authorization.

### Transform model

Authority snapshots use an unreliable-ordered channel and local-arrival
interpolation.

There is no prediction, reconciliation, rollback, or lag compensation baseline.

Those require evidence from the real game's movement/combat model.

## Platform Services

New optional module:

```text
modules/platform_services/
```

Public API:

```text
NucleusPlatformCapabilities
NucleusPlatformUser
NucleusPlatformProvider
NucleusNullPlatformProvider
NucleusPlatformService
```

The abstraction deliberately stops at:

```text
provider lifecycle
identity
locale
capability discovery
```

There is no GodotSteam/EOS/console SDK dependency.

A consuming game can implement a provider adapter around a production plugin
without Nucleus mirroring the provider's entire API.

## Barebone reuse

No Barebone networking/platform implementation was found that improves the
current Nucleus design.

This iteration is built on the current Godot/Nucleus contracts rather than
porting legacy code.

## Version

```text
0.6.0-dev.1
→
0.7.0-dev.1
```

## Validation

Headless pure-contract tests cover:

```text
network sequence admission
network rate limiting
2D snapshot interpolation
3D snapshot interpolation
standalone platform provider
PlatformService delegation
```

The actual RPC/transport behavior still requires Godot headless/runtime
validation and, ultimately, multi-process project integration tests.

## Template checkpoint

After this iteration, stop broad baseline expansion.

Nucleus should now be exercised in the planned real game.

Future changes should be classified as:

```text
Nucleus defect
proven reusable Nucleus gap
optional provider/plugin integration
game-specific system
```

Do not implement the remaining roadmap ideas merely to complete a checklist.

Real project evidence now has higher value than more speculative framework code.
