# Gameplay Foundation Contract

## Scope

```text
components/gameplay/resources
components/gameplay/combat
components/gameplay/interaction
components/gameplay/timing
components/gameplay/lifecycle
components/gameplay/state
```

All systems in this document are scene-owned composition pieces. None requires a
global gameplay manager.

## ValuePool and regeneration

`NucleusValuePool` is a bounded numeric pool for health, stamina, mana, shield,
fuel, or another game-defined quantity.

It intentionally has no combat semantics.

Important behavior:

- values clamp to minimum/maximum by default;
- optional overflow has an explicit limit;
- `decrease()` preserves remaining overflow instead of discarding it;
- `set_limits()` can preserve normal-range ratio;
- capture/restore state is local and serialization-format agnostic;
- threshold signals report depletion, fill, and overflow transitions.

`NucleusRegenerator` consumes the ValuePool API and owns regeneration timing.
This is composition:

```text
ValuePool + Regenerator
```

rather than a specialized Health class.

## Combat

`NucleusHitPayload` carries hit data.

`NucleusDamageReceiver` converts accepted payload damage into a ValuePool
decrease and owns invulnerability/immunity policy.

2D/3D hitboxes and hurtboxes use Godot's collision/area facilities. Keep hit
detection separate from damage storage.

A typical health composition is:

```text
ValuePool
+ DamageReceiver
+ optional Regenerator
+ Hurtbox
```

## Interaction

Interaction components discover/represent interactable targets and invoke their
contract. Use local signals and direct references when producer and consumer
already share scene ownership.

Do not route ordinary nearby interaction through the global EventBus.

## Cooldown and lifetime

Cooldown and lifetime are generic timing components. They should remain
mechanic-agnostic and reusable by actions, spawned objects, UI, or game-specific
logic.

## State machine

`NucleusStateMachine` owns one scene-local FSM.

States encapsulate behavior and transition hooks. Other systems integrate by
observing state changes or using explicit action requirements/effects.

Animation is a consumer of state through the AnimationTree adapters; the FSM
does not own animation playback.

## Editor validation

Iteration 18 adds editor configuration warnings to `NucleusRegenerator`.
Missing pool wiring is surfaced before Play while runtime auto-resolution is
preserved.

## Persistence

Only state that a game needs to persist should be captured into its save
document. Timers and transient collision overlap state should normally be
reconstructed after scene load.
