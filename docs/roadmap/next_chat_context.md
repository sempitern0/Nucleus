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

## Runtime validation status

Iterations through **Iteration 16 — Targeting + Sensing** have been applied by
the project owner and validated in Godot with no errors/warnings.

Iteration 17 should only be marked runtime-validated after the owner confirms
it.

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
optional EventBus
optional NetworkHandler
```

### UI

```text
production UI composition
settings bindings
focus/navigation
motion
feedback
screen effects
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
```

### Iteration 17 design

Iteration 17 adds:

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

It also normalizes documentation into:

```text
docs/components/
    technical API/contracts

docs/architecture/
    design rationale/reuse audits

docs/guides/
    public Godot-editor workflows

docs/roadmap/
    roadmap + portable chat context
```

## Key architecture already established

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

## Natural next step after Iteration 17

**Iteration 18 — Production hardening**

Prioritize:

```text
automated/headless tests
example/validation scenes
_get_configuration_warnings()
CI
Windows/Linux/Web smoke exports
documentation consistency audit
```

Do not add another large gameplay subsystem before this hardening pass unless a
runtime bug requires repair first.

## Optional modules after baseline hardening

Candidates:

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

These should be opt-in.

## Future independent plugins

Do not integrate these into the Nucleus baseline:

### Day / Night + Environment

Barebone contains a previous system with time/day zones, sun/sky configs and
presets. Re-audit it later as a separate plugin.

### Planet Generator

Barebone contains procedural planet assets/shaders under
`components/3D/space/planets`. Rebuild later as a specialized plugin.

### Terrainy

Barebone has `addons/terrainy`.

Product direction:

```text
fast editor terrain generation
professional default quality
optimized output
minimal manual painting
presets/biomes
strong quickstart workflow
```

It should NOT attempt to become Terrain3D.

A future Terrainy iteration requires a deep audit of generation, LOD/chunking,
materials, vegetation, collision, editor UX, low-end/Web profiles, and
performance.

See:

```text
docs/roadmap/plugin_horizon.md
```

## Decision rule

When considering any new feature, first ask:

1. Is it broadly reusable across genres?
2. Does Godot already solve it?
3. Does Nucleus already expose a helper/component that should be reused?
4. Does it belong in Core, scene-owned Components, an optional module, or a
   separate plugin?
5. Does the abstraction remove repeated work without hiding useful Godot
   behavior?

The baseline should remain coherent even if that means saying no to useful but
project-specific features.
