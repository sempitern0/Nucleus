# Development Tools — Validation addendum

Iteration 30 adds a shared validation backend to the optional Development Tools
workflow.

The backend deliberately reuses existing Nucleus contracts:

```text
Node._get_configuration_warnings()
Resource.get_validation_errors()
```

Available palette commands:

```text
validation.run [path]
validation.scene <path>
validation.resource <path>
```

`validation.run` with no path validates the current scene. Scene validation also
checks exported Resources reachable from scene nodes when those Resources expose
`get_validation_errors()`.

For automation, use:

```bash
godot --headless --path . \
  --script res://scripts/validation/run_validation.gd -- \
  --scene=res://path/to/scene.tscn \
  --resource=res://path/to/resource.tres
```

The runner returns a non-zero exit code if it finds any warning or error. This is
intended for explicit, authored validation targets rather than an implicit scan
of every Resource in a consuming game.
