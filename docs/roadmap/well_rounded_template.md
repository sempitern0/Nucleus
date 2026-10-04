# Nucleus — Roadmap to a Well-Rounded Game Template

This roadmap describes what remains after Iteration 14.

The objective is not to make Nucleus contain every system a game might need.
The objective is to make the starting point strong enough that new projects
mostly implement game rules/content rather than infrastructure.

## Current foundation

Nucleus already covers the most expensive cross-project foundations:

```text
application lifecycle
platform/path normalization
settings + editor bindings
input + rebinding + local multiplayer
audio + music + one-shot pooling
save slots + encryption + migrations + autosave
scene flow
localization
diagnostics
general utilities
optional EventBus
optional networking bootstrap/LAN discovery

production UI primitives
accessibility-oriented UI behavior

ValuePool / regeneration
damage / hitbox / hurtbox
interaction
cooldowns / lifetime
state machines
movement 2D/3D
camera 2D/3D
gameplay actions
attributes / modifiers
status effects
```

At this point the main architectural layers are present.

The remaining work should mostly improve production workflow, presentation, and
commonly reused game-facing systems.

---

# Tier 1 — Before calling the baseline well-rounded

These are the remaining systems with the highest cross-project return.

## 1. Spawn + object pooling

Recommended next gameplay infrastructure.

Needed primitives:

```text
NucleusObjectPool
NucleusPoolable
NucleusSpawner2D
NucleusSpawner3D
optional pooled lifetime adapter
```

Requirements:

- scene-owned pools;
- PackedScene factories;
- bounded/unbounded policies;
- prewarm;
- activate/deactivate hooks;
- transform-safe 2D/3D spawn;
- deterministic cleanup on scene exit;
- no global pool registry by default.

Why:

```text
projectiles
impact VFX
enemies
pickups
floating text
temporary props
```

occur across many genres.

`NucleusLifetime` should gain an adapter that returns an object to its pool
instead of always queue_free(), rather than changing Lifetime ownership itself.

## 2. Targeting + sensing

Interaction currently covers overlap candidates, but reusable gameplay also
frequently needs:

```text
raycast target acquisition
nearest target
screen/angle filtering
line of sight
target priorities
lock-on
2D/3D sensing
```

Build on:

```text
NucleusInteractor
NucleusNodeUtils
Godot RayCast2D/3D
ShapeCast2D/3D
PhysicsDirectSpaceState
```

Do not create one combat-specific target manager.

A generic candidate/selector contract would also serve:

```text
AI
weapons
lock-on camera
interaction
abilities
```

## 3. Animation integration

Nucleus should not replace `AnimationPlayer` or `AnimationTree`.

What is missing is reusable glue:

```text
movement → AnimationTree parameters
StateMachine → AnimationTree state
Action execution → animation request
animation event → GameplayAction/state callback
```

Prefer adapters/bindings rather than a custom animation graph.

This prevents every project from rewriting:

```text
velocity.length() → blend_position
is_on_floor → condition
current state → travel()
```

## 4. Camera/gameplay feedback stack

Movement/Camera deliberately deferred presentation effects.

A reusable composition layer should cover:

```text
camera shake / trauma
recoil impulse
landing kick
head bob
FOV impulses
2D shake
screen feedback requests
```

Requirements:

- stackable sources;
- deterministic decay;
- reduced-motion policy integration;
- no direct dependency on weapons/damage;
- use existing Camera rigs and UI screen-effects layer.

## 5. Automated test and validation foundation

This is now more valuable than adding another gameplay subsystem.

Recommended:

```text
tests/
├── core/
├── gameplay/
└── integration/
```

With headless Godot tests covering:

```text
Save corruption/recovery/migrations
Settings persistence
Input serialization
ValuePool boundaries/overflow
Action transactions
FSM transitions
Attribute calculations
Status stacking/timing
local multiplayer routing
```

CI should at minimum:

```text
import project headlessly
run test suite
run formatting/static checks
```

This is required before treating Nucleus as a reusable long-lived foundation.

## 6. Example / validation scenes

Documentation is strong, but a reusable template benefits from executable
examples.

Suggested small scenes:

```text
UI showcase
save/settings showcase
2D gameplay showcase
3D gameplay showcase
local multiplayer showcase
actions/status showcase
```

Examples should be independent from Core and safe to delete.

They provide:

- regression smoke tests;
- editor discoverability;
- copyable compositions;
- proof that components connect correctly.

---

# Tier 2 — High-value optional modules

These should not be forced into every Nucleus project.

## 7. Inventory + equipment

This is now cheap to implement cleanly because Attributes exist.

Suggested optional module:

```text
ItemDefinition Resource
Inventory container
stack rules
equipment slots
equipment modifier sources
save adapter
UI data adapters
```

Equipment should contribute:

```text
equipment:<slot>
→ NucleusAttributeSet.set_modifier_source()
```

rather than inventing its own stat system.

Do not assume RPG item rarity, weight, durability, grids, crafting, or weapons
in the base contract.

## 8. AI + navigation primitives

Use native Godot NavigationAgent2D/3D.

Useful reusable pieces:

```text
perception/sensors
target memory
navigation movement adapter
steering helpers
FSM/Action integration
```

Avoid shipping a mandatory behavior-tree framework unless a real project need
justifies it.

The existing NucleusStateMachine + GameplayActions already provide a strong
small/medium AI foundation.

## 9. Probability / weighted selection / loot

Barebone contained useful probability experiments, but a global LootManager is
not appropriate.

Potential optional primitives:

```text
weighted table Resource
deterministic RNG injection
roll-without-replacement
loot table composition
```

Reuse `NucleusShuffleBag` where its semantics already fit.

Loot itself should remain an optional game module.

## 10. Persistent world identity

`NucleusUuid` exists, but no gameplay component currently assigns stable ids to
world entities.

An optional:

```text
NucleusPersistentIdentity
```

would help:

```text
world-object save state
cross-scene references
quest targets
spawned entity identity
network mappings
```

Do not force UUIDs onto every Node.

## 11. Save-slot UI / save presentation

The Save backend is substantially more capable than its user-facing tooling.

Useful generic UI:

```text
slot summary
timestamp
game version
metadata
corruption/recovery state
delete confirmation
optional thumbnail companion
```

This belongs in UI Components, not Save Core.

---

# Tier 3 — Project/category-specific modules

These improve coverage but should remain opt-in.

## Online multiplayer gameplay layer

Nucleus already has optional connection/bootstrap networking.

A full online gameplay framework would additionally require decisions about:

```text
authority
replication
prediction
rollback
lag compensation
host migration
matchmaking
dedicated servers
```

Those choices are genre/network-model specific.

Prefer separate modules/examples over putting them in Core.

## Dialogue / quests

Common, but content-model specific.

Could reuse:

```text
UUID
SaveSession
Localization
GameplayActions
Status/Attributes
```

but should not become a mandatory dependency.

## Platform services

Optional adapters for:

```text
achievements
cloud saves
rich presence
leaderboards
Steam/EOS/etc.
```

should live behind platform/provider-specific modules.

## World streaming

Needed for large/open-world projects, unnecessary for many others.

Build only when a project requires:

```text
chunk streaming
persistent cells
background loading
world partition
```

on top of Scene Flow and Save.

## Procedural generation

Keep external/specialized.

Nucleus should provide infrastructure, not a preferred procedural-generation
model.

---

# Production hardening before a 1.0-style release

Regardless of feature work, Nucleus should eventually add:

```text
README with installation/architecture entry points
LICENSE
CHANGELOG
semantic release/version policy
compatibility matrix for Godot versions
headless CI
Windows/Linux/Web export smoke tests
example project/scenes
API stability/deprecation policy
```

## Editor UX

Many existing Components currently report bad setup through `NucleusLog`.

A production-hardening pass should progressively add:

```gdscript
_get_configuration_warnings()
```

to editor-facing Components.

That lets the Godot Scene dock flag:

```text
missing target
ambiguous ValuePool
missing ActionSet
missing collision configuration
missing status definition
```

before running the game.

This is one of the highest-value quality-of-life passes remaining.

---

# Recommended sequence

After Status Effects + Attributes, the highest-return order is:

```text
15. Spawn / Object Pooling
16. Targeting / Sensing
17. Animation + Camera Feedback adapters
18. Automated Tests + Example Scenes + Editor validation
```

At that point Nucleus can reasonably be considered a well-rounded baseline for
starting diverse 2D/3D projects.

Then implement optional modules according to actual project demand:

```text
Inventory/Equipment
AI/Navigation
Probability/Loot
Persistent world identity
Save-slot UI
online gameplay
platform services
dialogue/quests
world streaming
```

The important boundary is that "well-rounded" does not mean "contains every
genre system".

It means the foundational systems compose cleanly enough that genre code starts
on top of Nucleus rather than rebuilding infrastructure underneath it.
