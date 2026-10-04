# Nucleus Gameplay Components

Target engine: Godot 4.7.x.

These components are reusable gameplay primitives, not game rules.

They are scene-owned, optional, and composable.

## Structure

```text
components/gameplay/
├── combat/
│   ├── damage_receiver.gd
│   ├── hit_payload.gd
│   ├── hitbox_2d.gd
│   ├── hitbox_3d.gd
│   ├── hurtbox_2d.gd
│   └── hurtbox_3d.gd
├── interaction/
│   ├── interactable.gd
│   ├── interaction_area_2d.gd
│   ├── interaction_area_3d.gd
│   ├── interaction_candidate_tracker.gd
│   ├── interaction_input.gd
│   └── interactor.gd
├── lifecycle/
│   └── lifetime.gd
├── resources/
│   ├── regenerator.gd
│   └── value_pool.gd
├── state/
│   ├── state.gd
│   └── state_machine.gd
└── timing/
    └── cooldown.gd
```

No component is an Autoload.

## Composition over one giant health component

A typical health setup is:

```text
Player
├── Health                # NucleusValuePool
├── DamageReceiver
├── Regenerator           # optional
└── Hurtbox2D / Hurtbox3D
```

The same pool can instead represent:

```text
stamina
mana
shield
fuel
oxygen
temperature budget
ability resource
```

The pool does not know what damage means.

`NucleusDamageReceiver` does not know what death means.

Game code listens to:

```gdscript
health.depleted.connect(_on_died)
```

This keeps death, respawn, ragdoll, score, achievements, and networking out of a
generic numeric component.

## Value pools

`NucleusValuePool` provides:

```text
minimum
maximum
optional overflow
increase / decrease
fill / empty
ratio
overflow ratio
depleted / filled signals
snapshot capture / restore
```

Overflow is explicit. Normal calls clamp at `maximum_value`; callers must opt
into overflow when increasing.

This makes overheal/shield-like behavior possible without making it the default.

## Regeneration

`NucleusRegenerator` operates on a `NucleusValuePool`.

It supports:

```text
fixed amount per tick
tick interval
delay after negative pool delta
time-scale policy
optional overflow
```

The timer implementation uses Godot `Timer` directly.

Nucleus does not wrap Timer globally because Timer is already the appropriate
engine abstraction.

## Cooldowns

`NucleusCooldown` provides the behavior that projects repeatedly implement
around Timer:

```gdscript
if cooldown.try_start():
    use_ability()
```

It adds:

```text
try_start
restart
cancel
remaining time
normalized progress
optional progress signal
time-scale policy
```

while delegating actual timing to Godot Timer.

## Combat contact model

Nucleus separates physical hit detection from damage application:

```text
Hitbox2D / Hitbox3D
        │
        ▼
NucleusHitPayload
        │
        ▼
Hurtbox2D / Hurtbox3D
        │
        ▼
DamageReceiver
        │
        ▼
ValuePool
```

`NucleusHitPayload` is runtime data:

```text
amount
source Node
hitbox Node
StringName tags
metadata Dictionary
```

This supports project concepts such as:

```text
fire
ice
melee
projectile
critical
environment
```

without Nucleus defining those tags.

`NucleusDamageReceiver.immune_tags` uses `NucleusArrayUtils.intersects()` rather
than duplicating collection logic.

## Collision layers

Nucleus does not reserve a global physics layer.

Configure project collision layers in:

```text
Project
→ Project Settings
→ Layer Names
→ 2D Physics / 3D Physics
```

Then place hitboxes on the chosen hit layer and set hurtbox masks to see it.

This replaces Barebone's dependency on `Globals.hitboxes_collision_layer`.

## Interaction model

Interaction is split into:

```text
NucleusInteractable
    → what can be interacted with

NucleusInteractor
    → candidate/current selection

InteractionArea2D/3D
    → physical overlap detection

NucleusInteractionInput
    → input routing
```

The world interaction component never polls the global Input singleton.

For single-player, `NucleusInteractionInput` listens to normal unhandled input.

For couch multiplayer, bind the already existing:

```text
NucleusLocalPlayerInput
```

and the component consumes that player's routed `input_received` stream.

The default action is:

```gdscript
NucleusInputActions.INTERACT
```

so the component reuses the semantic action already shipped by Nucleus.

## Candidate selection

The default selector is deterministic:

1. Ignore unavailable interactables.
2. Pick the highest `priority`.
3. Keep registration order for equal priorities.

Projects that need camera-facing scoring, distance weighting, or raycast
targeting can build another detector/selector around the same
`NucleusInteractor` API without changing `NucleusInteractable`.

## State machine

`NucleusStateMachine` is intentionally smaller than Barebone Machina.

A normal tree is:

```text
StateMachine
├── Idle
├── Move
└── Attack
```

Each state derives from:

```gdscript
NucleusState
```

and may override:

```text
can_enter
can_exit
enter
exit
update
physics_update
handle_input
handle_unhandled_input
```

Transition identity uses `StringName` state ids.

```gdscript
request_transition(&"attack")
```

The state machine sets `current_state` before the new state's `enter()` hook.
This makes state ownership consistent inside the hook.

Reentrant transitions are rejected with `ERR_BUSY`.

## Save integration

State-bearing components expose explicit snapshot APIs where it is useful.

Example:

```gdscript
save_session.register_participant(
    &"player_health",
    health.capture_state,
    health.restore_state,
)
```

Likewise:

```gdscript
save_session.register_participant(
    &"door_interaction",
    interactable.capture_state,
    interactable.restore_state,
)
```

The components do not discover `NucleusSaveSession` globally.

This preserves the explicit participant model already used by Nucleus Save.

## Lifetime

`NucleusLifetime` is a narrow auto-despawn component.

Typical use:

```text
VFX
└── Lifetime

Projectile
└── Lifetime
```

It uses a native one-shot Timer and queues the configured target for deletion.

It does not implement pooling. A future object-pool system should be a separate
ownership model rather than overloading lifetime semantics.
