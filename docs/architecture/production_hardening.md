# Production Hardening and Validation

## Objective

Nucleus includes validation infrastructure so a reusable project foundation is
easier to trust, test, and maintain without requiring a third-party test stack.

## Native headless tests

The dependency-free GDScript runner lives under `tests/headless/`.

Deterministic coverage targets high-value contracts such as:

```text
SemVer parsing/precedence
ValuePool behavior
network utilities and replication helpers
input binding serialization
settings contracts
editor configuration warnings
optional module invariants
```

## Test-suite contract

`tests/headless/test_case.gd` is the assertion API:

```text
expect_true
expect_false
expect_equal
expect_float
finish
```

Suites define `run() -> Dictionary`, return through `finish()`, and are
registered in `test_manifest.gd`.

`scripts/ci/static_checks.py` verifies this structure without requiring Godot.
Godot's parser remains authoritative for engine symbols, typed APIs, and
GDScript semantics.

## Godot parse gate

CI parses the native test graph before executing it:

```bash
godot \
  --headless \
  --path . \
  --check-only \
  --script res://tests/headless/test_runner.gd
```

The manifest uses `preload()`, so parsing the runner traverses registered suites.
Parse/API failures are therefore separated from assertion failures.

## Bootstrap smoke test

`tests/smoke/smoke_main.tscn` verifies a compatible Godot runtime and mandatory
default Autoloads. It exits non-zero on failure.

## Validation scenes

`examples/validation/gameplay_2d.tscn` and
`examples/validation/gameplay_3d.tscn` provide removable editor fixtures for
representative gameplay wiring.

## Editor configuration warnings

High-value editor-facing nodes use Godot's native
`_get_configuration_warnings()` mechanism. Runtime guards remain in place; the
warnings surface common wiring errors before Play.

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

`docs/documentation_coverage.json` maps direct subsystem directories to
technical documents. `scripts/ci/documentation_audit.py` compares that manifest
with repository structure.

## CI

`.github/workflows/nucleus-ci.yml` performs:

```text
static checks
documentation audit
productization audit
Godot headless import
native test-graph parse
native GDScript tests
bootstrap smoke scene
Linux export
Windows export
Web export
```

The workflow pins Godot `4.7.2-stable`.

## Smoke export isolation

`scripts/ci/smoke_exports.sh` copies the repository to a temporary directory,
sets the smoke scene as `run/main_scene`, and installs CI-only export presets
there. Validation therefore does not mutate the reusable template checkout.

## Acceptance rule

A local editor PASS is useful feedback but is not the production gate. A change
claiming runtime/export validation should pass:

```text
static checks
documentation audit
productization audit
headless import
test-graph parse
runtime test suite
bootstrap smoke scene
Linux / Windows / Web smoke exports
```
