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

The headless test runner is a normal project scene:

```text
tests/headless/test_runner.tscn
```

This is deliberate. Running the suite as a scene lets Godot load `project.godot`
and register the normal Nucleus Autoloads before the test manifest and its
transitive scripts are compiled. Do not launch the native suite with
`--script tests/headless/test_runner.gd`.

The manifest uses `preload()`, so loading the scene still compiles every
registered suite before runtime assertions execute. A compile/API error therefore
fails the same CI step as the native suite instead of using a second CLI script
context with different Autoload behavior.

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

Use the same Godot line as CI (`4.7.2-stable`):

```bash
godot --headless --path . --import
```

On Windows, keeping the executable in a variable makes the sequence easier to
repeat:

```powershell
$godot = "C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe"
& $godot --version
& $godot --headless --path . --import
```

Use the normal executable instead when the console build is not installed.

## Native headless tests

Linux/macOS:

```bash
godot   --headless   --path .   res://tests/headless/test_runner.tscn
```

PowerShell:

```powershell
& $godot --headless --path . res://tests/headless/test_runner.tscn
$LASTEXITCODE
```

The runner exits with `0` on success and `1` when one or more assertions fail.
Script compilation failures also make the Godot process fail before a PASS can
be emitted.

## Bootstrap smoke scene

```bash
godot   --headless   --path .   res://tests/smoke/smoke_main.tscn
```

This separately verifies the required default Autoloads and compatible Godot
runtime.

## Why the runner is a scene

Nucleus source legitimately references its project Autoload names, for example
`NucleusApp` and `NucleusInput`.

A standalone script launched with `godot --script` is not the same lifecycle as
loading a project scene. In particular, `--check-only --script` can parse a
transitive test graph before those project singletons are available to the
script context. That produces misleading `Identifier not found: NucleusApp`
style errors even when `[autoload]` in `project.godot` is correct.

The scene runner uses the same project initialization model as the consuming
game and smoke fixture, which is the behavior Nucleus actually promises.

## Tests that need SceneTree lifecycle

Most suites intentionally stay lightweight and can instantiate Resources or
plain Nodes without scene attachment.

Tests that use APIs requiring live global transforms, `_ready()`, physics or
other SceneTree state must attach their parentless fixture through the helpers in
`tests/headless/test_case.gd`:

```gdscript
var root := Node3D.new()
expect_true(attach_test_node(root), "Fixture requires a live SceneTree.")

# exercise global_position/global_transform/lifecycle

free_test_node(root)
```

Do not use `global_position` or `global_transform` on a detached `Node3D` and
then treat the resulting engine fallback as test data.

## Smoke exports

With official Godot 4.7.2 templates installed:

```bash
GODOT_BIN=/path/to/godot   bash scripts/ci/smoke_exports.sh "$PWD"
```

## GitHub Actions

`.github/workflows/nucleus-ci.yml` runs repository audits first, then Godot
import, the native headless test scene, bootstrap smoke execution, and
Linux/Windows/Web exports.

The native scene is both the transitive GDScript compile gate and the assertion
runner because its manifest preloads every suite.

## Recommended local order

```text
1. static checks
2. editor test runner while iterating
3. affected visual validation scene when applicable
4. headless import
5. headless native test scene
6. bootstrap smoke scene if Core/Autoloads changed
7. CI smoke exports for release-facing work
```

## Runtime validation status

Static generation checks are not equivalent to executing Godot.

Call a change runtime-validated only after local Godot validation or a successful
CI run covering import, native runtime tests, the smoke scene, and relevant
exports.
