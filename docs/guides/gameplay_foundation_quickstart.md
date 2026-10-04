# Gameplay Foundation Quickstart

## Health/stamina/mana/fuel

Add a `Node` with `NucleusValuePool`.

Configure:

```text
minimum_value
maximum_value
overflow_limit
initial_value
```

Add `NucleusRegenerator` as a child of the ValuePool for automatic target
resolution, or assign `target_pool` explicitly.

Iteration 18 shows an editor warning if neither wiring path is present.

## Damage

Add `NucleusDamageReceiver` and wire its target pool when auto-discovery would be
ambiguous.

Use Hitbox/Hurtbox components matching the scene dimension.

Keep the roles separate:

```text
collision detects a hit
HitPayload describes it
DamageReceiver applies policy
ValuePool stores the quantity
```

## Cooldowns/lifetime

Add the generic timing/lifecycle component instead of embedding duplicate Timer
bookkeeping into every mechanic.

## FSM

Add `NucleusStateMachine` with game-specific states.

Let movement/actions/etc. request or observe state changes. Let the animation
adapter consume FSM state rather than calling animations from every state.

## Interaction

Use the existing interaction components/contracts for nearby interactables and
keep communication local where possible.

## Validation scenes

Open:

```text
examples/validation/gameplay_2d.tscn
examples/validation/gameplay_3d.tscn
```

to inspect minimal resource/regeneration/targeting composition.
