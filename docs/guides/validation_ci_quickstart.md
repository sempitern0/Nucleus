# Validation and CI Quickstart

Nucleus validation has two local workflows:

```text
Godot editor
	fast manual feedback while developing

headless / CI
	authoritative automation and export gate
```

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

Do not treat this editor runner as a replacement for headless import or export
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
then exits. Exiting without errors/warnings means that smoke execution passed.

## Local static checks

From the repository root:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
```

Both scripts use only the Python standard library.

## Godot headless import

With Godot 4.7.x available:

```bash
godot --headless --path . --import
```

This catches project import/parse failures.

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

Install the official Godot 4.7.2 editor/export templates, then run:

```bash
GODOT_BIN=/path/to/godot \
  bash scripts/ci/smoke_exports.sh "$PWD"
```

The script exports disposable Linux, Windows, and Web builds without changing
your working `project.godot` or requiring committed project export presets.

## GitHub Actions

`.github/workflows/nucleus-ci.yml` performs the complete sequence automatically.

It downloads official Godot binaries/templates through
`scripts/ci/install_godot.sh` and caches them.

## Recommended local order

For normal development:

```text
1. F6 tests/editor/test_runner.tscn
2. F6 the affected examples/validation scene
3. F6 tests/smoke/smoke_main.tscn when Core/Autoloads change
4. headless import + tests before integrating the iteration
5. smoke exports / CI before marking the iteration fully validated
```

## Runtime validation status

Static generation checks are not equivalent to executing Godot.

Only mark an iteration runtime-validated after local Godot validation or a
successful CI run of import, tests, smoke scene, and exports.
