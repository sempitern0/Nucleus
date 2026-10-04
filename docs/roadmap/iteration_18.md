# Iteration 18 — Production Hardening

Base audited before implementation:

```text
sempitern0/Nucleus
main
4c8936ff26d96a4167c1ca2997217900e5345faf
```

This iteration is a delta only. It was produced without mutating GitHub.

## Implemented

### Automated validation

- dependency-free GDScript headless runner;
- SemVer precedence/parsing regression suite;
- ValuePool limits/overflow/state regression suite;
- networking utility regression suite;
- editor configuration-warning regression suite;
- mandatory-Autoload/engine smoke scene.

### Editor diagnostics

Native `_get_configuration_warnings()` were added to high-value composition
points:

```text
NucleusRegenerator
NucleusTargetAreaSensor2D
NucleusTargetAreaSensor3D
NucleusAnimationTreeStateBinding
```

The scripts run as `@tool` only to expose Godot Scene-dock diagnostics. Runtime
lifecycle work is guarded from editor execution.

### Validation scenes

```text
examples/validation/gameplay_2d.tscn
examples/validation/gameplay_3d.tscn
```

These are removable wiring fixtures, not dependencies of the template.

### CI and exports

GitHub Actions now has a proposed validation path for:

```text
static source checks
documentation audit
Godot headless import
headless test suite
bootstrap smoke scene
Linux release smoke export
Windows release smoke export
Web release smoke export
```

The CI install script pins official Godot `4.7.2-stable` editor and export
templates from `godotengine/godot-builds`.

Smoke export configuration is injected only into a disposable project copy, so
the reusable template does not gain a permanent game main scene or project
export presets.

### Documentation recovery

The Iteration 17 documentation model is preserved:

```text
docs/components/    technical contracts
docs/modules/       optional module contracts
docs/guides/        editor-first workflows
docs/architecture/  rationale/boundaries
docs/roadmap/       status/handoff
```

Recovered contracts cover every direct subsystem under Core, Modules, Gameplay,
and UI. `docs/documentation_coverage.json` makes that coverage machine-checkable.

## Static validation performed during delivery

The generation environment validated:

```text
Python syntax
Bash syntax
GitHub Actions YAML syntax
Nucleus static style/encoding rules
documentation manifest against all 46 known direct subsystem directories
```

Godot itself was not available in the generation environment.

## Acceptance gate

Iteration 18 must remain **runtime-validation pending** until, after applying the
delta, either local Godot or CI passes:

1. headless import;
2. headless tests;
3. bootstrap smoke scene;
4. Linux export;
5. Windows export;
6. Web export.

A runtime/export failure should be fixed before starting another baseline
feature iteration.

## Validation cleanup after first local Godot run

The first owner-side Godot validation identified two developer-experience gaps.
They were corrected as part of Iteration 18 rather than opening a new feature
iteration:

```text
InputBindingCodec enum reconstruction
    serialized integers are explicitly cast back to Godot enum types
    no int-as-enum warning suppression is required

editor test launcher
    tests/editor/test_runner.tscn
    F6 runs the same suite manifest as headless CI
```

An InputBindingCodec round-trip suite now covers keyboard, mouse, joypad button,
and joypad axis serialization. The validation quickstart now distinguishes the
fast editor loop from the authoritative headless/export acceptance gate.
