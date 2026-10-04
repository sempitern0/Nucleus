# Input Rebinding

Target engine: Godot 4.7.x.

Nucleus already provides runtime input remapping. This document makes that
surface explicit and separates binding authority, event capture, persistence,
and UI presentation.

For an editor-first setup, see:

```text
docs/guides/input_rebinding_quickstart.md
```

## Architecture

```text
project.godot InputMap
        │
        │ immutable defaults
        ▼
   NucleusInput
        │
        ├── binding CRUD
        ├── conflict queries
        ├── runtime InputMap changes
        └── override persistence
                │
                ▼
         NucleusSettings
         input/bindings

Custom UI
    │
    ▼
NucleusInputRebindCapture
    │
    ▼
NucleusInput.set_binding()

Simple Button UI
    │
    ▼
NucleusInputRebindButtonBinding
    │
    ▼
NucleusInputRebindCapture
```

`NucleusInput` remains the single authority.

The capture component never writes Settings or InputMap directly.

## Existing service API

The application-wide `NucleusInput` service exposes:

```text
is_action_rebindable()
get_rebindable_actions()
refresh_actions()

get_action_events()
get_binding_text()

add_binding()
set_binding()
remove_binding()
clear_bindings()

reset_action()
reset_all_bindings()

find_conflicts()
```

This is already sufficient to build a complete settings screen.

## Defaults and persistence

Defaults always live in:

```text
project.godot
→ InputMap
```

Only overrides are persisted.

The storage key is:

```text
input/bindings
```

through the existing `NucleusSettings` service.

Consequences:

- adding a new action does not require a save migration;
- deleting an action discards obsolete overrides;
- untouched actions automatically inherit updated project defaults;
- resetting an action removes its override.

## Supported event types

The stable codec currently supports:

```text
InputEventKey
InputEventMouseButton
InputEventJoypadButton
InputEventJoypadMotion
```

Bindings are normalized before they reach InputMap.

Generated mappings use the all-devices id rather than the physical controller id
that happened to generate the capture.

This is essential for local multiplayer: a remapped gamepad action describes
the semantic controller binding, while `NucleusLocalPlayerInput` still decides
which physical controller belongs to each player.

## Capture component

`NucleusInputRebindCapture` is presentation-agnostic.

Use it when the settings UI needs more than a single Button.

Primary API:

```gdscript
capture.begin_capture(
    &"interact",
    NucleusInputTypes.Source.KEYBOARD_MOUSE,
    0,
    NucleusInputRebindCapture.ConflictPolicy.PROMPT,
)
```

It works while the SceneTree is paused because its process mode is `ALWAYS`.

It accepts only keyboard/mouse or gamepad capture sources because touch events
are not part of the current persistent binding codec.

## Conflict policies

### ALLOW

Commit the binding even when another action uses it.

### REJECT

Emit `conflict_detected` and keep listening.

### PROMPT

Pause event capture and retain the candidate.

A UI may then show an accessible confirmation dialog and call:

```gdscript
capture.accept_pending_conflict()
```

or:

```gdscript
capture.reject_pending_conflict()
```

Rejecting resumes capture.

This makes conflict resolution a presentation/product policy instead of a Core
rule.

## Why capture does not hardcode Escape/B

A cancel key cannot safely be hardcoded inside the capture engine because the
player may intentionally want to bind that key/button.

The UI owns cancellation:

```gdscript
capture.cancel_capture()
```

For a modal rebinding screen, expose an explicit Cancel button/action outside
the captured source or use the modal's own accessible cancellation policy.

## Simple Button binding

For basic settings screens the existing composition remains:

```text
Button
└── NucleusInputRebindButtonBinding
```

Iteration 15 refactors that binding so it delegates event capture to
`NucleusInputRebindCapture`.

Existing exported concepts remain:

```text
action
source
binding_index
allow_conflicts
listening_text
unbound_text
```

It additionally supports:

```text
prompt_conflicts
capture
conflict_text
```

A capture Node can be shared by an entire settings panel so only one binding is
captured at a time.

If no capture is assigned, the binding creates one internally.

## Multiple binding slots

`binding_index` is relative to the selected input source.

Example:

```text
interact

Keyboard & Mouse
    slot 0 = E
    slot 1 = Mouse 4

Gamepad
    slot 0 = X / Square
```

Use:

```gdscript
NucleusInput.get_action_events(
    action,
    source,
)
```

to build dynamic rows.

## Unbinding

The service intentionally separates replacement from removal.

Remove one source slot:

```gdscript
NucleusInput.remove_binding(
    action,
    source,
    index,
)
```

Remove every binding for a source:

```gdscript
NucleusInput.clear_bindings(
    action,
    source,
)
```

Reset to project defaults:

```gdscript
NucleusInput.reset_action(action)
```

or:

```gdscript
NucleusInput.reset_all_bindings()
```

Nucleus does not globally forbid leaving a gameplay action unbound because some
games intentionally allow that.

The settings UI should apply its own policy for truly mandatory actions.

## UI actions

Built-in `ui_*` actions are not rebindable by default.

This protects menu navigation from accidentally becoming unusable.

The service exposes:

```gdscript
NucleusInput.allow_ui_action_rebinding
```

for projects that intentionally implement remappable UI navigation.

If enabled, the project UI must provide a safe recovery/reset path.

## Adding project actions at runtime

If a project adds InputMap actions after Nucleus startup, call:

```gdscript
NucleusInput.refresh_actions()
```

This captures their initial bindings as project defaults without replacing
defaults that were already tracked.

## Accessibility recommendations

A production controls screen should provide:

- keyboard/mouse and gamepad remapping independently;
- readable current binding labels;
- explicit Unbind;
- reset per action and reset all;
- conflict explanation rather than silent failure;
- controller-family-aware labels;
- full keyboard/gamepad focus navigation;
- no mouse-only conflict dialogs;
- a safe recovery path if UI actions are made rebindable.

The Input backend already provides the mechanics required for these workflows.
