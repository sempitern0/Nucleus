# Nucleus — Well-Rounded Template Roadmap

Target engine: Godot 4.7.x.

Nucleus is a reusable project foundation, not a catalogue of every mechanic a
game could need.

## Baseline status

### Core / application infrastructure — complete

```text
application lifecycle
platform/path normalization
logging/diagnostics
settings
input + runtime rebinding
local multiplayer device routing
audio/music/one-shots
save/encryption/migrations/autosave
scene flow
localization
general utilities
```

### Production UI — complete baseline

```text
settings bindings
focus/navigation
motion/feedback
screen effects
modal/toast/tooltip patterns
layout/data/presentation helpers
accessibility-oriented behavior
```

### Gameplay composition — complete baseline

```text
ValuePool / regeneration
damage / hitbox / hurtbox
interaction
cooldowns / lifetime
FSM
2D/3D movement
2D/3D camera
GameplayActions
Attributes / modifier sources
Status Effects
pooling / spawners
Targeting / Sensing
AnimationTree integration
camera / game-feel feedback
```

### Optional infrastructure — available, not baseline-loaded

```text
EventBus
NetworkHandler / LAN helpers
```

## Iteration 17 — feature baseline complete

Iteration 17 added the final planned large baseline layer:

```text
AnimationTree adapters
FSM → AnimationTree state
CharacterBody velocity → animation parameters
GameplayAction → AnimationTree state / OneShot
animation event relay
shared motion accessibility policy
stackable source-owned camera feedback
recoil / kick / shake / head bob / landing feedback
temporary FOV offsets
```

It also established the current documentation model.

## Iteration 18 — implementation complete, runtime validation pending

The production-hardening delta adds:

```text
dependency-free headless GDScript tests
bootstrap smoke scene
2D/3D validation scenes
native editor configuration warnings
static source/style checks
machine-checkable documentation coverage
GitHub Actions validation
Linux/Windows/Web smoke exports
recovered documentation for Core/Components/Modules
```

The delta was prepared against `main` commit:

```text
4c8936ff26d96a4167c1ca2997217900e5345faf
```

Do not mark Iteration 18 runtime-validated until Godot executes the included
headless import/tests/smoke scene and smoke exports successfully.

## Baseline completion rule

Once Iteration 18 passes runtime/CI validation, Nucleus should be considered a
well-rounded general project foundation.

Further baseline additions require evidence that they are:

```text
cross-genre
repeated across projects
difficult enough to justify centralization
compatible with current dependency boundaries
not already solved well by Godot
```

Otherwise they belong in an optional module/plugin or in the game itself.

## Optional modules after hardening

Candidates:

```text
Inventory / Equipment
AI / Navigation helpers
Probability / Loot
Persistent world identity
Save-slot presentation UI
online gameplay replication
platform services
dialogue / quests
world streaming
```

These should remain opt-in.

## Dedicated plugin horizon

Keep these outside the baseline:

```text
Day / Night + Environment
Planet Generator
Terrainy
```

See `docs/roadmap/plugin_horizon.md`.

## Productization before a public 1.0-style release

Still establish/confirm:

```text
top-level README
license
changelog
semantic versioning policy
Godot compatibility policy
deprecation policy
installation instructions
API stability expectations
release packaging
```

CI, validation fixtures, and documentation coverage are now part of the
Iteration 18 hardening layer rather than deferred productization work.
