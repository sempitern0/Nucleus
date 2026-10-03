# Optional Event Bus

`NucleusEventBus` is deliberately not part of the default Core Autoload set.

Godot signals remain the preferred communication mechanism when a producer and
consumer have a natural relationship.

## When it is useful

An EventBus is reasonable when:

- optional modules should not import each other;
- a domain object is not naturally connected to the emitting Node;
- several independent systems observe a high-level application event;
- a project explicitly wants a global mediator.

It should not become a replacement for every local signal.

## Scene-owned usage

```text
GameSession
└── EventBus : NucleusEventBus
```

Then pass the bus explicitly to systems that need it.

## Optional Autoload usage

A developer may manually add:

```ini
NucleusEvents="*res://modules/event_bus/event_bus.gd"
```

Nucleus itself does not add this entry.

## API

```gdscript
bus.subscribe(&"match_started", _on_match_started)

bus.subscribe(
    &"damage_registered",
    _on_damage_registered,
    100,
)

bus.subscribe_once(
    &"bootstrap_completed",
    _on_bootstrap_completed,
)

bus.publish(
    &"match_started",
    match_id,
)
```

Higher priority runs first. Subscribers with equal priority retain registration
order.

Deferred subscriptions schedule their callback through the bus Node rather than
calling it immediately.

## Event history

History is disabled by default:

```gdscript
max_history_length = 0
```

When enabled, one record is stored per publication, not per subscriber.

This avoids the OmniKit behavior where one event with ten listeners created ten
history entries.

## Differences from OmniKit

Retained:

- `StringName` event ids.
- priorities;
- one-shot listeners;
- deferred listeners;
- optional history.

Corrected:

- listener sorting now uses `priority`, not object id;
- callbacks are compared as Callables, so two methods on one object are distinct;
- invalid Callables are pruned automatically;
- mutation during publication is safe because delivery uses a snapshot;
- one-shot listeners are removed before invocation, making re-subscription safe;
- history records publications rather than leaking listener internals.
