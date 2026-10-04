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

Target engine:

```text
Godot 4.7.x
```

Nucleus is a clean reusable Godot foundation/template for new games.

The objective is professional cross-project infrastructure and composition, not
a toolkit containing every mechanic found in any game.

## Working style

- Inspect current `main` before every iteration.
- Reuse existing Nucleus APIs instead of duplicating behavior.
- Prefer Godot-native features over wrappers.
- Composition over inheritance for game-facing systems.
- Scene-owned systems unless cross-scene lifetime truly requires an Autoload.
- No Service Locator.
- Local signals before global EventBus.
- EventBus and NetworkHandler remain optional/not loaded by default.
- No Barebone backward compatibility requirement.
- Public `class_name` names use `Nucleus` prefix.
- GDScript: tabs, <=100 columns, LF, final newline.
- Generate a delta ZIP; do not mutate GitHub unless explicitly requested.
- Perform static checks and state clearly when Godot runtime was not available.

## Repository checkpoint used for Iteration 18

Iteration 18 was prepared read-only against:

```text
main
4c8936ff26d96a4167c1ca2997217900e5345faf
```

Commit message:

```text
uid files for new gameplay components
```

No GitHub changes were made while producing the delta.

## Runtime validation status

Iterations through **Iteration 16 — Targeting + Sensing** were previously
reported by the owner as validated in Godot with no errors/warnings.

Iteration 17 must remain marked runtime-validation pending until the owner
confirms it.

Iteration 18 is implemented in the delta but also remains runtime-validation
pending. The generation environment did not provide a Godot executable/export
templates.

## Implemented foundation

### Core

```text
Application lifecycle
platform/path normalization
Logging/diagnostics
Settings
Input + rebinding
local multiplayer input ownership
Audio
Save/encryption/migrations/autosave
Scene flow
Localization
utilities
```

### Optional modules

```text
EventBus
NetworkHandler / LAN helpers
```

Neither is loaded by default.

### UI

```text
production UI composition
settings bindings
focus/navigation
motion
feedback
screen effects
modal/toast/tooltip
layout/presentation/data helpers
accessibility-oriented helpers
```

### Gameplay

```text
ValuePool / regeneration
DamageReceiver / Hitbox / Hurtbox
Interaction
Cooldown / Lifetime
StateMachine
Movement 2D/3D
Camera 2D/3D
GameplayActions
Attributes / modifier sources
Status Effects
Object Pooling / Spawners
Targeting / Sensing
AnimationTree integration
camera/game-feel feedback
```

## Iteration 17

Iteration 17 added:

```text
AnimationTree adapters
FSM → AnimationTree state
CharacterBody velocity → animation parameters
GameplayAction → AnimationTree state / OneShot
Animation method-track event relay

shared NucleusMotionPolicy
stackable camera feedback 2D/3D
source-owned continuous offsets
impulse profiles
recoil/kick/shake
head bob
landing feedback
source-owned temporary FOV offsets
```

It normalized documentation into:

```text
docs/components/
    technical API/contracts

docs/architecture/
    design rationale/reuse audits

docs/guides/
    public Godot-editor workflows

docs/modules/
    optional-module contracts

docs/roadmap/
    roadmap + portable chat context
```

## Iteration 18 — Production hardening

The delta adds:

```text
tests/headless/
    native dependency-free GDScript runner
    SemVer coverage
    ValuePool coverage
    networking utility coverage

tests/smoke/
    mandatory Autoload / engine bootstrap smoke scene

examples/validation/
    removable 2D and 3D composition scenes

_get_configuration_warnings()
    Regenerator
    TargetAreaSensor2D
    TargetAreaSensor3D
    AnimationTreeStateBinding

scripts/ci/
    static checks
    documentation coverage audit
    Godot installer
    disposable smoke export driver

.github/workflows/nucleus-ci.yml
    headless import
    tests
    smoke scene
    Linux/Windows/Web exports

docs/documentation_coverage.json
    machine-checkable coverage for every direct Core/Module/Gameplay/UI
    subsystem

recovered docs
    Core
    Gameplay
    UI
    optional modules
    quickstarts
    baseline architecture
    hardening architecture
```

The CI pins `4.7.2-stable` within the target Godot 4.7 line.

## Key architecture

### GameplayAction pipeline

```text
requirements
→ costs
→ effect prevalidation
→ pay
→ cooldown
→ commit
→ effects
```

Actions support source-owned blockers and context providers.

### Attributes

Runtime numeric attributes use source-owned modifiers.

Status Effects are one modifier producer; future Equipment may be another.

### Pooling

Pools are scene-owned and type-specific.

No global PoolManager.

Spawners use reserve → transform → activate.

### Targeting

Sensors register source-owned candidates.

Filters decide validity.

Scorers rank.

TargetingAgent owns current/lock state.

Targeting integrates with Actions, Interaction, local multiplayer, Status
Effects, and pooled projectile contexts.

### Documentation

One source of truth:

```text
technical behavior → docs/components/
optional module contract → docs/modules/
editor workflow → docs/guides/
design rationale → docs/architecture/
future/status → docs/roadmap/
```

`python3 scripts/ci/documentation_audit.py` fails when a direct subsystem
directory is not mapped to documentation.

## Validation required after applying Iteration 18

Run:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py

godot --headless --path . --import

godot \
  --headless \
  --path . \
  --script res://tests/headless/test_runner.gd

godot \
  --headless \
  --path . \
  res://tests/smoke/smoke_main.tscn
```

Then run CI or `scripts/ci/smoke_exports.sh` with official export templates.

Only after these pass should Iteration 18 be marked runtime-validated.

## Natural next step after Iteration 18

Do not immediately add another baseline subsystem.

First:

1. apply the delta;
2. execute Godot/CI validation;
3. repair any runtime/export issue discovered;
4. confirm Iteration 17 and 18 validation status in the handoff.

After that, new work should primarily be opt-in modules/plugins or
productization.

## Optional module candidates

```text
Inventory / Equipment
AI / Navigation helpers
Probability / Loot
Persistent world identity
Save-slot UI
online gameplay replication
platform services
dialogue / quests
world streaming
```

## Independent plugin horizon

Do not integrate these into the Nucleus baseline:

```text
Day / Night + Environment
Planet Generator
Terrainy
```

See `docs/roadmap/plugin_horizon.md`.

## Decision rule

When considering a feature:

1. Is it broadly reusable across genres?
2. Does Godot already solve it?
3. Does Nucleus already expose a helper/component that should be reused?
4. Is its correct home Core, scene-owned Components, optional module, plugin, or
   the game itself?
5. Does the abstraction remove repeated work without hiding useful Godot
   behavior?

The baseline should remain coherent even if that means saying no to useful but
project-specific features.
