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
- No Barebone compatibility aliases.
- Public `class_name` names use `Nucleus` prefix.
- GDScript: tabs, <=100 columns, LF, final newline.
- Generate a delta ZIP; do not mutate GitHub unless explicitly requested.
- Use CI/runtime results as the acceptance source of truth.

## Current checkpoint

Productization was prepared read-only against:

```text
main
285ba33a81a001647c79e2b0aef10303039a9e4e
```

That commit has a successful Nucleus CI run.

## Versioning

Nucleus template version:

```text
0.1.0-dev.1
```

Source of truth:

```text
VERSION
```

Nucleus uses Semantic Versioning independently from the consuming game's
version.

Policy:

```text
docs/policies/versioning.md
```

## Runtime / CI status

The Iteration 18 validation pipeline is operational.

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

Iteration 17-specific gameplay feel/animation behavior should still be judged in
the consuming game where subjective integration behavior can be exercised.

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

## Productization

The repository now has explicit contracts for:

```text
top-level README
MIT license
changelog
semantic versioning
Godot compatibility
deprecation
installation
API stability
release packaging
```

Key files:

```text
README.md
LICENSE
CHANGELOG.md
VERSION

docs/policies/
docs/guides/installation.md
docs/guides/releasing.md

scripts/ci/productization_audit.py
scripts/release/package_release.py
.github/workflows/nucleus-package.yml
```

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

### Documentation

One source of truth:

```text
technical behavior → docs/components/
optional module contract → docs/modules/
editor workflow → docs/guides/
cross-cutting product promises → docs/policies/
design rationale → docs/architecture/
future/status → docs/roadmap/
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

godot \
  --headless \
  --path . \
  res://tests/smoke/smoke_main.tscn
```

Then run CI for smoke exports.

## Natural next step

Use Nucleus as the base of the planned real game.

Do not immediately add another broad baseline subsystem.

When the project exposes a need, decide whether it is:

1. a Nucleus defect;
2. a reusable Nucleus API gap;
3. an optional module/plugin;
4. game-specific.

Only the first two should automatically change the baseline.

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
