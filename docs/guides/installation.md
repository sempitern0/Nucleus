# Installing Nucleus for a New Game

## Recommended use

Nucleus is designed to be the **starting project** for a game.

It is not currently distributed as a Godot addon and it does not attempt to
merge itself automatically into an existing `project.godot`.

For a new game, use a versioned Nucleus release package or an exact pinned
commit.

## Requirements

Use the engine version declared in:

```text
docs/policies/godot_compatibility.md
```

The current release-gated reference is Godot 4.7.2-stable.

## Option A — release package

When a Nucleus package is available:

1. verify the package SHA-256 file;
2. extract `Nucleus-<version>.zip`;
3. rename the extracted directory to the game name;
4. initialize the game's own Git repository;
5. open `project.godot` in the supported Godot version.

A release package includes a `RELEASE_MANIFEST.json` describing the Nucleus
version, source commit, compatibility target, and hashes of packaged files.

## Option B — pinned Git checkout

Example:

```bash
git clone https://github.com/sempitern0/Nucleus.git MyGame
cd MyGame
git checkout <exact-tag-or-commit>
rm -rf .git
git init
```

PowerShell equivalent for the repository reset:

```powershell
Remove-Item -Recurse -Force .git
git init
```

Do not base a long-running game on an unrecorded moving `main`. Record the
starting Nucleus version or commit in the game documentation.

## First Godot setup

After opening the project:

1. change `application/config/name`;
2. replace the icon and game-specific presentation settings when ready;
3. create the game's main scene;
4. assign that scene as `run/main_scene`;
5. review the default InputMap actions;
6. keep the mandatory Autoloads until you intentionally redesign their
   documented responsibilities;
7. keep `default_bus_layout.tres` unless the game's audio architecture replaces
   it deliberately.

The absence of a default main scene in Nucleus is intentional.

## Validate before game-specific changes

Run:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py
```

Then run `tests/editor/test_runner.tscn` with F6.

For a full gate, use the headless and export sequence in:

```text
docs/guides/validation_ci_quickstart.md
```

Establishing a known-green starting commit makes later game regressions much
easier to distinguish from template problems.

## What to keep

For the first production project, keep:

```text
core/
components/
modules/
tests/
scripts/ci/
docs/
examples/validation/
.github/workflows/nucleus-ci.yml
```

The tests, validation scenes, and documentation are intentionally part of the
development baseline. Remove them only when the game has replacement tooling.

`modules/` remains opt-in even when the directory is present.

## Where game code should go

Do not force game-specific systems into Nucleus directories merely because they
can be reused once.

A practical initial structure is:

```text
game/
    actors/
    levels/
    systems/
    ui/
    data/
assets/
```

Keep `core/`, generic `components/`, and optional `modules/` focused on reusable
infrastructure. Promote game code into Nucleus only after repeated cross-project
evidence.

## Modifying Nucleus inside the game

Vendoring is intentional. A game may modify Nucleus source.

For maintainability:

- keep Nucleus-origin changes in focused commits;
- avoid renaming public Nucleus types without a reason;
- preserve tests for modified reusable behavior;
- record template-level fixes that should be upstreamed;
- merge later Nucleus versions selectively rather than assuming a package
  manager can resolve local changes.

## Installing into an existing Godot project

This is possible but is not the preferred path.

An existing project must manually reconcile at least:

```text
Autoloads
InputMap
audio bus layout
project settings
settings/save paths
scene-flow assumptions
class_name collisions
existing project architecture
```

Copying only `core/` or `components/` without those contracts can create a
partially configured project.

For an established game, integrate only the Nucleus systems you need and follow
their component/module documentation rather than treating Nucleus as a one-click
installer.

## Licensing a game built from Nucleus

The Nucleus repository is MIT licensed.

A derived game may use another license, including a proprietary one. If the
game's root license differs, retain the Nucleus MIT notice for the Nucleus code,
for example under a `LICENSES/` or third-party notices directory.
