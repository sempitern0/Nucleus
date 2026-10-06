# Iteration 31 — Scene Object Console

## Goal

Extend Development Tools from command discovery into a practical runtime scene
workbench without introducing arbitrary reflection or a global CheatManager.

Prepared as a cumulative delta on top of the Iteration 30 package and repository
baseline:

```text
main
ddd9652e67f7571487d4b5c644518f1b0038a528
```

## Delivered

```text
modules/development_tools/scene_objects/
    NucleusSceneObjectTools

modules/development_tools/adapters/
    NucleusSceneObjectDevelopmentCommands
```

The ready Development Tools scene now includes the Scene Object command adapter.

## Commands

Discovery:

```text
scene.nodes [query] [limit]
scene.group <group> [limit]
node.inspect <path> [query]
```

Safe property mutation:

```text
node.set <path> <property> <value>
```

Transform shortcuts:

```text
node.position2d
node.position3d
node.rotation2d
node.rotation3d
node.scale2d
node.scale3d
```

Runtime switches:

```text
node.visible
node.process
```

## Boundary

The implementation deliberately does not add:

```text
node.call
node.free
node.script
resource mutation
Autoload traversal
absolute SceneTree paths
Expression/eval
OS commands
```

`node.set` only accepts editor-visible, non-read-only values from a bounded type
set. Structural identity/reference properties are blocked.

This makes the console useful for runtime tuning while preserving the explicit
allowlist model established by Development Tools.

## Development loop

The intended workflow becomes:

```text
scene.nodes / scene.group
    find runtime object
        ↓
node.inspect
    inspect simple mutable state
        ↓
node.set / transform / visibility / processing
    run one experiment
        ↓
custom command
    promote repeated domain operations
        ↓
validation + performance
    verify and measure the scenario
```

## Documentation

Added:

```text
docs/modules/development_tools_scene_objects.md
docs/guides/scene_object_console_quickstart.md
docs/guides/custom_development_commands_tutorial.md
```

The custom-command tutorial covers ownership, registration lifecycle, typed
arguments, aliases/tags, normalized results, testing, release policy, and when to
promote a raw node experiment into a domain command.

## Tests

`scene_object_tools_test.gd` covers:

```text
node discovery
scene-relative paths
group discovery
property inspection
Vector2/bool mutation
2D/3D movement
visibility
processing switches
absolute-path rejection
structural property rejection
```

The suite is registered in the native headless test manifest.

## Version

No additional version bump is included. The cumulative development package
remains on the repository's current pre-release line:

```text
0.12.0-dev.1
```
