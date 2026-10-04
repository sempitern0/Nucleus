# Nucleus

Nucleus is a reusable Godot project foundation for starting new games with a
tested baseline for application infrastructure, gameplay composition, UI, save,
input, audio, scene flow, accessibility, and production validation.

It is a **project template**, not an addon framework and not a catalogue of every
game mechanic.

## Status

| Contract | Current status |
| --- | --- |
| Template version | See [`VERSION`](VERSION) |
| Godot | 4.7.2-stable is the release-gated reference version |
| API | Pre-1.0; public contracts are usable but still allowed to evolve |
| CI | Static checks, docs, Godot parse/tests, smoke scene, cross-platform exports |
| License | MIT |

The default project intentionally has **no main game scene**. A consuming game
owns that decision.

## Design principles

Nucleus follows a small set of architectural rules:

- prefer Godot-native APIs over wrappers;
- composition over inheritance for game-facing systems;
- scene ownership unless cross-scene lifetime genuinely requires an Autoload;
- local signals before global mediation;
- no Service Locator;
- optional systems stay optional;
- public `class_name` identifiers use the `Nucleus` prefix;
- baseline features must be broadly reusable across game genres.

The default Autoload set is intentionally small:

```text
NucleusApp
NucleusSettings
NucleusInput
NucleusAudio
NucleusSave
NucleusSceneFlow
```

`EventBus` and networking remain opt-in modules.

## Included baseline

### Core

```text
application lifecycle
platform/path helpers
logging and diagnostics
settings
input and runtime rebinding
local multiplayer input ownership
audio
save, encryption, migrations, autosave
scene flow
localization
window, screenshot, and utility helpers
```

### Gameplay composition

```text
value pools and regeneration
damage / hitbox / hurtbox
interaction
cooldowns and lifetime
state machines
2D / 3D movement
2D / 3D camera
gameplay actions
attributes and modifiers
status effects
pooling and spawners
targeting and sensing
surface-aligned 3D decals
AnimationTree integration
camera and game-feel feedback
```

### UI

```text
settings bindings
focus and navigation
motion and feedback
screen effects
modal / toast / tooltip patterns
layout, data, and presentation helpers
accessibility-oriented behavior
```

### Optional modules

```text
EventBus
NetworkHandler / LAN helpers
Inventory / Equipment
```

## Start a new game

The recommended workflow is to start from a **versioned Nucleus package or
pinned commit**, not from an unpinned moving branch.

1. Obtain Nucleus and create a new repository for the game.
2. Open it with the Godot version declared in
   [`docs/policies/godot_compatibility.md`](docs/policies/godot_compatibility.md).
3. Change `application/config/name` and project-specific presentation settings.
4. Create the game's main scene and assign it in Project Settings.
5. Keep the default Autoloads until you intentionally replace a documented
   dependency.
6. Run the validation suite before game-specific work begins.

Detailed setup, including PowerShell and Git workflows, is documented in
[`docs/guides/installation.md`](docs/guides/installation.md).

## Validation

Fast local checks:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py
```

Editor regression tests:

```text
tests/editor/test_runner.tscn
```

Run that scene with **F6**.

Authoritative headless checks:

```bash
godot --headless --path . --import

godot \
  --headless \
  --path . \
  --check-only \
  --script res://tests/headless/test_runner.gd

godot \
  --headless \
  --path . \
  --script res://tests/headless/test_runner.gd

godot \
  --headless \
  --path . \
  res://tests/smoke/smoke_main.tscn
```

GitHub Actions additionally validates Linux, Windows, and Web smoke exports.

See
[`docs/guides/validation_ci_quickstart.md`](docs/guides/validation_ci_quickstart.md).

## Documentation

Start with [`docs/README.md`](docs/README.md).

The documentation model is:

```text
docs/guides/        editor and user workflows
docs/components/    technical component contracts
docs/modules/       optional module contracts
docs/architecture/  architecture and rationale
docs/policies/      compatibility and stability promises
docs/roadmap/       status, iterations, and future direction
```

The most important product contracts are:

- [Versioning](docs/policies/versioning.md)
- [Godot compatibility](docs/policies/godot_compatibility.md)
- [API stability](docs/policies/api_stability.md)
- [Deprecation](docs/policies/deprecation.md)
- [Installation](docs/guides/installation.md)
- [Releasing and packaging](docs/guides/releasing.md)
- [Changelog](CHANGELOG.md)

## Versioning

Nucleus follows Semantic Versioning for the **template itself**.

The Nucleus version is stored in [`VERSION`](VERSION). It is deliberately not
stored as the consuming game's application version in `project.godot`.

Before 1.0, public APIs are usable but may still change between Nucleus minor
versions. All intentional breaking changes must be documented.

See [`docs/policies/versioning.md`](docs/policies/versioning.md).

## Barebone lineage

Nucleus is the successor to the author's earlier `Barebone` Godot template.
Reusable ideas and selected implementation work were salvaged or redesigned,
but Nucleus does **not** provide a Barebone compatibility layer.

New projects should depend only on Nucleus contracts.

## License

Nucleus is licensed under the [MIT License](LICENSE).

A game created from Nucleus may use a different license, including a proprietary
one. When redistributing Nucleus-derived code, retain the MIT notice for the
Nucleus portions as required by the license.
