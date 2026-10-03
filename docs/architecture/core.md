# Nucleus Core Architecture

Target engine: Godot 4.7.x.

## Purpose

The Core contains only infrastructure that is valid regardless of game genre,
camera perspective, dimensionality, control scheme, content, or business model.

A Core module may depend on Godot and on lower-level Core modules. It must not
depend on gameplay code, external addons, examples, or project-specific assets.

## Current modules

```text
core/
├── application/
├── diagnostics/
├── input/
│   ├── bindings/
│   ├── cursor.gd
│   ├── gamepad.gd
│   ├── input_actions.gd
│   ├── input_binding_codec.gd
│   ├── input_labels.gd
│   ├── input_service.gd
│   └── input_types.gd
├── settings/
└── window/
```

Current Autoloads:

```text
NucleusApp
NucleusSettings
NucleusInput
```

Each owns a distinct application-lifetime responsibility.

## Dependency direction

```text
Godot APIs
   ▲
   ├── Diagnostics / Window
   │
   └── NucleusApp
          ▲
          │ lifecycle
          │
     NucleusSettings
          ▲
          │ preferences
          │
       NucleusInput
```

Gameplay is not part of this graph.

Future Audio, Persistence, and Scene Flow modules may depend on lower layers,
but lower layers must never depend back on them.

## Design rules

1. **No gameplay types in Core.**
2. **Autoloads require persistent cross-scene state or lifecycle ownership.**
3. **No global EventBus by default.**
4. **No Service Locator.**
5. **No legacy compatibility layer.**
6. **Public global class names use the `Nucleus` prefix.**
7. **Composition over inheritance for game-facing systems and UI bindings.**
8. **Critical lifecycle persistence is synchronous.**
9. **Project files define defaults; user data stores overrides.**
10. **Presentation metadata is not persistence data.**

## Patterns used

### Observer

Lifecycle, Settings, and Input expose narrow signals instead of importing their
consumers.

### Facade

`NucleusLog` provides a small stable API over Godot output.

### Adapter

`NucleusFileLogger` adapts Godot Logger to a file sink.

### Repository

Settings persistence is isolated behind its ConfigFile repository.

### Binding components

Settings and Input adapt ordinary Godot controls through child Nodes instead of
creating parallel GUI inheritance hierarchies.

### Snapshot + Override

Input snapshots project InputMap defaults, then persists only user changes.

## Barebone code intentionally salvaged

Retained and redesigned:

- Application quit interception.
- Window helpers.
- File logging.
- Resource-driven settings.
- Lightweight GUI settings bindings.
- ConfigFile preferences.
- Semantic movement actions.
- Cursor helpers.
- Gamepad labels and vibration.

Not carried into Core:

- `Globals` and `GlobalEvents`.
- Global player state.
- Gameplay collision constants.
- Generic EventBus.
- Networking.
- Inventory, weapons, DLC, interactions, Terrainy, or other game features.

## Planned Core modules

```text
Audio
Persistence
Scene Flow
```

Each module must justify every new Autoload independently.
