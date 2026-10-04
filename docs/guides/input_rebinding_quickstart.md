# Input Rebinding — Godot Editor Quickstart

The rebinding backend already exists in Nucleus.

This guide shows how to wire it into a settings UI.

Technical reference:

```text
docs/components/input_rebinding.md
```

---

## 1. Define defaults in InputMap

Open:

```text
Project
→ Project Settings
→ Input Map
```

Create the project's semantic actions and assign defaults.

Nucleus already includes neutral defaults such as:

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

These project bindings are the reset/default state.

---

## 2. Create a basic keyboard rebind button

Example tree:

```text
InteractRow
├── ActionLabel : Label
└── KeyboardBinding : Button
    └── RebindBinding : Node
```

Attach to `RebindBinding`:

```text
core/input/bindings/rebind_button_binding.gd
```

Configure:

```text
action = interact
source = Keyboard & Mouse
binding_index = 0
```

Pressing the Button now changes its text to:

```text
Press an input...
```

The next supported keyboard/mouse event is persisted automatically.

No Settings script is required.

---

## 3. Add a gamepad column

Create another Button:

```text
InteractRow
├── ActionLabel
├── KeyboardBinding
└── GamepadBinding
```

Its binding uses:

```text
action = interact
source = Gamepad
binding_index = 0
```

The label is automatically formatted for the active controller family.

---

## 4. Reset all controls

Tree:

```text
ResetControlsButton : Button
└── ResetBinding
```

Attach:

```text
core/input/bindings/reset_input_bindings_binding.gd
```

Leave its `action` empty.

That calls:

```gdscript
NucleusInput.reset_all_bindings()
```

Set `action` to a specific action id for a per-action reset button.

---

## 5. Build rows dynamically

A future production controls menu can enumerate:

```gdscript
for action: StringName in NucleusInput.get_rebindable_actions():
    var keyboard_events := NucleusInput.get_action_events(
        action,
        NucleusInputTypes.Source.KEYBOARD_MOUSE,
    )

    var gamepad_events := NucleusInput.get_action_events(
        action,
        NucleusInputTypes.Source.GAMEPAD,
    )
```

Use those arrays to create as many binding slots as your UI wants.

Nucleus does not impose a fixed one-key-per-action layout.

---

## 6. Advanced conflict confirmation

Add one shared Node to the controls panel:

```text
ControlsPanel
├── RebindCapture : Node
├── Rows
└── ConflictModal
```

Attach:

```text
core/input/rebinding/input_rebind_capture.gd
```

Assign that capture to every `NucleusInputRebindButtonBinding` in the panel and
enable:

```text
prompt_conflicts = true
```

Listen to:

```text
conflict_detected
```

and show your existing Nucleus modal.

If the player chooses Replace/Use Anyway:

```gdscript
binding.accept_conflict()
```

If the player chooses another input:

```gdscript
binding.reject_conflict()
```

The latter returns to capture mode.

This lets the final controls UI reuse the existing modal/focus/accessibility
tooling instead of embedding conflict presentation into Input Core.

---

## 7. Explicit unbind

For a small Remove button:

```gdscript
func _on_unbind_pressed() -> void:
    NucleusInput.remove_binding(
        action,
        source,
        binding_index,
    )
```

For "clear keyboard bindings":

```gdscript
NucleusInput.clear_bindings(
    action,
    NucleusInputTypes.Source.KEYBOARD_MOUSE,
)
```

The change is persisted through NucleusSettings automatically.

---

## 8. Local multiplayer clarification

Do not create separate mappings such as:

```text
player_1_interact
player_2_interact
```

for couch multiplayer.

A remap changes the semantic InputMap action:

```text
interact
```

`NucleusLocalInputSession` still routes the physical controller assigned to each
player.

Therefore both systems compose:

```text
InputMap remap
      ↓
NucleusInput
      ↓
NucleusLocalPlayerInput
      ↓
Player 1 / Player 2
```

---

## 9. Keep UI navigation recoverable

By default Nucleus excludes:

```text
ui_*
```

from the rebinding API.

Keep that default unless the project explicitly supports remapping UI
navigation.

If you enable it, provide:

```text
Reset Controls
keyboard navigation
gamepad navigation
accessible conflict modal
```

that cannot all become unreachable at the same time.
