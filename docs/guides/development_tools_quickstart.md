# Development Tools Quickstart

Use Development Tools when the project starts accumulating temporary debug
buttons, one-off keybinds, or console-like helpers.

## Fastest setup

Instance:

```text
res://modules/development_tools/development_tools.tscn
```

in a development shell or directly under the current world scene.

The scene provides a registry, built-in framework commands, and a hidden command
palette.

## Open it

Call:

```gdscript
$DevelopmentTools.open_palette()
```

or create a game-owned InputMap action such as:

```text
development_tools_toggle
```

and assign it to the scene's `toggle_action` export. Nucleus intentionally does
not choose F1, tilde, or another physical binding for every game.

## Try the built-ins

```text
dev.context
scene.current
scene.reload
dev.help scene
```

To change scenes:

```text
scene.goto res://world/test_harbor.tscn
```

The scene command goes through `NucleusSceneFlow`.

## Register a game command

```gdscript
@export var registry: NucleusDevelopmentCommandRegistry

func _ready() -> void:
    registry.register_command(
        NucleusDevelopmentCommand.build(
            &"boat.teleport",
            "Teleport boat",
            _teleport_boat,
            "Teleport the active boat to a named marker.",
            &"Nautica",
            [
                NucleusDevelopmentCommandArgument.build(
                    &"marker",
                    TYPE_STRING,
                ),
            ],
        )
    )

func _teleport_boat(
    arguments: Array,
    _context: Dictionary,
) -> NucleusDevelopmentCommandResult:
    var marker_name := str(arguments[0])
    var marker := find_marker(marker_name)
    if marker == null:
        return NucleusDevelopmentCommandResult.failure(
            "Unknown marker: %s" % marker_name
        )

    boat.global_transform = marker.global_transform
    return NucleusDevelopmentCommandResult.success(
        "Boat moved to %s" % marker_name
    )
```

Unregister scene-owned commands in `_exit_tree()` when their lifetime should end
with that scene.

## Typed arguments

Available primitive types:

```text
TYPE_STRING
TYPE_INT
TYPE_FLOAT
TYPE_BOOL
```

Quoted values work:

```text
encounter.spawn 12 "Harbor Patrol" true
```

Do not use the parser as a scripting language. Prefer Resources or authored data
for complex fixtures.

## Add Performance commands

Add a node using `NucleusPerformanceDevelopmentCommands` and assign:

```text
registry_path
sampler_path
```

You then get:

```text
performance.report
performance.trace streaming_started
performance.compare user://baseline.json
performance.clear
```

This is a useful loop for profiling a repeatable gameplay scenario:

```text
load scenario
→ mark traces
→ play workload
→ save/compare report
→ inspect regression
```

## Release behavior

Development Tools is debug-only by default. Keep it that way unless a dedicated
QA build intentionally needs the palette.

The registry never executes arbitrary source text, methods, OS commands, or
properties from user input. Only explicitly registered callbacks are callable.

## Technical contract

See:

[`../modules/development_tools.md`](../modules/development_tools.md)
