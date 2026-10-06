# Iteration 30 — Validation / Development Quality Gate

## Goal

Turn Nucleus' existing editor warnings and Resource validation contracts into one
reusable development-quality surface without creating another inspector, global
manager, or reflection-based debug system.

Prepared as a delta on top of:

```text
main
ddd9652e67f7571487d4b5c644518f1b0038a528
```

The template version remains `0.12.0-dev.1`.

## Delivered

```text
NucleusDevelopmentValidation
    validate_node_tree()
    validate_scene()
    validate_resource()
    validate_resource_object()
    format_report()

NucleusDevelopmentValidationCommands
    validation.run [path]
    validation.scene <path>
    validation.resource <path>

scripts/validation/run_validation.gd
```

The backend reuses contracts already present in Nucleus:

```text
Node._get_configuration_warnings()
Resource.get_validation_errors()
```

No subsystem-specific rules are duplicated in Development Tools.

## Validation model

Node configuration warnings become `WARNING` issues. Resource validation errors
become `ERROR` issues. Exported Resources reachable from a validated scene node
also participate, so authored scene wiring and reusable data assets can be
checked through one report.

The validator does not execute arbitrary methods. It calls only the two explicit
validation contracts above.

## Interactive workflow

The ready Development Tools shell now includes validation commands. Typical use:

```text
validation.run
validation.scene res://world/test_harbor.tscn
validation.resource res://data/items/catalog.tres
```

`validation.run` without a path validates the current scene. With a path it
selects scene or Resource validation from the loaded resource type.

## Headless / CI workflow

The same backend has a dependency-free SceneTree entry point:

```bash
godot --headless --path . \
  --script res://scripts/validation/run_validation.gd -- \
  --scene=res://world/test_harbor.tscn \
  --resource=res://data/items/catalog.tres
```

The process exits non-zero when any validation issue is found, so consuming games
can promote authored validation targets into a CI quality gate without changing
the interactive implementation.

The Nucleus native headless suite also covers warning/error collection and
exported Resource traversal.

## Development Tools fixes included

The ready shell no longer ships with `interact` as its palette toggle. Nucleus
continues to require a consuming game to opt into a dedicated semantic action or
open the palette programmatically.

The palette also no longer calls `grab_focus()` after a command has removed it
from the SceneTree. Scene reload/goto commands can therefore replace the current
scene without producing the previous focus error.

## Architectural boundary

```text
Owning subsystem
    defines warning / validation rule
        ↓
Validation backend
    aggregates normalized issues
        ↓
Development Tools / headless runner
    invokes and presents the report
```

This keeps the quality gate composable and allows future scenario-runner or bug
capture work to consume the same explicit command surface.
