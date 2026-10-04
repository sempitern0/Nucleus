# Gameplay Actions — Godot Editor Quickstart

Use this guide when you want to build abilities/actions from the Godot editor.

Technical contracts:

```text
docs/components/gameplay_actions.md
```

---

## 1. Create a dash with stamina + cooldown

Recommended actor tree:

```text
Player
├── MotionInput
├── Stamina : NucleusValuePool
├── StateMachine
└── Actions : NucleusActionSet
    └── Dash : NucleusGameplayAction
        ├── Cooldown
        ├── StaminaCost
        ├── StateRequirement
        ├── StateTransition
        ├── DashFov
        ├── DashAudio
        └── ActionInput
```

Attach:

```text
Dash
    components/gameplay/actions/gameplay_action.gd

Cooldown
    components/gameplay/timing/cooldown.gd

StaminaCost
    components/gameplay/actions/value_pool_cost.gd

StateRequirement
    components/gameplay/actions/state_requirement.gd

StateTransition
    components/gameplay/actions/state_transition_effect.gd

DashFov
    components/gameplay/actions/camera_fov_effect.gd

DashAudio
    components/gameplay/actions/audio_cue_effect.gd

ActionInput
    components/gameplay/actions/action_input.gd
```

### Configure cost

Select `StaminaCost`:

```text
target_pool = Player/Stamina
amount      = 20
reserve     = 0
```

### Configure cooldown

Example:

```text
duration = 1.25
```

### Configure state restriction

Example:

```text
allowed_states =
    idle
    move
```

### Configure execution

Create your game InputMap action:

```text
dash
```

Assign it to `ActionInput.input_action`.

`ActionInput` will reuse the Player's existing `NucleusMotionInput`.

For couch multiplayer, if MotionInput is already bound to one
`NucleusLocalPlayerInput`, Dash automatically receives only that player's routed
press event.

---

## 2. Create a heal action

Tree:

```text
Heal : NucleusGameplayAction
├── Cooldown
├── ManaCost : NucleusValuePoolCost
├── HealHealth : NucleusValuePoolEffect
└── HealAudio : NucleusAudioCueEffect
```

Configure:

```text
ManaCost.target_pool = Mana
ManaCost.amount = 15

HealHealth.target_pool = Health
HealHealth.delta = 30
```

Enable:

```text
require_full_application
```

if the action should be unavailable unless all 30 points can actually be
restored.

Leave it disabled if partial healing is acceptable.

---

## 3. Run project-specific code

You do not need a custom Effect for every action.

Connect:

```gdscript
%PrimaryAttack.executed.connect(_on_primary_attack)


func _on_primary_attack(context: Dictionary) -> void:
    spawn_projectile(context)
```

The action has already:

```text
validated requirements
paid costs
started cooldown
```

before `executed` is emitted.

Use a custom `NucleusActionEffect` only when the effect itself is reusable.

---

## 4. Drive FSM from an action

A state transition effect can turn:

```text
Dash action
```

into:

```text
StateMachine → dash state
```

Set:

```text
target_state = "dash"
```

The effect prechecks both `can_exit()` and `can_enter()` before the action
commits.

The action context can be forwarded into the state context.

---

## 5. Drive camera feedback

For an FPS sprint/boost action:

```text
Action
└── CameraFovEffect
```

Assign the existing `NucleusCameraFov3D`.

Example:

```text
target_fov = 90
instant = false
```

A separate action/effect can set `reset_to_base = true`.

The camera component still owns smoothing; the Action only changes its target.

---

## 6. Play action audio

Create/reuse a `NucleusAudioCue` Resource and assign it to:

```text
NucleusAudioCueEffect.cue
```

The effect uses the existing `NucleusAudio` one-shot pool.

For spatial footsteps/gunshots positioned in the world, keep using
`AudioStreamPlayer2D/3D`; this built-in action effect is intentionally for the
existing non-positional cue API.

---

## 7. Execute actions from AI

AI does not need to synthesize InputEvents.

Use the ActionSet:

```gdscript
var error: Error = action_set.execute(
    &"melee_attack",
    {
        "source": self,
        "target": current_target,
    },
)
```

The same requirements/costs/cooldown/effects run for player and AI execution.

---

## 8. Bind an action to UI

Tree:

```text
DashButton : Button
└── ActionButtonBinding
```

Attach:

```text
components/ui/gameplay/action_button_binding.gd
```

Assign the Dash action.

The Button can automatically become disabled while:

```text
cooling down
out of stamina
wrong FSM state
action disabled
```

No custom Button subclass is required.

---

## 9. Save cooldowns

Register the actor ActionSet with the existing SaveSession:

```gdscript
save_session.register_participant(
    &"player_actions",
    %Actions.capture_state,
    %Actions.restore_state,
)
```

Action ids should remain stable between game versions if their cooldown state is
persisted.

Changing a Node name is safe when an explicit `action_id` is assigned.

---

## 10. Multiple ValuePools

If an actor has:

```text
Health
Mana
Stamina
```

always drag the intended pool into the Inspector.

Nucleus deliberately refuses to auto-select one when several candidates are
visible.

This turns an ambiguous configuration into an editor-time/runtime diagnostic
instead of silently consuming the wrong resource.

---

## 11. Custom reusable requirement

Example:

```gdscript
class_name HasTargetRequirement
extends NucleusActionRequirement

@export var targeting: MyTargetingComponent


func check(_context: Dictionary) -> Error:
    return OK if targeting.current_target else ERR_UNAVAILABLE
```

When the target changes:

```gdscript
notify_availability_changed()
```

That signal allows Action/UI availability to refresh without polling every
frame.
