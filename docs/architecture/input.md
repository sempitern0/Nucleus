# Nucleus Input Architecture

Target engine: Godot 4.7.x.

## Goal

Input provides device-agnostic actions, active-device tracking, runtime
rebinding, gamepad presentation labels, vibration, and lightweight UI bindings.

Gameplay consumes semantic Godot actions. It does not query hardcoded keyboard
keys or controller button numbers.

## Architecture

```text
project.godot InputMap
       │
       │ immutable defaults
       ▼
 NucleusInputService
       │
       ├── active device/source state
       ├── runtime InputMap overrides
       ├── conflict queries
       └── vibration
       │
       ├──► NucleusSettings
       │      input/bindings
       │      input/vibration_enabled
       │
       └── signals ──► prompt/rebind UI bindings
```

`project.godot` is always the source of default bindings.

Only user overrides are persisted.

## Why `NucleusInput` is an Autoload

Input owns application-lifetime state that genuinely crosses scenes:

- Active input source for UI prompt switching.
- Active gamepad id and presentation family.
- Runtime InputMap overrides.
- Controller connection notifications.
- Vibration routing.

It therefore satisfies the Nucleus Autoload rule.

## Default semantic actions

Nucleus ships a small neutral InputMap:

```text
move_left
move_right
move_forward
move_back

look_left
look_right
look_up
look_down

primary_action
secondary_action
interact
pause
```

The actions are intentionally semantic rather than genre-specific.

There is no `shoot`, `reload`, `crouch`, `inventory`, or other gameplay-specific
action in Core.

Games can freely remove or extend this list.

## UI navigation remains separate

Nucleus does not add WASD or gameplay inputs to Godot's built-in `ui_*` actions.

UI navigation and gameplay input are separate concerns.

This avoids the Barebone behavior where movement keys also implicitly became
menu-navigation keys.

## Universal input

Movement defaults contain:

```text
Keyboard: WASD + arrows
Gamepad:  left stick + D-pad
```

Gameplay can use Godot directly:

```gdscript
var movement := Input.get_vector(
	NucleusInputActions.MOVE_LEFT,
	NucleusInputActions.MOVE_RIGHT,
	NucleusInputActions.MOVE_FORWARD,
	NucleusInputActions.MOVE_BACK,
)
```

Godot applies a circular deadzone to `Input.get_vector()`, which is preferable
to manually constructing square joystick deadzones.

Right-stick look is exposed as four actions. Mouse look remains event-driven
through `InputEventMouseMotion.relative`, because mouse and stick look have
different units and should not be artificially merged into one axis value.

## Runtime rebinding

Example:

```gdscript
var event := InputEventKey.new()
event.physical_keycode = KEY_F

NucleusInput.set_binding(
	NucleusInputActions.INTERACT,
	NucleusInputTypes.Source.KEYBOARD_MOUSE,
	0,
	event,
)
```

Supported binding types:

- `InputEventKey`
- `InputEventMouseButton`
- `InputEventJoypadButton`
- `InputEventJoypadMotion`

The service normalizes runtime events into InputMap mappings that target all
devices rather than one physical controller id.

## Override-based persistence

The service snapshots project defaults at startup.

If an action still matches its default, nothing is stored.

Example persisted Settings value:

```ini
[input]

bindings={
"interact": [{
"type": &"key",
"physical_keycode": 70,
...
}]
}
```

This design handles project updates naturally:

- New project action: gets its new project default automatically.
- Removed project action: old override is discarded.
- Unmodified action: always follows the current project default.
- Reset action: removes the override and restores project data.

There is no persisted copy of every default binding.

## Stable serialization

Barebone persisted strings containing user-facing controller labels. Nucleus
deliberately does not.

`NucleusInputBindingCodec` stores only engine-level binding data:

```text
event type
physical keycode or logical keycode
modifiers
mouse button index
joypad button index
joypad axis + direction
```

Controller-family labels are presentation data and are generated at runtime.

When a keyboard event has a physical keycode, the codec intentionally clears
the logical keycode. A binding therefore has one keyboard identity rather than
two competing identities.

## Physical keyboard mappings

Default gameplay keys use `physical_keycode`.

This keeps WASD and similar spatial controls in the same physical locations on
different keyboard layouts.

Prompt text converts the physical key back to a label appropriate for the
current keyboard layout where the platform supports it.

## Active source detection

The current source can be:

```text
KEYBOARD_MOUSE
GAMEPAD
TOUCH
```

Connection alone does not switch prompts to a gamepad.

A source changes only after meaningful activity:

- non-echo key press;
- mouse button;
- mouse movement above a small threshold;
- gamepad button;
- gamepad axis above a threshold;
- touch or drag.

This reduces prompt flicker caused by joystick drift or tiny mouse movements.

## Device IDs in Godot 4.7

Keyboard and mouse use dedicated `InputEvent` device ids in Godot 4.7, while a
gamepad can legitimately use device id `0`.

Nucleus therefore detects the source primarily from `InputEvent` type and never
uses the old assumption that device zero means keyboard.

For InputMap mappings, the service normalizes remapped events to the engine's
all-devices mapping id rather than retaining the physical controller id that
generated the capture.

## Gamepad family

Family detection only changes presentation labels:

```text
Xbox
PlayStation
Nintendo
Steam
Generic
```

It does not change input semantics.

Godot's controller mapping database remains responsible for normalizing
physical controller layouts into standard `JoyButton` and `JoyAxis` constants.

## UI composition

Rebinding does not require custom Button subclasses.

```text
Button
└── NucleusInputRebindButtonBinding
```

Prompt labels use the same approach:

```text
Label
└── NucleusInputPromptBinding
```

There is also `NucleusResetInputBindingsBinding`.

This continues the Settings architecture's composition-over-inheritance rule.

## Conflicts

`NucleusInput.find_conflicts()` compares bindable events using Godot's exact
event matching.

The rebind binding can either:

- allow duplicates and report nothing, or
- reject the new event and emit `conflict_detected`.

Conflict policy is therefore a UI/product decision rather than a hidden global
rule.

## Vibration

```gdscript
NucleusInput.start_vibration(
	0.25,
	0.75,
	0.4,
)
```

The service:

1. Resolves the active controller.
2. Checks `input/vibration_enabled`.
3. Checks Godot-reported vibration support.
4. Clamps motor strengths.
5. Starts the effect.

## Barebone code intentionally salvaged

Retained concepts:

- Semantic `move_*` action names.
- `Input.get_vector()` for movement.
- Keyboard/mouse versus joypad event helpers.
- Cursor mode helpers.
- Controller button presentation labels.
- Controller vibration convenience.

Not retained:

- `OmniKitGamepadControllerManager` as a separate singleton.
- Exact controller-name state machines.
- `current_device_id != 0` controller detection.
- `OmniKitMotionInput` current/previous input cache.
- Hand-built square deadzones.
- Human-readable binding strings as persistence format.
- Game-specific actions such as shoot, grenade, crawl, inventory, and terrain
  painting.

## Dependency direction

```text
NucleusApp
    ▲
    │
NucleusSettings
    ▲
    │ preferences
    │
NucleusInput
    │
    ├── InputMap
    ├── Input
    └── UI binding components

Gameplay ──► Godot semantic actions
Gameplay ──► NucleusInput only for service features
```

Settings never imports Input code.
