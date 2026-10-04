# Gameplay Actions

Target engine: Godot 4.7.x.

Gameplay Actions are the orchestration layer between existing Nucleus gameplay
components.

They do not replace movement, state machines, resources, cooldowns, audio, or
camera systems. They coordinate them.

## Pipeline

One `NucleusGameplayAction` executes this pipeline:

```text
enabled / busy
      ↓
cooldown ready
      ↓
requirements
      ↓
cost affordability
      ↓
effect prevalidation
      ↓
pay costs
      ↓
start cooldown
      ↓
commit
      ↓
apply effects in tree order
      ↓
executed
```

All validation occurs before the commit point.

Costs are paid synchronously. If a later cost fails, previously paid costs are
refunded in reverse order.

Once the cooldown starts, the action is committed.

Custom effects should therefore respect this contract:

```text
can_apply() == OK
    ↓
apply() should normally succeed
```

An effect failure after commit is reported, but Nucleus does not attempt to
reverse arbitrary gameplay side effects.

## Scene composition

Example dash:

```text
Dash : NucleusGameplayAction
├── Cooldown : NucleusCooldown
├── StaminaCost : NucleusValuePoolCost
├── GroundedRequirement : NucleusStateRequirement
├── DashState : NucleusStateTransitionEffect
├── DashFov : NucleusCameraFovEffect
├── DashAudio : NucleusAudioCueEffect
└── ActionInput : NucleusGameplayActionInput
```

Nothing in this tree is an Autoload.

## Action identity and tags

Every action has a stable `StringName` id.

If `action_id` is empty, the Node name is used.

Optional tags support queries such as:

```text
movement
combat
defensive
magic
menu
```

through:

```gdscript
action_set.get_actions_with_tag(&"combat")
```

Nucleus defines no mandatory gameplay tags.

## Requirements

`NucleusActionRequirement` is a side-effect-free gate.

Built-in:

```text
NucleusStateRequirement
```

It can define:

```text
allowed states
blocked states
```

and observes `NucleusStateMachine.state_changed` so action availability/UI can
refresh automatically.

Reusable project-specific requirements can derive from
`NucleusActionRequirement`.

Examples:

```text
must have target
must be grounded
must own item
must not be silenced
must be inside vehicle
```

Do not put those concepts into the generic action class.

## Costs

`NucleusActionCost` defines:

```text
can_pay(context)
pay(context)
refund(context)
```

Built-in:

```text
NucleusValuePoolCost
```

This directly consumes an existing `NucleusValuePool`.

Example:

```text
Stamina
current: 70

Dash cost
amount: 20
reserve: 5
```

Dash is available while at least 25 stamina remains.

When an actor owns multiple pools, assign `target_pool` explicitly. Automatic
resolution intentionally refuses to guess between Health, Mana, Stamina, etc.

## Effects

Built-in action effects are adapters over existing Nucleus systems.

### Value pool

`NucleusValuePoolEffect`

Examples:

```text
heal
restore mana
consume health
grant temporary overflow value
```

### State machine

`NucleusStateTransitionEffect`

Transitions an existing `NucleusStateMachine`.

The action context can be merged into the state transition context.

### Audio

`NucleusAudioCueEffect`

Calls:

```gdscript
NucleusAudio.play_cue(cue)
```

using the existing Core audio service.

It is intentionally non-positional because `NucleusAudioCue` is the existing
non-positional cue contract. Positional sound remains scene-owned
`AudioStreamPlayer2D/3D`.

### Camera FOV

`NucleusCameraFovEffect`

Drives the existing:

```text
NucleusCameraFov3D
```

without teaching the camera what sprint, ADS, boost, or abilities mean.

## Custom gameplay behavior

An action can have zero built-in effects.

Connect:

```gdscript
action.executed.connect(_perform_attack)
```

This is the preferred extension point for game-specific behavior that does not
deserve a reusable Effect class.

Create a custom `NucleusActionEffect` only when the behavior itself is reusable
across actions/projects.

## Input integration

`NucleusGameplayActionInput` prefers an existing:

```text
NucleusMotionInput
```

because that component already bridges:

```text
single-player InputEvent stream
local-player routed InputEvent stream
NucleusLocalPlayerInput
```

Therefore abilities do not implement a second couch-multiplayer device router.

Input activation uses:

```gdscript
event.is_action_pressed(input_action)
```

for discrete execution.

Held/continuous actions should be modeled deliberately by the game rather than
turning every action into per-frame polling.

## ActionSet

`NucleusActionSet` is an optional scene-owned registry.

Recommended tree:

```text
Player
├── MotionInput
├── Stamina
├── StateMachine
└── Actions : NucleusActionSet
    ├── Dash
    ├── Heal
    └── PrimaryAttack
```

It provides:

```text
get_action(id)
has_action(id)
get_actions()
get_actions_with_tag(tag)
execute(id, context)
capture_state()
restore_state()
```

Direct Node references remain valid. Use ActionSet when stable lookup by id is
useful for:

```text
AI
UI
save/load
hotbars
debug tools
network command mapping
```

## Save integration

`NucleusCooldown` now exposes:

```text
capture_state()
restore_state()
```

An Action captures its enabled state and remaining cooldown.

An ActionSet captures every registered action by stable id.

Therefore:

```gdscript
save_session.register_participant(
    &"player_actions",
    action_set.capture_state,
    action_set.restore_state,
)
```

fits the existing explicit `NucleusSaveSession` participant architecture.

Gameplay Actions never discover the Save service globally.

## UI integration

`NucleusActionButtonBinding` binds an ordinary `BaseButton` to an Action.

It can automatically disable the button when:

```text
action disabled
cooldown active
state requirement fails
resource cost cannot be paid
effect prevalidation fails
```

Godot's normal disabled Button state and Theme rendering remain intact.

## Availability signaling

Action availability is refreshed by:

```text
cooldown started/ready/canceled
ValuePool cost value changes
StateRequirement state changes
manual enabled changes
```

Custom Requirements/Costs should emit their inherited notification signals when
the state they depend on changes.

This avoids polling every action every frame only to keep UI updated.
