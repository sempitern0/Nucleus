# Nucleus Core Architecture

Target engine: Godot 4.7.x.

## Purpose

The Core contains only infrastructure that is valid regardless of game genre,
camera perspective, dimensionality, control scheme, content, or business model.

A Core module may depend on Godot and on lower-level Core modules. It must not
depend on gameplay code, external addons, examples, or project-specific assets.

## Iteration 01

```text
core/
├── application/
│   └── application.gd
├── diagnostics/
│   ├── nucleus_file_logger.gd
│   └── nucleus_log.gd
└── window/
    └── nucleus_window.gd
```

Only `NucleusApp` is an Autoload.

## Dependency direction

```text
Godot APIs
   ▲
   ├── NucleusWindow
   ├── NucleusLog
   └── NucleusFileLogger
              ▲
              │
         NucleusApp
```

Gameplay is not part of this graph.

Future Core modules such as Settings, Input, Audio, Persistence, and Scene Flow
may depend on these foundations, but this layer must never depend back on them.

## Design rules

1. **No gameplay types in Core.**
   No Player, Enemy, Weapon, Inventory, Interactable, Quest, or genre-specific
   concepts.

2. **Autoloads require persistent cross-scene state or lifecycle ownership.**
   Stateless shared behavior uses static named classes instead.

3. **No global EventBus by default.**
   Prefer local Godot signals. Add a mediator only when a subsystem has a real
   many-to-many communication problem.

4. **No Service Locator.**
   Core services do not hide arbitrary dependencies behind a global registry.

5. **No legacy compatibility layer.**
   Nucleus is a clean architecture. Barebone is reference material only.

6. **Public global class names use the `Nucleus` prefix.**
   This reduces collisions when the project is eventually distributed through
   the Godot Asset Store.

7. **Composition over inheritance for game-facing systems.**
   Reusable gameplay functionality will live in components rather than Core
   base classes.

8. **Persistence work must be synchronous at critical lifecycle boundaries.**
   Mobile pause and application quit callbacks have limited time to finish.

## Patterns used

### Observer

`NucleusApp` translates operating-system notifications into typed Godot signals.
Future services can react without `NucleusApp` importing them.

### Facade

`NucleusLog` provides a tiny stable logging API while continuing to use Godot's
native output, warning, and error streams.

### Adapter

`NucleusFileLogger` adapts Godot's `Logger` interface to a rotating file sink.

### Static utility

`NucleusWindow` contains pure viewport/window calculations that do not own
state, so it is deliberately not an Autoload.

## Barebone code intentionally salvaged

Ideas retained and redesigned:

- Manual quit interception from `OmniKitWindowManager`.
- Viewport center, aspect ratio, relative mouse, and window centering helpers.
- File logging through Godot's `Logger` API.
- Thread safety with `Mutex` for logger callbacks.

Ideas intentionally not carried into Core:

- `Globals`.
- `GlobalEvents`.
- Global player references.
- Collision-layer constants.
- Resolution catalogs.
- Parallax helpers inside window infrastructure.
- Generic EventBus.
- Networking.
- Inventory, weapons, interactions, DLC, UI effects, or other gameplay state.

## Planned Core modules

The next layers should be introduced one at a time:

```text
Settings
Input
Audio
Persistence
Scene Flow
```

Each module must justify every new Autoload independently.
