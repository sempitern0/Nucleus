# Tutorial: get the most from Nucleus bindings

Bindings are small scene-owned adapters that keep a normal Godot Control in sync
with a Nucleus service.

They are most useful when you want:

```text
Control changes
→ service changes
→ persistence/runtime behavior changes

and also:

service changes elsewhere
→ Control refreshes automatically
```

The binding removes repetitive `_ready()`, signal connection, initial-value,
and refresh code from each menu.

There are two different binding families:

```text
Settings bindings
    Control ↔ NucleusSettings

Input bindings
    Label/Button ↔ NucleusInput bindings/prompts
```

## Part A — bind a volume slider

### 1. Create the Control

Create:

```text
MasterVolume : HSlider
└── SettingBinding : Node
```

Assign this script to `SettingBinding`:

```text
res://core/settings/bindings/range_setting_binding.gd
```

Because the binding is a child of the `HSlider`, `target` can remain empty. The
binding resolves its parent as a `Range`.

### 2. Assign the setting definition

Set `SettingBinding.setting` to:

```text
res://core/settings/defaults/audio_master_volume.tres
```

Leave:

```text
configure_range_from_definition = true
```

The binding will derive the slider step/range from the definition where
available.

### 3. Run the scene

The flow is now:

```text
HSlider.value_changed
→ NucleusRangeSettingBinding
→ NucleusSettings.set_value()
→ audio setting applier
→ AudioServer
```

If some other code changes `audio/master_volume`,
`NucleusRangeSettingBinding` observes `NucleusSettings.setting_changed` and
updates the Slider without emitting another value-change loop.

No menu script is required.

## Part B — bind a boolean setting

For a CheckButton:

```text
ReducedMotion : CheckButton
└── SettingBinding : Node
```

Use:

```text
res://core/settings/bindings/bool_setting_binding.gd
```

Assign a `NucleusBoolSettingDefinition`, for example the existing reduced-motion
definition.

The binding forces `toggle_mode = true`, reads the current value, writes toggle
changes to Settings, and refreshes when the setting changes elsewhere.

## Part C — populate an OptionButton from the setting definition

Create:

```text
WindowMode : OptionButton
└── SettingBinding : Node
```

Use:

```text
res://core/settings/bindings/int_option_setting_binding.gd
```

Assign an existing `NucleusIntOptionSettingDefinition`.

With:

```text
clear_existing_items = true
```

the binding builds the `OptionButton` items from the definition and stores the
actual integer values as item metadata.

This means the UI does not need a second copy of the setting's option table.

## Part D — create a game-specific setting

Suppose a game needs:

```text
gameplay/camera_sensitivity
```

This is project policy, so keep the definition in the consuming game rather than
adding it to Nucleus Core.

### 1. Create the definition Resource

Create a `NucleusFloatSettingDefinition`, for example:

```text
res://game/config/camera_sensitivity.tres
```

Configure:

```text
section         = gameplay
key             = camera_sensitivity
display_name    = Camera sensitivity
default_value   = 1.0
has_range       = true
minimum_value   = 0.2
maximum_value   = 3.0
step            = 0.1
```

The resulting ID is:

```text
gameplay/camera_sensitivity
```

### 2. Register it in the game's catalog

A setting is only part of the application contract when its definition is in the
active `NucleusSettingsCatalog.settings` array.

For a consuming game, prefer a game-owned catalog/Settings scene when adding
project-specific settings.

That lets the game reference the reusable Core definitions it wants and add its
own definitions without turning game policy into Nucleus defaults.

### 3. Bind it to a Slider

Create:

```text
CameraSensitivity : HSlider
└── SettingBinding : NucleusRangeSettingBinding
```

Assign:

```text
setting = camera_sensitivity.tres
```

The Slider now gets range/step information from the same definition used by
Settings validation.

### 4. Apply the setting in game code

If the behavior belongs only to one camera/controller, observe the setting
there:

```gdscript
func _ready() -> void:
    NucleusSettings.setting_changed.connect(_on_setting_changed)
    _apply_sensitivity(
        NucleusSettings.get_float(
            &"gameplay/camera_sensitivity",
            1.0,
        )
    )


func _on_setting_changed(
    setting_id: StringName,
    value: Variant,
    _previous_value: Variant,
) -> void:
    if setting_id == &"gameplay/camera_sensitivity":
        _apply_sensitivity(float(value))
```

If many scenes need the same application rule, move that rule to one game-owned
applier.

## Part E — show the current input prompt

Create:

```text
InteractPrompt : Label
└── PromptBinding : Node
```

Assign:

```text
res://core/input/bindings/input_prompt_binding.gd
```

Configure:

```text
action               = interact
binding_index        = 0
follow_active_source = true
```

The Label automatically changes when:

- keyboard/mouse becomes the active source;
- a gamepad becomes the active source;
- the active gamepad family changes;
- the action is rebound.

Do not store strings such as `E`, `A`, `Cross`, or `LMB` in gameplay UI.

## Part F — create a rebinding button

Create:

```text
RebindInteractKeyboard : Button
└── Binding : Node
```

Use:

```text
res://core/input/bindings/rebind_button_binding.gd
```

Configure:

```text
action        = interact
source        = Keyboard & Mouse
binding_index = 0
```

For a gamepad row, use another Button with:

```text
source = Gamepad
```

The binding automatically creates a `NucleusInputRebindCapture` child if one is
not assigned.

Pressing the Button starts capture and the button text becomes the current
binding label.

### Conflict policy

Choose one of these patterns:

```text
allow_conflicts = true
    fastest UI; duplicate bindings are allowed

allow_conflicts = false
prompt_conflicts = false
    conflicting input is rejected

prompt_conflicts = true
    pause capture and let your modal ask the player
```

When using prompt mode, connect `conflict_detected` and call:

```gdscript
binding.accept_conflict()
```

or:

```gdscript
binding.reject_conflict()
```

from the project's confirmation UI.

## Part G — build a complete controls row

A scalable controls menu can be composed as:

```text
InteractRow : HBoxContainer
├── ActionName : Label
├── KeyboardBinding : Button
│   └── Rebind : NucleusInputRebindButtonBinding
└── GamepadBinding : Button
    └── Rebind : NucleusInputRebindButtonBinding
```

Repeat the scene as a reusable row for every game-owned action.

Keep the action ID as data on the row/binding rather than writing one script per
action.

## Why bindings are valuable

Without a binding, a menu often has to manually implement:

```text
read initial state
connect Control signal
validate/convert UI value
write service
listen for external changes
avoid signal loops
refresh text/prompt
handle input-source changes
handle rebinding
```

Bindings centralize that repeated glue while leaving presentation in native
Godot Controls.

## When not to use a binding

Do not add a Nucleus binding just to avoid one simple local signal.

A direct connection is fine when:

- the state is scene-local and not a Nucleus service concern;
- no persistence/synchronization is involved;
- the relationship is already explicit and trivial.

## Common mistakes

- copying setting option values into the UI and letting the two copies diverge;
- editing `ProjectSettings` when a runtime Settings applier already owns the
  behavior;
- hard-coding input prompt strings;
- rebinding a physical gamepad device ID instead of a semantic gamepad binding;
- using `ui_cancel` as a gameplay action;
- adding a game-specific setting to Nucleus Core instead of the game's catalog;
- manually setting a Slider value in several scripts even though a binding can
  synchronize it.

## Related docs

- [`../settings_input_quickstart.md`](../settings_input_quickstart.md)
- [`../../components/settings_and_input.md`](../../components/settings_and_input.md)
- [`../ui_quickstart.md`](../ui_quickstart.md)
