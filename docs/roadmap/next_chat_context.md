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

Nucleus development version after Iteration 24:

```text
0.6.0-dev.1
```

Source of truth:

```text
VERSION
```

Nucleus uses Semantic Versioning independently from the consuming game's
application version.

## Runtime / CI status

Iterations through 23 were validated by the user.

Iteration 24 remains runtime-validation pending until Godot parses and executes
the new AI / Navigation suite and the normal CI/export pipeline succeeds.

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

Roadmap candidate:

```text
Save-slot presentation UI
```

However, after AI / Navigation the template is already broad enough that the
planned real game should increasingly decide whether remaining optional modules
are worth implementing before production starts.

Potential later candidates remain:

```text
Save-slot presentation UI
online gameplay replication
platform services
dialogue / quests
world streaming
```

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
