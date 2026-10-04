# Nucleus — New Chat Handoff Context

Copy this document into a new conversation when continuing Nucleus development.

---

## Project

Repository:

```text
sempitern0/Nucleus
```

Default branch:

```text
main
```

Legacy/reference repository:

```text
sempitern0/Barebone
```

Nucleus is the successor/rework of Barebone, but there is no Barebone backward
compatibility requirement.

Target engine line:

```text
Godot 4.7.x
```

Release-gated reference:

```text
Godot 4.7.2-stable
```

Nucleus is a clean reusable Godot foundation/template for new games.

## Working style

- Inspect current `main` before every iteration.
- Reuse existing Nucleus APIs instead of duplicating behavior.
- Prefer Godot-native features over wrappers.
- Composition over inheritance for game-facing systems.
- Scene-owned systems unless cross-scene lifetime truly requires an Autoload.
- No Service Locator.
- Local signals before global EventBus.
- Optional modules are not loaded by default.
- No Barebone compatibility aliases.
- Public `class_name` names use `Nucleus` prefix.
- GDScript: tabs, <=100 columns, LF, final newline.
- Generate a delta ZIP; do not mutate GitHub unless explicitly requested.
- Use Godot/CI runtime results as the acceptance source of truth.

## Current checkpoint

Iteration 24 was prepared read-only against:

```text
main
3a5fa19ec9b2e6329798e054928e7e46c47c7390
```

That commit already contains the user-validated Persistent World State module.

## Versioning

Nucleus development version after Iteration 25:

```text
0.7.0-dev.1
```

Source of truth:

```text
VERSION
```

Nucleus uses Semantic Versioning independently from the consuming game's
application version.

## Runtime / CI status

Iterations through 23 were validated by the user.

Iteration 25 remains runtime-validation pending until the productization fix
allows CI to reach Godot parsing/tests and the new replication/platform suites
complete successfully.

Current CI covers:

```text
static source checks
documentation coverage
productization contract audit
Godot headless import
native test-graph parse
native regression tests
bootstrap smoke scene
Linux smoke export
Windows smoke export
Web smoke export
```

## Core

```text
Application lifecycle
platform/path normalization
logging/diagnostics
settings
input + rebinding
local multiplayer input ownership
audio
save/encryption/migrations/autosave
scene flow
localization
window / screenshot helpers
utilities
```

Mandatory Autoloads:

```text
NucleusApp
NucleusSettings
NucleusInput
NucleusAudio
NucleusSave
NucleusSceneFlow
```

## Gameplay baseline

```text
ValuePool / regeneration
damage / hitbox / hurtbox
interaction
cooldowns / lifetime
StateMachine
movement 2D/3D
camera 2D/3D
GameplayActions
Attributes / modifier sources
Status Effects
Object Pooling / Spawners
Targeting / Sensing
SmartDecal3D
AnimationTree integration
camera/game-feel feedback
```

## Optional modules

```text
EventBus
NetworkHandler / LAN helpers
Inventory / Equipment
Probability / Loot
Persistent World State
AI / Navigation
Online Gameplay Replication
Platform Services
```

None is loaded by default.

Persistent World State is the exception where an intentional game-level
Autoload can be appropriate when complete level scenes are replaced.

## Iteration 21 — Inventory / Equipment

Important contracts:

```text
NucleusItemDefinition
NucleusItemCatalog
NucleusItemStack
NucleusInventory
NucleusEquipment
```

Runtime stack lookup is:

```text
get_stack_by_id(stack_id)
```

Do not reintroduce `get_stack(stack_id)` because it collides with GDScript's
global `get_stack()` diagnostic function.

Equipment reuses `NucleusAttributeSet` modifier sources.

Save integration uses explicit `NucleusSaveSession` participants.

## Iteration 22 — Probability / Loot

Optional module:

```text
modules/loot/
```

Key rule:

```text
Loot Resources are configuration.
LootRoller owns RNG/runtime unique state.
```

Godot `RandomNumberGenerator` remains the probability source of truth.

Loot does not depend on Inventory.

## Iteration 23 — Persistent World State

Optional module:

```text
modules/world_state/
```

Key model:

```text
region_id + persistent_id
→ one persistent world record
```

Authored object identity never uses SceneTree paths.

Permanent removal is explicit:

```text
NucleusWorldEntity.remove_persistently()
```

Runtime persistent scenes use:

```text
NucleusWorldRegion.spawn_persistent()
```

WorldStateService must outlive replaced level scenes when cross-scene state is
required.

## Iteration 24 — AI / Navigation

Optional module:

```text
modules/ai/
```

Decision types:

```text
NucleusAIContextProvider
NucleusAIConsideration
NucleusAIContextBoolConsideration
NucleusAIContextFloatConsideration
NucleusAIUtilityOption
NucleusAIUtilityBrain
NucleusAITargetContextProvider
NucleusAIStateBinding
NucleusAIStateMachineBridge
```

Navigation types:

```text
NucleusNavigationPolicy
NucleusNavigationFollower2D
NucleusNavigationFollower3D
NucleusNavigationQueries2D
NucleusNavigationQueries3D
NucleusNavigationWander2D
NucleusNavigationWander3D
```

Responsibility split:

```text
TargetingAgent
    perception and selected target

UtilityBrain
    intention selection

StateMachine
    behavior execution

NavigationAgent
    native pathfinding / optional RVO

NavigationFollower
    path-follow orchestration and output velocity

CharacterBody / gameplay movement
    actual locomotion
```

No AIManager, Enemy base class, Behavior Tree, duplicate perception layer, or
custom pathfinder exists.

Moving targets are repathed only after distance and interval thresholds.

Utility ContextProviders can emit `context_changed`; the brain requests
reevaluation without requiring every NPC to evaluate every frame.

## Documentation

One source of truth:

```text
technical behavior → docs/components/
optional module contract → docs/modules/
editor workflow → docs/guides/
cross-cutting product promises → docs/policies/
design rationale → docs/architecture/
future/status → docs/roadmap/
```

Iteration 24 docs:

```text
docs/modules/ai_navigation.md
docs/guides/ai_navigation_quickstart.md
docs/roadmap/iteration_24.md
```

## Validation commands

Run:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py

godot --headless --path . --import

godot \
  --headless \
  --path . \
  --check-only \
  --script res://tests/headless/test_runner.gd

godot \
  --headless \
  --path . \
  --script res://tests/headless/test_runner.gd
```

Then run the normal smoke/export CI.

## Next decision

After Iteration 25, move to the planned real game and treat Nucleus as a pinned
production dependency/foundation.

Do not schedule another broad template iteration by default.

## Decision rule

When considering a feature:

1. Is it broadly reusable across genres?
2. Does Godot already solve it?
3. Does Nucleus already expose a helper/component that should be reused?
4. Is its correct home Core, Components, optional module, plugin, or the game?
5. Does the abstraction remove repeated work without hiding useful Godot
   behavior?

The baseline should remain coherent even when that means keeping useful
game-specific features outside Nucleus.


## Iteration 25 — final pre-game checkpoint

Prepared against:

```text
main
b5eb53138916d62681f16398b08eb37fde2c51fb
```

Productization CI root cause:

```text
.gitignore contains [Rr]elease/
→ scripts/release/ was ignored
→ package_release.py existed locally but not in GitHub checkout
```

Canonical packaging script is now:

```text
scripts/package_release.py
```

Keep the productization CI gate.

### Online gameplay replication

New public types:

```text
NucleusNetworkIntentChannel
NucleusNetworkSequenceTracker
NucleusNetworkRateLimiter
NucleusTransformSnapshotBuffer2D
NucleusTransformSnapshotBuffer3D
NucleusNetworkTransformReplicator2D
NucleusNetworkTransformReplicator3D
```

Native Godot remains responsible for:

```text
MultiplayerSpawner
MultiplayerSynchronizer
SceneReplicationConfig
RPC transport semantics
```

Default contract:

```text
client sends intent
server validates and simulates
server owns critical state
clients receive resolved replication
```

No generic prediction/reconciliation/rollback is included.

### Platform Services

New optional module:

```text
modules/platform_services/
```

Public types:

```text
NucleusPlatformCapabilities
NucleusPlatformUser
NucleusPlatformProvider
NucleusNullPlatformProvider
NucleusPlatformService
```

Nucleus standardizes only provider lifecycle, local identity, locale, and
capability discovery.

No GodotSteam/EOS/console dependency is included.

Use project/provider adapters around production integrations.

### Development policy after Iteration 25

Stop broad template expansion and move into the planned real game.

Further Nucleus changes should be driven by observed production friction rather
than roadmap completion.

## First production feedback — Nautica bootstrap

Observed against Nautica branch:

```text
codex/nautica-project-bootstrap
760b96058338c2a462af0e7e3e7afe5362e6a140
```

### Display settings

Nautica confirmed that the settings UI, catalog, persistence, binding, and
`NucleusDisplaySettingsApplier` path are present. `display/window_mode` already
reaches `DisplayServer.window_set_mode()` on desktop.

The apparent fullscreen failure while running from the Godot 4.7 editor is not
a missing Nucleus feature. Godot game embedding is enabled by default and does
not support window-mode/window-flag transitions.

Hardening derived from this production feedback:

```text
display applier
→ avoid unsupported embedded-editor window transitions
→ emit an actionable diagnostic
→ keep the preference persisted for the next non-embedded run
```

Validate fullscreen with **Embed Game on Next Play** disabled or in an exported
build. Do not write `ProjectSettings` at runtime to work around this limitation.

### Nucleus-first agent contract

Nautica also exposed coding-agent drift: game code duplicated
`Input.mouse_mode = ...` even though `NucleusCursor` already owns cursor mode.

The repository contract is now:

```text
search Nucleus first
→ use the existing Nucleus owner when one exists
→ otherwise prefer the native Godot API
```

A short root `AGENTS.md` provides the map for Codex/Astra, while
`scripts/ci/static_checks.py` mechanically rejects selected high-value bypasses
such as direct cursor-mode assignment and direct built-in display-setting
application outside their Nucleus owners.

This is production hardening, not a new broad template iteration.
