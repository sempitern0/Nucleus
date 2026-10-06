# Pooling and Targeting Quickstart

## Pooling

Place one `NucleusObjectPool` for one reusable scene/type in the owning gameplay
scene. Use the matching spawner when placement matters.

Expected lifecycle:

```text
acquire/reserve
→ set transform/context
→ activate
→ use
→ release/reset
```

Do not introduce a global PoolManager just to access unrelated pools.

## Targeting

Add a `NucleusTargetingAgent` to the actor/system that owns selection.

For area sensing:

```text
TargetingAgent
└── Sensor (Area2D or Area3D + NucleusTargetAreaSensor*)
    └── CollisionShape*
```

Assign the agent explicitly when the hierarchy contains more than one plausible
agent. Add filters for validity and scorers for ranking.

## Editor warnings

Area sensors warn when:

- neither bodies nor areas are enabled;
- no enabled collision shape exists;
- `agent` is empty and runtime resolution may be ambiguous.

These are design-time diagnostics. They do not replace runtime guards.

## Integrations

Use existing target requirement/context integrations for actions instead of
running a second physics query inside every action.

When spawning pooled projectiles, pass target/action context during the
reserve/configure/activate phase.
