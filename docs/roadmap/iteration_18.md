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
- shared editor launcher over the same suite manifest;
- SemVer precedence/parsing regression suite;
- ValuePool limits/overflow/state regression suite;
- networking utility regression suite;
- InputBindingCodec serialization regression suite;
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

GitHub Actions validates:

```text
static source checks
documentation audit
Godot headless import
native test-graph parsing
headless test suite
bootstrap smoke scene
Linux release smoke export
Windows release smoke export
Web release smoke export
```

The CI install script pins official Godot `4.7.2-stable` assets.

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

## First validation feedback

The first owner-side validation exposed infrastructure issues rather than
component defects:

```text
InputBindingCodec enum reconstruction
test suite using helpers not present in test_case.gd
test suite referencing a non-Godot KeyLocation constant
repository trailing whitespace blocking the first CI run
```

These are treated as Iteration 18 hardening fixes, not a new feature iteration.

The input regression suite now uses only Godot 4.7 `KeyLocation` values:

```text
KEY_LOCATION_UNSPECIFIED
KEY_LOCATION_LEFT
KEY_LOCATION_RIGHT
```

The suite also uses only the canonical Nucleus test API:

```text
expect_true
expect_false
expect_equal
expect_float
finish
```

## Test infrastructure hardening

`static_checks.py` now validates the headless suite contract before Godot starts:

```text
suite extends test_case.gd
run() -> Dictionary exists
finish() is returned
expect_* helpers exist in test_case.gd
legacy check()/result() calls are rejected
every *_test.gd is registered in test_manifest.gd
manifest entries point to real suites
```

Godot then runs a dedicated `--check-only` parse of the preloaded test graph
before executing runtime assertions.

CI is also staged so cheap static/documentation failures happen before Godot is
downloaded, and export templates are downloaded only after tests and smoke pass.

## Acceptance gate

Iteration 18 remains **runtime-validation pending** until a clean local/CI run
passes all of:

1. static checks;
2. documentation audit;
3. headless import;
4. native test-graph parse;
5. native runtime tests;
6. bootstrap smoke scene;
7. Linux export;
8. Windows export;
9. Web export.

A failure in this sequence should be fixed before starting another baseline
feature iteration.
