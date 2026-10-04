# Nucleus — Well-Rounded Template Roadmap

Target engine: Godot 4.7.x.

This roadmap tracks the baseline that should exist before Nucleus stops growing
by default and moves primarily into hardening, examples, and optional plugins.

## Baseline status

### Core / application infrastructure — complete

```text
application lifecycle
platform/path normalization
logging/diagnostics
settings
input
runtime rebinding
local multiplayer device routing
audio/music/one-shots
save slots/encryption/migrations/autosave
scene flow/transitions
localization
general utilities
optional EventBus
optional NetworkHandler
```

### Production UI — complete baseline

```text
settings bindings
focus/navigation helpers
motion/feedback
screen effects
modal patterns
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

Iteration 17 completes the last major gameplay-composition layer planned for the
general baseline.

## Next milestone — Iteration 18

Iteration 18 should prioritize trust and developer experience rather than another
large gameplay system.

### Automated tests

Add headless coverage for at least:

```text
Settings persistence
Input binding serialization/rebinding
Save codec/integrity/backups/migrations
ValuePool boundaries/overflow
FSM transitions
GameplayAction transaction/cost rollback
Attributes modifier ordering
Status stacking/timers
Pooling acquire/release/reset
Targeting ownership/filter/ranking
Animation adapter smoke tests
Camera feedback source ownership
```

### Example / validation scenes

Create independent removable examples:

```text
2D gameplay composition
3D gameplay composition
settings + input rebinding
save/load
local multiplayer
actions + status + attributes
pooling + targeting
animation + game feel
UI/accessibility showcase
```

Examples should double as smoke-test fixtures where practical.

### Editor configuration warnings

Add `_get_configuration_warnings()` to high-value editor-facing components.

Examples:

```text
missing ValuePool
ambiguous auto-discovery
missing AnimationTree
missing feedback pivot
missing target point
missing Action
invalid save profile
missing InputMap action
```

The goal is to surface composition errors before pressing Play.

### CI / export smoke tests

At minimum:

```text
headless project import
test suite
static formatting checks
Windows export smoke test
Linux export smoke test
Web export smoke test
```

Windows/Linux/Web remain important compatibility targets.

## Baseline completion rule

After Iteration 18 passes cleanly, Nucleus should be considered a well-rounded
general project foundation.

Do not keep adding systems to the baseline merely because a game somewhere may
need them.

A new baseline feature should require evidence that it is:

```text
cross-genre
repeated across projects
difficult enough to justify centralization
compatible with current dependency boundaries
```

Otherwise it belongs in a plugin/module or in the game itself.

## Optional modules after the baseline

High-value candidates:

```text
Inventory / Equipment
AI / Navigation helpers
weighted probability / loot tables
persistent world identity
save-slot presentation UI
platform services
online gameplay replication
dialogue / quests
world streaming
```

These should remain opt-in.

## Dedicated plugin horizon

The following ideas are explicitly outside the Nucleus baseline:

```text
Day / Night + Environment
Planet Generator
Terrainy
```

See:

```text
docs/roadmap/plugin_horizon.md
```

They are substantial enough to deserve independent architecture, versioning,
documentation, tests, and editor workflows.

## Productization

Before a public 1.0-style release, also establish:

```text
top-level README
license
changelog
semantic versioning policy
Godot compatibility policy
deprecation policy
CI
examples
installation instructions
API stability expectations
```

The objective is for a developer to understand how to use Nucleus without
understanding how every subsystem is implemented.
