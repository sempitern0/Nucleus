# Iteration 18 — Production Hardening

## Objective

Convert a feature-complete reusable baseline into infrastructure that is easier
to trust, validate, and maintain.

This iteration intentionally does not add another large gameplay subsystem.

## Native headless tests

Nucleus includes a dependency-free GDScript test runner under `tests/headless/`.

Initial deterministic coverage targets high-value contracts:

```text
SemVer parsing/precedence
ValuePool limits/overflow/state restore
network utility validation/nonce generation
InputBindingCodec serialization round-trips
editor configuration warning contracts
```

The runner is deliberately small. Future suites should use the same pattern
until the project proves it needs a third-party test framework.

## Test-suite contract

`tests/headless/test_case.gd` is the single assertion API:

```text
expect_true
expect_false
expect_equal
expect_float
finish
```

Suites must define `run() -> Dictionary`, finish through `finish()`, and be
registered in `test_manifest.gd`.

`scripts/ci/static_checks.py` verifies this structure without requiring Godot.
It also rejects the obsolete `check()` / `result()` convention and detects
unknown `expect_*` calls.

This static contract does not attempt to duplicate the Godot parser. Engine
symbols, enum constants, typed APIs, and GDScript semantics are validated by the
Godot test-graph parse stage.

## Godot parse gate

CI explicitly parses the native test graph before executing tests:

```bash
godot \
  --headless \
  --path . \
  --check-only \
  --script res://tests/headless/test_runner.gd
```

The manifest uses `preload()`, so parsing the runner traverses the registered
suite graph. Parse/API failures are therefore separated from assertion failures
in CI output.

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

High-value editor-facing nodes use Godot's native
`_get_configuration_warnings()` mechanism.

Iteration 18 covers:

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
headless test-suite contract
test manifest completeness
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
native test-graph parse
native GDScript tests
bootstrap smoke scene
Linux export
Windows export
Web export
```

The workflow pins Godot `4.7.2-stable`.

CI is intentionally staged by cost:

```text
cheap Python checks
    ↓
Godot editor download/import/tests
    ↓
large export-template download
    ↓
cross-platform smoke exports
```

Export templates are not downloaded until the code has passed the cheaper
validation gates.

## Smoke export isolation

Nucleus intentionally has no game main scene.

`scripts/ci/smoke_exports.sh` copies the repository to a temporary directory and
sets the smoke scene as `run/main_scene` and installs CI-only export presets
only in that disposable copy before exporting.

CI therefore validates exportability without mutating the developer checkout or
changing the reusable template's main-scene policy.

## Acceptance rule

A local editor PASS is useful feedback but is not the production gate.

An iteration is runtime/export validated only after the following all pass:

```text
static checks
documentation audit
headless import
test-graph parse
runtime test suite
bootstrap smoke scene
Linux / Windows / Web smoke exports
```
