# Optional Modules Quickstart

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

Use `NucleusItemCatalog` as explicit shared definition data.

Equipment may reuse `NucleusAttributeSet` modifier sources and Inventory stack
identity without teaching either baseline system about item gameplay.

See:

```text
docs/guides/inventory_equipment_quickstart.md
```

## Keep optional modules optional

The default Nucleus `project.godot` intentionally does not load these modules.

A game that does not use one should pay no runtime architectural cost for it.
