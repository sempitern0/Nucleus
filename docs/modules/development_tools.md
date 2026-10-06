# Optional Development Tools Module

## Status

`modules/development_tools` is optional, debug-oriented, and not loaded by
default. It provides an explicit development-command registry plus a searchable
in-game command palette.

The ready-to-instance shell is:

```text
res://modules/development_tools/development_tools.tscn
```

It is scene-owned by default. A game may place it in a persistent development
shell when commands should survive scene replacement. Do not add it to the
baseline Autoload list merely for convenience.

## Purpose

During production, teams repeatedly create temporary debug buttons, one-off key
bindings, inspector scripts, and ad-hoc cheat menus. Those tools are useful but
usually duplicate discovery, argument parsing, output, and lifecycle code.

Nucleus standardizes only that reusable shell:

```text
explicit command registration
typed arguments
quoted command-line parsing
search + aliases
bounded execution history
normalized command results
ready-to-instance palette UI
small adapters around existing Nucleus owners
```

The game still owns what a command actually does.

## Public types

```text
NucleusDevelopmentCommandArgument
NucleusDevelopmentCommand
NucleusDevelopmentCommandResult
NucleusDevelopmentCommandRegistry
NucleusDevelopmentCommandPalette
NucleusDevelopmentTools
NucleusDevelopmentDefaultCommands
NucleusSceneFlowDevelopmentCommands
NucleusPerformanceDevelopmentCommands
```

## Trust boundary

The registry is an explicit allowlist. It intentionally does **not** provide:

```text
eval / Expression execution
arbitrary Object.call() by user text
arbitrary property mutation
OS.execute()
remote console transport
a generic cheat manager
production administration APIs
```

A command exists only after game/framework code registers a
`NucleusDevelopmentCommand` with a concrete callback. This keeps development
tooling powerful without turning typed text into arbitrary code execution.

`NucleusDevelopmentCommandRegistry.debug_build_only` defaults to `true`. The
ready shell also removes itself in non-debug builds by default. A project may
explicitly opt into release-like QA tooling, but that is product policy.

## Command model

A command defines:

```text
id
title
description
category
aliases
tags
typed argument list
callback
```

IDs are stable machine-facing names such as:

```text
scene.reload
boat.teleport
world.spawn_wave
performance.report
```

Titles/descriptions are presentation text. Do not encode game logic in the
registry itself.

Example:

```gdscript
var command := NucleusDevelopmentCommand.build(
    &"boat.teleport",
    "Teleport active boat",
    _teleport_boat,
    "Moves the active development boat to an authored marker.",
    &"Nautica",
    [
        NucleusDevelopmentCommandArgument.build(
            &"marker",
            TYPE_STRING,
        ),
    ],
)

var error := registry.register_command(command)
```

Callbacks receive:

```text
arguments
    parsed primitive values in declared order

context
    invocation metadata plus registry and command_id
```

Callbacks should normally return `NucleusDevelopmentCommandResult`. Returning a
String is accepted as a successful short-form result.

## Arguments

Reusable parsing currently supports:

```text
TYPE_STRING
TYPE_INT
TYPE_FLOAT
TYPE_BOOL
```

Arguments may be optional, have default values, and define string choices.
Required arguments must precede optional ones.

The line parser supports quoted values and escapes:

```text
world.spawn 10 "Harbor Patrol" true
scene.goto res://world/harbor.tscn
```

Do not turn the command parser into a scripting language. Complex configuration
should remain Resources/data owned by the game.

## Search and aliases

The palette searches stable IDs, aliases, titles, categories, tags, and
descriptions. Exact IDs/aliases rank first, then prefixes, then contains matches.

Aliases are unique across the registry and cannot silently shadow another
command.

## Execution history

The registry keeps a bounded in-memory history containing:

```text
timestamp
command id
raw command line
parsed arguments
status
message
```

It is not persisted and is not telemetry. Its purpose is local debugging and
fast repetition/context.

## Ready development shell

`development_tools.tscn` composes:

```text
DevelopmentTools
├── Registry
├── DefaultCommands
├── SceneFlowCommands
└── Overlay
    └── Palette
```

Built-in commands are deliberately conservative:

```text
dev.context
dev.help [query]
dev.history.clear
scene.current
scene.reload
scene.goto <res://path>
```

Scene changes route through `NucleusSceneFlow`; the module does not duplicate
ResourceLoader/SceneTree transition policy.

## Opening the palette

The shell does not invent a physical key. Either call it explicitly:

```gdscript
$DevelopmentTools.open_palette()
```

or configure `toggle_action` with a dedicated semantic InputMap action owned by
the consuming game.

When open, the palette uses normal `ui_up`, `ui_down`, `ui_accept`, and
`ui_cancel` behavior and temporarily exposes the cursor through `NucleusCursor`,
restoring the prior cursor mode when closed.

## Performance adapter

`NucleusPerformanceDevelopmentCommands` is an explicit bridge between two
optional modules. Assign both `registry_path` and `sampler_path` to register:

```text
performance.report [path]
performance.clear
performance.trace <label>
performance.compare <baseline_path>
```

The adapter calls the existing Performance APIs. Development Tools does not
reimplement sampling, reports, or regression logic.

## Game-specific commands

Register commands from the scene/system that owns the behavior and unregister
them when that owner leaves scope. This naturally makes the palette context
sensitive without a global Service Locator.

Good candidates:

```text
teleport to authored marker
spawn test encounter
grant an item
set a quest/world-state fixture
force weather/time-of-day development state
connect/disconnect a local network test peer
load a profiling scenario
```

Poor candidates:

```text
raw arbitrary property setter
call any method by string
execute GDScript entered by the user
production moderation/admin console
```

## Relationship to future tooling

The command registry is intended to become the common entry point for later
development tooling such as scene validators, reproducible scenario runners, and
bug-report capture. Those systems should register bounded commands rather than
creating separate debug-menu frameworks.
