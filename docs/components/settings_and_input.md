# Settings and Input Contract

## Scope

```text
core/settings
core/input
```

The two systems integrate closely but retain separate responsibilities:
Settings owns configurable values and persistence; Input owns device state,
InputMap-facing rebinding, labels/prompts, and local player ownership.

## Settings ownership

`NucleusSettings` is the default settings Autoload.

The subsystem is structured around:

```text
definitions
catalog
defaults
persistence
appliers
bindings
```

Definitions describe settings. The catalog is the authoritative registry.
Persistence stores user choices. Appliers translate values into engine state.
Bindings connect UI or other consumers without duplicating settings logic.

Do not make UI widgets write `ProjectSettings`, `DisplayServer`, or audio buses
independently when a Nucleus setting/applier already owns that behavior.

## Runtime application

Changing a setting through `NucleusSettings.set_value()` updates the runtime
value, emits `setting_changed`, and lets the matching applier update Godot state.
Persistence and runtime application are related but separate responsibilities.

For built-in display settings, `NucleusDisplaySettingsApplier` owns:

```text
display/window_mode
display/borderless
display/vsync_mode
graphics/max_fps
graphics/msaa_3d
```

Do not try to make a runtime preference effective by writing the corresponding
`ProjectSettings` key. Many project settings are read only during startup.
Nucleus intentionally uses runtime APIs such as `DisplayServer`, `Engine`, and
the root `Viewport` from the applier.

### Godot editor game embedding

Godot 4.7 enables game embedding by default. Embedded runs do not support window
mode or window-flag changes such as fullscreen.

Nucleus therefore keeps the preference persisted but does not treat an embedded
editor run as proof that fullscreen is broken. The display applier emits a
diagnostic when an actual embedded window change is requested.

To validate window mode:

1. Open the editor's **Game** workspace.
2. Disable **Embed Game on Next Play**.
3. Run the project again, or validate an exported build.
4. Compare the runtime state with `DisplayServer.window_get_mode()` if needed.

Web and native-mobile platforms also use managed window behavior and intentionally
ignore desktop window-mode requests.

## Input ownership

`NucleusInput` is the default input Autoload.

It builds on Godot's `Input` and `InputMap` rather than replacing them.

The public surface includes:

- semantic default action identifiers;
- active input-source/device tracking;
- runtime rebinding serialization;
- human-readable input labels;
- prompt bindings;
- cursor and gamepad helpers;
- local multiplayer input sessions/readers.

### Cursor ownership

`NucleusCursor` is the public cursor-mode boundary.

Use:

```gdscript
NucleusCursor.show()
NucleusCursor.hide()
NucleusCursor.capture()
NucleusCursor.confine()
NucleusCursor.confine_hidden()
NucleusCursor.set_mode(custom_mode)
```

Game-facing code should not assign `Input.mouse_mode` directly. Keeping the raw
Godot assignment inside `NucleusCursor` gives agents and humans one searchable
owner for cursor policy without hiding Godot's actual modes.

## Runtime rebinding

`NucleusInputBindingCodec` serializes supported `InputEvent` bindings so they can
be persisted through Settings or another project-owned store.

Rebinding changes Godot's `InputMap`; game code should continue to query actions,
not physical keys/buttons.

## Local multiplayer

Local multiplayer input ownership is explicit. A local input session owns player
assignments and readers consume input for one assignment/device context.

Do not solve local multiplayer by globally swapping the active device or by
forking the InputMap per player unless a game has a specific requirement that
cannot be represented by the existing reader/session model.

## Signals and data flow

Typical flow:

```text
device InputEvent
→ NucleusInput source/device tracking
→ optional local-player routing
→ gameplay/UI consumer

rebind request
→ InputMap mutation
→ serialized binding
→ settings persistence
→ prompt/label refresh

settings binding
→ NucleusSettings.set_value()
→ setting_changed
→ settings applier
→ Godot runtime API
```

## Agent and CI guardrail

The root `AGENTS.md` tells coding agents to search Nucleus before duplicating a
lower-level Godot call. `scripts/ci/static_checks.py` mechanically protects a
small set of high-value ownership boundaries, including cursor mode and built-in
display settings.

The guardrail is intentionally narrow. Nucleus still prefers native Godot APIs
when no Nucleus system owns the concern.

## Persistence boundary

Settings persistence is configuration data. Save-game state belongs to
`core/save`. Do not mix them merely because both write to `user://`.

## Extension rule

New settings should enter through definitions/catalog/appliers. New input
presentation should consume semantic actions and the existing label/prompt
helpers rather than encoding device-specific strings in gameplay code.
