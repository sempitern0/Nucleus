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
viewport/window/screenshot helpers
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
surface-aligned 3D decals
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

Iteration 18 established automated tests, validation fixtures, editor warnings,
documentation coverage, GitHub Actions, and Linux/Windows/Web smoke exports.

The hardening layer is operational rather than merely proposed.

## Iteration 19 — productization / first-project readiness

Iteration 19 established:

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

Nucleus remains pre-1.0 until a real game provides enough evidence to stabilize
the public API.

## Iteration 20 — proven presentation reuse

Two small Barebone-era capabilities passed the baseline rule:

```text
surface-adaptive native Decal placement
stateless Viewport screenshot capture
```

They were redesigned around current Nucleus boundaries rather than copied
verbatim.

The development version after the presentation additions was:

```text
0.2.0-dev.1
```

## Iteration 21 — optional Inventory / Equipment

The first post-Core optional gameplay module provides:

```text
immutable item definitions
explicit item catalog
UUID-backed runtime stacks/instances
scene-owned inventories
slot and weight limits
scene-owned equipment
data-driven equipment slots
Attribute modifier integration
GameplayAction item requirements/costs
capture/restore persistence
```

It is not an Autoload and does not define inventory UI, crafting, loot, economy,
or replication.

Development version:

```text
0.3.0-dev.1
```

Recommended next module:

```text
Probability / Loot
```

Loot should consume/produce generic IDs/definitions rather than depend on a
specific game inventory UI or pickup implementation.

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
Probability / Loot
Persistent world identity
AI / Navigation helpers
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
