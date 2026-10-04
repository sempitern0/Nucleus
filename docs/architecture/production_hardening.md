# Iteration 18 — Production Hardening

## Objective

Convert a feature-complete reusable baseline into infrastructure that is easier
to trust, validate, and maintain.

This iteration intentionally does not add another large gameplay subsystem.

## Native headless tests

Nucleus now includes a dependency-free GDScript test runner under
`tests/headless/`.

Initial deterministic coverage targets high-value pure contracts:

```text
SemVer parsing/precedence
ValuePool limits/overflow/state restore
network utility validation/nonce generation
editor configuration warning contracts
```

The runner is deliberately small. Future suites should use the same pattern
until the project proves it needs a third-party test framework.

Run:

```bash
godot --headless --path . --script res://tests/headless/test_runner.gd
```

## Bootstrap smoke test

`tests/smoke/smoke_main.tscn` verifies:

- a compatible Godot 4.7+ runtime within major version 4;
- all mandatory default Autoloads are present.

It exits non-zero on failure, making it CI-friendly.

## Validation scenes

`examples/validation/gameplay_2d.tscn` and
`examples/validation/gameplay_3d.tscn` expose representative editor wiring for
ValuePool/regeneration/targeting.

They are removable fixtures, not sample-game dependencies.

## Editor configuration warnings

High-value editor-facing nodes now use Godot's native
`_get_configuration_warnings()` mechanism.

Iteration 18 adds warnings to:

```text
NucleusRegenerator
NucleusTargetAreaSensor2D
NucleusTargetAreaSensor3D
NucleusAnimationTreeStateBinding
```

The scripts are `@tool`, but runtime lifecycle work is explicitly skipped while
the editor is executing them. Runtime auto-resolution remains available.

## Static repository checks

`scripts/ci/static_checks.py` enforces:

```text
UTF-8 text
LF endings
final newline
no trailing whitespace
GDScript <= 100 columns
tab indentation
Nucleus prefix for public class_name
```

It has no Python package dependencies.

## Documentation consistency

`docs/documentation_coverage.json` maps every direct subsystem directory to a
technical document.

`scripts/ci/documentation_audit.py` compares that manifest against the actual
repository structure and fails if a subsystem is added without documentation.

## CI

`.github/workflows/nucleus-ci.yml` performs:

```text
static checks
documentation audit
Godot headless import
native GDScript tests
bootstrap smoke scene
Linux export
Windows export
Web export
```

The workflow pins Godot `4.7.2-stable`, currently the maintenance release in the
target 4.7 line.

Engine and official export templates are downloaded from the official
`godotengine/godot-builds` release assets and cached by GitHub Actions.

## Smoke export isolation

Nucleus intentionally has no game main scene.

`scripts/ci/smoke_exports.sh` copies the repository to a temporary directory and
sets the smoke scene as `run/main_scene` and installs CI-only export presets
only in that disposable copy before exporting.

CI therefore validates exportability without mutating the developer checkout or
changing the reusable template's main-scene policy.

## Remaining runtime validation

This delivery was statically checked in the generation environment, but that
environment did not provide a Godot executable or export templates.

Do not mark Iteration 18 runtime-validated until the project owner runs Godot
locally or the included CI completes successfully after the delta is applied.
