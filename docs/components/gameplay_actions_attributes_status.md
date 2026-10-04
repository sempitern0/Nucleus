# Gameplay Actions, Attributes, and Status Effects Contract

## Scope

```text
components/gameplay/actions
components/gameplay/attributes
components/gameplay/status
```

These systems form Nucleus's reusable gameplay transaction/modifier layer.

## GameplayAction pipeline

The committed action pipeline is:

```text
requirements
→ costs
→ effect prevalidation
→ pay
→ cooldown
→ commit
→ effects
```

This ordering matters. Requirements and effect prevalidation happen before
payment. Once the action reaches commit, effects execute against the committed
context.

Actions support source-owned blockers and context providers. This allows
equipment, targeting, status effects, AI, or a game-specific producer to add
context without turning GameplayAction into a dependency hub.

Representative extension contracts include:

```text
NucleusActionRequirement
NucleusActionCost
NucleusActionEffect
NucleusActionContextProvider
```

Prefer a new small requirement/cost/effect Resource or Node over subclassing the
entire action execution pipeline.

## Attributes

Attributes represent runtime numeric values derived from a base plus modifiers.

Modifier ownership is source-based. A producer can add modifiers and later
remove exactly the modifiers it owns.

This is important for clean composition:

```text
StatusEffect source
Equipment source
temporary buff source
game-specific source
→ Attribute
```

Bindings project attribute values onto engine/gameplay properties without
making the attribute system own those consumers.

`NucleusValuePoolAttributeBinding` uses `ValuePool.set_limits()` so pool clamping
and signals remain authoritative.

## Status effects

Status effects are one producer of modifiers and periodic behavior.

The container owns active effect instances, duration/stacking state, and removal.
Definitions describe reusable effect policy.

Periodic pool changes are performed through the existing ValuePool API rather
than writing pool internals.

## Ownership and cleanup

Blockers, context, and modifiers must be removed by the source that added them.
This prevents orphaned state after equipment removal, effect expiry, pooling, or
scene teardown.

## Persistence

Persist durable gameplay state at the game layer using stable IDs and plain data.
Do not serialize live Node references, Callables, timers, or modifier-source
objects directly.

## Extension rule

If a new mechanic can be expressed as a requirement, cost, effect, context
provider, modifier source, or status definition, extend that seam instead of
adding another central gameplay manager.
