# Optional Modules Quickstart

This page is the module selection map.

For a first-use recipe for every optional module, see:

[`tutorials/modules_first_steps.md`](tutorials/modules_first_steps.md)

## EventBus

Use the EventBus only when you intentionally need mediator semantics.

Add `modules/event_bus/event_bus.tscn` to the scope that should own it. Promote
it to an Autoload only for genuine cross-scene events.

Prefer a normal signal for direct/local relationships.

## Networking

Add `modules/networking/network_handler.tscn` to the scope that should own peer
lifecycle, or configure it as an Autoload in a game that genuinely needs
cross-scene connection lifetime.

Choose transport explicitly:

```text
ENet
    native desktop/server use

WebSocket
    browser-compatible client path
```

The module does not implement gameplay replication, RPC design, authentication,
lobbies, or matchmaking.

## Inventory / Equipment

`modules/inventory` is data/runtime infrastructure and does not require an
Autoload.

Typical ownership:

```text
Player
├── Inventory
└── Equipment

Chest
└── Inventory
```

See:

```text
docs/guides/inventory_equipment_quickstart.md
```

## Probability / Loot

`modules/loot` uses Godot's native `RandomNumberGenerator` and adds reusable
loot-table semantics.

Typical ownership:

```text
Enemy
└── LootRoller

Chest
└── LootRoller
```

Loot does not require Inventory.

See:

```text
docs/guides/loot_quickstart.md
```

## Persistent World State

`modules/world_state` gives authored/runtime world objects stable identity and
explicit cross-scene state.

If the game replaces whole level scenes, its `NucleusWorldStateService` must live
outside those scenes.

Use either:

```text
persistent GameSession
```

or intentionally add:

```text
modules/world_state/world_state.tscn
```

as an opt-in Autoload.

This service is not added to the default Nucleus project.

See:

```text
docs/guides/persistent_world_quickstart.md
```

## AI / Navigation

`modules/ai` composes Utility AI with Godot `NavigationAgent2D/3D`.

It intentionally reuses:

```text
NucleusTargetingAgent
NucleusStateMachine
Godot NavigationServer
```

instead of introducing another perception system, another FSM, or custom
pathfinding.

Typical 3D ownership:

```text
Enemy
├── NavigationAgent3D
├── NavigationFollower3D
├── TargetingAgent
├── UtilityBrain
├── StateMachine
└── AIStateMachineBridge
```

There is no AI Autoload.

See:

```text
docs/guides/ai_navigation_quickstart.md
```

## Online Gameplay Replication

`modules/networking/replication` complements Godot's native multiplayer
replication instead of replacing it.

Use:

```text
MultiplayerSpawner
    spawn / despawn

MultiplayerSynchronizer
    discrete replicated state

NucleusNetworkIntentChannel
    client → server gameplay requests

NucleusNetworkTransformReplicator2D/3D
    optional remote transform smoothing
```

The default contract is server-authoritative.

See:

```text
docs/guides/online_replication_quickstart.md
```

## Platform Services

`modules/platform_services` provides only:

```text
provider lifecycle
local platform identity
capability discovery
standalone fallback
```

It has no dependency on GodotSteam, EOS, or console SDKs.

A game integrates those through a thin `NucleusPlatformProvider` adapter.

See:

```text
docs/guides/platform_services_quickstart.md
```

## Keep optional modules optional

The default Nucleus `project.godot` intentionally does not load these modules.

A game that does not use one should pay no runtime architectural cost for it.

For concrete first-use code and scene ownership, continue with:

[`tutorials/modules_first_steps.md`](tutorials/modules_first_steps.md)
