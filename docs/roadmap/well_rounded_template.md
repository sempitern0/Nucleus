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
Inventory / Equipment
Probability / Loot
Persistent World State
AI / Navigation
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

## Iteration 22 — optional Probability / Loot

The second post-Core optional gameplay module provides:

```text
weighted loot using Godot rand_weighted()
independent chance rolls
guaranteed entries
runtime unique entries
amount ranges
side-effect-free conditions
Resource payloads
scene-owned LootRoller
seeded deterministic generation
save/restore of RNG state and unique state
```

No global LootManager or generic probability wrapper is introduced.

Development version:

```text
0.4.0-dev.1
```

## Iteration 23 — optional Persistent World State

The third post-Core optional module provides:

```text
stable world region IDs
stable authored entity UUIDs
explicit state adapters
persistent removal semantics
runtime world-state store
scene reconciliation
persistent runtime PackedScene spawning
SaveSession integration
JSON-safe 2D/3D transform adapters
```

The state service remains opt-in. Cross-scene projects may intentionally keep it
under a persistent GameSession or promote its provided scene to an Autoload.

Development version:

```text
0.5.0-dev.1
```

## Iteration 24 — optional AI / Navigation

The fourth post-Core optional gameplay module provides:

```text
Utility AI intentions
context providers and normalized considerations
TargetingAgent context integration
StateMachine decision bridge
efficient NavigationAgent2D/3D followers
moving-target repath throttling
native RVO safe-velocity integration
NavigationLink extension signals
2D/3D patrol/wander goal producers
```

No AI manager, Enemy base class, Behavior Tree, perception duplicate, or
navigation replacement is introduced.

Development version:

```text
0.6.0-dev.1
```


## Iteration 25 — online replication / Platform Services

The final pre-game template iteration adds:

```text
server-authoritative gameplay intent channel
sequence and basic rate admission
2D/3D transform snapshot interpolation
native MultiplayerSpawner/Synchronizer guidance
provider-neutral platform lifecycle
platform user identity
platform capability discovery
standalone platform fallback
```

It also fixes release packaging source placement by moving the tracked script to:

```text
scripts/package_release.py
```

Development version:

```text
0.7.0-dev.1
```

No storefront SDK is added to Nucleus.

No prediction/rollback/lag-compensation framework is added without project
evidence.


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

## Next phase — freeze broad template work and build the real game

Iteration 25 is the pre-game checkpoint.

Start the planned game from a pinned Nucleus commit/release and use production
friction to drive further changes.

Classify every new requirement as:

```text
Nucleus defect
proven reusable Nucleus gap
optional provider/plugin integration
game-specific system
```

Do not expand Nucleus merely because a reusable-looking feature can be imagined.

Ideas such as:

```text
save-slot presentation UI
dialogue / quests
world streaming
prediction / rollback
provider achievement wrappers
```

should now wait for concrete project evidence.

## Dedicated plugin horizon

Keep these outside the baseline:

```text
Day / Night + Environment
Planet Generator
Terrainy
```

See `docs/roadmap/plugin_horizon.md`.
