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
```

## Persistence boundary

Settings persistence is configuration data. Save-game state belongs to
`core/save`. Do not mix them merely because both write to `user://`.

## Extension rule

New settings should enter through definitions/catalog/appliers. New input
presentation should consume semantic actions and the existing label/prompt
helpers rather than encoding device-specific strings in gameplay code.
