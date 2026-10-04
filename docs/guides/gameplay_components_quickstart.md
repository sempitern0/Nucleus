# Gameplay Components — Godot Editor Quickstart

This guide focuses on integrating the components from the Godot editor.

For architecture and internal API contracts, see:

```text
docs/components/gameplay.md
```

## 1. Health in 2D or 3D

Create this under the actor:

```text
Player
├── Health
├── DamageReceiver
├── Regenerator
└── Hurtbox
```

### Health

1. Add a Node called `Health`.
2. Attach `components/gameplay/resources/value_pool.gd`.
3. Set:
   - minimum: `0`
   - maximum: `100`
   - initial: `100`
4. Optional: configure overflow for overheal/shield-like behavior.

### Damage receiver

1. Add a Node called `DamageReceiver`.
2. Attach `components/gameplay/combat/damage_receiver.gd`.
3. Drag `Health` into `target_pool`.
4. Optional: configure post-hit invulnerability.

### Hurtbox

Use an `Area2D` or `Area3D`.

Attach:

```text
hurtbox_2d.gd
```

or:

```text
hurtbox_3d.gd
```

Add normal Godot collision shapes.

In Project Settings create a physics layer such as `Hitboxes`, then configure
the hurtbox collision mask to see that layer.

Connect death behavior in the actor script:

```gdscript
func _ready() -> void:
    %Health.depleted.connect(_on_died)
```

Nucleus does not decide what `_on_died()` means.

## 2. Create a damaging object

Create an Area with a collision shape:

```text
SwordHitbox : Area3D
└── CollisionShape3D
```

Attach:

```text
components/gameplay/combat/hitbox_3d.gd
```

Set:

```text
amount = 25
tags = ["melee"]
```

Put the Area on the physics layer your hurtboxes monitor.

For 2D use `NucleusHitbox2D`.

The hitbox and hurtbox now produce a `NucleusHitPayload` and the receiver removes
value from the target pool.

## 3. Add regeneration

Add a child Node with:

```text
components/gameplay/resources/regenerator.gd
```

Assign the Health pool.

Example:

```text
amount_per_tick = 2
tick_interval = 0.5
delay_after_decrease = 3
```

After damage, regeneration waits three seconds and then restores two points
every half-second.

## 4. Cooldown an ability

Add:

```text
Ability
└── Cooldown
```

Attach `components/gameplay/timing/cooldown.gd`.

Then:

```gdscript
func try_cast() -> void:
    if not %Cooldown.try_start():
        return

    cast_spell()
```

Enable `emit_progress` only if UI or gameplay actually needs continuous progress
events.

## 5. Auto-delete a transient object

Add `NucleusLifetime` below a projectile or effect.

```text
ExplosionVFX
└── Lifetime
```

Set duration in Inspector.

If the game uses slow motion but the VFX should disappear in real time, enable
`ignore_time_scale`.

## 6. Area interaction

Player tree:

```text
Player
├── Interactor
│   └── InteractionInput
└── InteractionArea3D
    └── CollisionShape3D
```

1. `Interactor`: attach `interactor.gd`.
2. `InteractionInput`: attach `interaction_input.gd`.
3. `InteractionArea3D`: attach `interaction_area_3d.gd`.
4. Drag the Interactor reference into the area/input components.
5. Configure the area mask to see the project's interactable layer.

World object:

```text
Door
├── Interactable
└── InteractionArea / body used for overlap
```

Attach `interactable.gd` to the `Interactable` Node.

Connect:

```gdscript
%Interactable.interacted.connect(_on_interacted)
```

The default input action is the existing Nucleus:

```gdscript
NucleusInputActions.INTERACT
```

### Couch multiplayer

After players join:

```gdscript
var player_input: NucleusLocalPlayerInput = (
    local_input_session.get_player(player_index)
)

interaction_input.bind_local_player_input(player_input)
```

Do not duplicate `Input.is_action_pressed()` per player. The existing
`NucleusLocalInputSession` already routes discrete events by hardware device.

## 7. Interaction prompts

Listen to:

```gdscript
interactor.current_changed.connect(_on_interactable_changed)
```

Then:

```gdscript
func _on_interactable_changed(
    current: NucleusInteractable,
    _previous: NucleusInteractable,
) -> void:
    prompt.visible = current != null

    if current:
        prompt.text = current.get_prompt_text()
```

For gamepad glyph text, combine this with the existing
`NucleusLocalPlayerInput.get_binding_text()` API.

## 8. State machine

Editor tree:

```text
Enemy
└── StateMachine
    ├── Idle
    ├── Chase
    └── Attack
```

1. Attach `state_machine.gd` to `StateMachine`.
2. Attach scripts derived from `NucleusState` to Idle, Chase, Attack.
3. Set `initial_state` to Idle in the Inspector.

Example state:

```gdscript
class_name EnemyIdleState
extends NucleusState


func enter(
    _previous_state: NucleusState,
    _context: Dictionary,
) -> void:
    owner.velocity = Vector3.ZERO


func physics_update(_delta: float) -> void:
    if can_see_target():
        request_transition(&"Chase")
```

State ids default to Node names.

For a stable explicit id, set `state_id` in the Inspector.

Avoid changing state synchronously from another state's `enter()` hook. Reentrant
transitions return `ERR_BUSY`; use `call_deferred()` if an immediate follow-up
transition is genuinely necessary.

## 9. Save a pool or interaction count

Because Nucleus Save already uses explicit participants:

```gdscript
save_session.register_participant(
    &"player_health",
    %Health.capture_state,
    %Health.restore_state,
)
```

For a one-use chest:

```gdscript
save_session.register_participant(
    &"chest",
    %Interactable.capture_state,
    %Interactable.restore_state,
)
```

No gameplay component needs direct knowledge of the save file format.
