# Validation and CI Quickstart

Nucleus validation has two local workflows:

```text
Godot editor
	fast manual feedback while developing

headless / CI
	authoritative automation and export gate
```

## Test infrastructure contract

All dependency-free unit/regression suites live under:

```text
tests/headless/*_test.gd
```

Every suite must:

```text
extend res://tests/headless/test_case.gd
define func run() -> Dictionary
use expect_true / expect_false / expect_equal / expect_float
return finish()
be registered in tests/headless/test_manifest.gd
```

`scripts/ci/static_checks.py` validates that contract before Godot starts.

Engine API symbols and GDScript parsing still require Godot itself. CI therefore
has a separate `--check-only` test-graph parse gate before executing assertions.

## Run tests from the Godot editor

Open:

```text
tests/editor/test_runner.tscn
```

Press **F6 — Run Current Scene**.

A clean result looks like:

```text
Nucleus editor tests: PASS (... checks, ... suites).
```

The automated suites now cover:

```text
SemanticVersion parsing / precedence
ValuePool limits / overflow / restoration
network utility validation
InputBindingCodec serialization
SmartDecal surface-basis contracts
NucleusWindow screenshot path/file helpers
Inventory / Equipment
Probability / Loot
Persistent World State
AI utility / navigation policies
editor configuration warnings
```

The editor runner is the convenient inner loop; headless parsing/runtime and
export smoke tests remain authoritative.

## Run validation fixtures

Useful fixtures include:

```text
examples/validation/gameplay_2d.tscn
examples/validation/gameplay_3d.tscn
examples/validation/smart_decal_3d.tscn
```

Use F6 and inspect configuration warnings and Output.

The automated bootstrap fixture is:

```text
tests/smoke/smoke_main.tscn
```

## Local static checks

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py
```

PowerShell:

```powershell
python .\scripts\ci\static_checks.py
python .\scripts\ci\documentation_audit.py
python .\scripts\ci\productization_audit.py
```

## Godot headless import

```bash
godot --headless --path . --import
```

## Parse the native test graph

```bash
godot \
  --headless \
  --path . \
  --check-only \
  --script res://tests/headless/test_runner.gd
```

This gate catches engine symbols and transitive GDScript compile errors before
runtime assertions execute.

## Native headless tests

```bash
godot \
  --headless \
  --path . \
  --script res://tests/headless/test_runner.gd
```

## Bootstrap smoke scene

```bash
godot \
  --headless \
  --path . \
  res://tests/smoke/smoke_main.tscn
```

## Smoke exports

With official Godot 4.7.2 templates installed:

```bash
GODOT_BIN=/path/to/godot \
  bash scripts/ci/smoke_exports.sh "$PWD"
```

## GitHub Actions

`.github/workflows/nucleus-ci.yml` runs repository audits first, then Godot
import, test parsing/runtime, smoke execution, and Linux/Windows/Web exports.

## Recommended local order

```text
1. static checks
2. editor test runner
3. affected visual validation scene when applicable
4. bootstrap smoke if Core/Autoloads changed
5. headless import
6. headless --check-only test graph
7. headless runtime tests
8. CI smoke exports
```

## Runtime validation status

Static generation checks are not equivalent to executing Godot.

Mark an iteration runtime-validated only after local Godot validation or a
successful CI run of import, parsing, runtime tests, smoke scene, and exports.
