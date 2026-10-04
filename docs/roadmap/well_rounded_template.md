# Nucleus — Well-Rounded Template Roadmap

Target engine line: Godot 4.7.x.

Release-gated reference: Godot 4.7.2-stable.

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

## Iteration 18 — production hardening validated

Iteration 18 added:

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

After test-infrastructure fixes, Nucleus CI passed on:

```text
285ba33a81a001647c79e2b0aef10303039a9e4e
```

The hardening layer is therefore operational rather than merely proposed.

## Iteration 19 — productization / first-project readiness

The productization layer establishes:

```text
top-level README
MIT license
changelog
Nucleus VERSION source of truth
semantic versioning policy
Godot compatibility policy
deprecation policy
installation instructions
API stability expectations
reproducible source-template release packaging
productization CI audit
```

Initial version:

```text
0.1.0-dev.1
```

Nucleus remains pre-1.0 until a real game provides enough evidence to stabilize
the public API.

## Baseline completion rule

The general reusable baseline is complete.

Further baseline additions require evidence that they are:

```text
cross-genre
repeated across projects
difficult enough to justify centralization
compatible with current dependency boundaries
not already solved well by Godot
```

Otherwise they belong in an optional module/plugin or in the game itself.

## Next phase — use Nucleus in a real game

The preferred next step is not another broad subsystem.

Start the planned game from a pinned Nucleus version/commit and use production
friction to drive changes.

Classify new requirements as:

```text
baseline defect
reusable baseline gap
optional module/plugin
game-specific system
```

Only proven baseline defects/gaps should expand the default template.

## Optional modules after hardening

Candidates remain:

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

These should remain opt-in unless cross-project evidence proves otherwise.

## Dedicated plugin horizon

Keep these outside the baseline:

```text
Day / Night + Environment
Planet Generator
Terrainy
```

See `docs/roadmap/plugin_horizon.md`.
