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

`scripts/ci/static_checks.py` validates that contract before Godot starts. This
catches missing manifest entries, unknown `expect_*` helpers, legacy
`check()`/`result()` calls, and malformed suite entry points.

Engine API symbols and GDScript parsing still require Godot itself. CI therefore
has a separate `--check-only` test-graph parse gate before executing assertions.

## Run tests from the Godot editor

Open:

```text
tests/editor/test_runner.tscn
```

Press **F6 — Run Current Scene**.

The scene executes the same dependency-free suites used by the headless runner,
prints one PASS/FAIL summary in Output, then exits the running scene.

A clean result looks like:

```text
Nucleus editor tests: PASS (... checks, ... suites).
```

The current automated suites cover:

```text
SemanticVersion parsing / precedence
ValuePool limits / overflow / state restoration
network utility validation
InputBindingCodec serialization round-trips
editor configuration warnings
```

Do not treat this editor runner as a replacement for headless parsing or export
smoke tests. It is the convenient inner development loop.

## Run validation fixtures from the editor

The following scenes are intentionally small composition fixtures:

```text
examples/validation/gameplay_2d.tscn
examples/validation/gameplay_3d.tscn
```

Open either scene and press **F6**. Use the Scene dock configuration warnings and
Output panel to detect invalid wiring or runtime errors.

The automated bootstrap fixture is:

```text
tests/smoke/smoke_main.tscn
```

When run with F6, it validates the mandatory Autoloads and supported engine line,
then exits. Exiting with the PASS line and no errors means that smoke execution
passed.

## Local static checks

From the repository root:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
```

On PowerShell:

```powershell
python .\scripts\ci\static_checks.py
python .\scripts\ci\documentation_audit.py
```

Both scripts use only the Python standard library.

Run these before launching the more expensive Godot validation path.

## Godot headless import

With Godot 4.7.x available:

```bash
godot --headless --path . --import
```

This catches project import/parse failures.

## Parse the native test graph

Before executing assertions:

```bash
godot \
  --headless \
  --path . \
  --check-only \
  --script res://tests/headless/test_runner.gd
```

This is the dedicated compile/parse gate for the runner, manifest, preloaded
suites, and the symbols they reference.

## Native headless tests

```bash
godot \
  --headless \
  --path . \
  --script res://tests/headless/test_runner.gd
```

The headless runner uses the same suite manifest as the editor runner and exits
non-zero when a suite fails.

## Bootstrap smoke scene

```bash
godot \
  --headless \
  --path . \
  res://tests/smoke/smoke_main.tscn
```

This checks mandatory Autoloads and the target engine line.

## Smoke exports

Install the official Godot 4.7.2 export templates, then run:

```bash
GODOT_BIN=/path/to/godot \
  bash scripts/ci/smoke_exports.sh "$PWD"
```

The script exports disposable Linux, Windows, and Web builds without changing
your working `project.godot` or requiring committed project export presets.

## GitHub Actions

`.github/workflows/nucleus-ci.yml` performs the complete sequence automatically.

Cheap repository checks run first. Godot is installed only after static and
documentation checks pass. Export templates are installed only after import,
test-graph parsing, runtime tests, and the bootstrap smoke scene pass.

This keeps early failures fast and avoids downloading the large export-template
archive when the project is not yet ready to export.

## Recommended local order

For normal development:

```text
1. python scripts/ci/static_checks.py
2. F6 tests/editor/test_runner.tscn
3. F6 the affected examples/validation scene
4. F6 tests/smoke/smoke_main.tscn when Core/Autoloads change
5. headless import
6. headless --check-only test graph
7. headless runtime tests
8. smoke exports / CI before marking the iteration fully validated
```

## Runtime validation status

Static generation checks are not equivalent to executing Godot.

Only mark an iteration runtime-validated after local Godot validation or a
successful CI run of import, test parsing, runtime tests, smoke scene, and
exports.
