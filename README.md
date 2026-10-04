<p align="center">
  <img src="icon.svg" width="112" height="112" alt="Nucleus icon">
</p>

<h1 align="center">Nucleus</h1>

<p align="center">
  A production-oriented Godot project foundation: stable core, composable
  systems, and game-specific policy left to the game.
</p>

<p align="center">
  <a href="https://github.com/sempitern0/Nucleus/actions/workflows/nucleus-ci.yml">
    <img alt="Nucleus CI" src="https://github.com/sempitern0/Nucleus/actions/workflows/nucleus-ci.yml/badge.svg?branch=main">
  </a>
  <img alt="Godot 4.7.2" src="https://img.shields.io/badge/Godot-4.7.2-478CBF?logo=godot-engine&logoColor=white">
  <img alt="Project template" src="https://img.shields.io/badge/type-project%20template-6D5DFB">
  <img alt="Pre-1.0" src="https://img.shields.io/badge/status-pre--1.0-EA9A3A">
  <a href="LICENSE">
    <img alt="MIT License" src="https://img.shields.io/badge/license-MIT-2EA44F">
  </a>
</p>

Nucleus is a reusable Godot project foundation for starting games with a tested
baseline for application infrastructure, input, settings, save, audio, scene
flow, gameplay composition, UI/accessibility, optional production modules, and
validation.

It is a **project template**, not an addon framework and not a catalogue of every
game mechanic.

The icon reflects the same idea: a small stable nucleus in the center, with
independent systems orbiting around it. The core should stay predictable while
games compose only what they need.

## Project status

| Contract | Current status |
| --- | --- |
| Template version | See [`VERSION`](VERSION) |
| Godot | `4.7.2-stable` is the release-gated reference |
| API | Pre-1.0; usable, but public contracts may still evolve |
| CI | Static checks, docs, Godot tests, smoke scene, Linux/Windows/Web exports |
| License | [MIT](LICENSE) |
| Main CI | [Nucleus CI workflow](https://github.com/sempitern0/Nucleus/actions/workflows/nucleus-ci.yml) |

The default project intentionally has **no main game scene**. A consuming game
owns its entry point, art direction, game rules, and product-specific defaults.

## Philosophy

Nucleus follows a few rules that matter more than any individual component:

- **Godot-native first.** Wrap an engine API only when Nucleus genuinely owns a
  reusable policy around it.
- **Composition over inheritance.** Game-facing behavior is built from small
  nodes/resources around normal Godot scenes.
- **Scene ownership first.** Autoloads are kept intentionally small.
- **Semantic input.** Games ask for actions, not physical keys or controller
  button indices.
- **Production evidence drives reuse.** Real friction in consuming games earns a
  place in the template; speculative abstractions do not.
- **Optional systems stay optional.** Networking, inventory, loot, AI, world
  persistence, replication, and platform services do not become hidden baseline
  dependencies.
- **Game policy stays in the game.** Nucleus should make common work reliable
  without deciding how every game must feel or play.

The root [`AGENTS.md`](AGENTS.md) is the compact implementation contract for
human and AI contributors.

## Baseline Autoloads

The global surface is deliberately small:

```text
NucleusApp
NucleusSettings
NucleusInput
NucleusAudio
NucleusSave
NucleusSceneFlow
```

`EventBus`, networking, and other modules remain opt-in.

## What is included

| Area | Typical responsibilities | Start here |
| --- | --- | --- |
| Core runtime | lifecycle, logging, paths, windows, utilities | [`core_runtime.md`](docs/components/core_runtime.md) |
| Settings + input | runtime settings, rebinding, gamepads, local input | [`settings_and_input.md`](docs/components/settings_and_input.md) |
| Runtime services | audio, save, scene flow, localization | [`audio_save_scene_localization.md`](docs/components/audio_save_scene_localization.md) |
| Gameplay foundation | health/value pools, damage, interaction, timers, state | [`gameplay_foundation.md`](docs/components/gameplay_foundation.md) |
| Actions + stats | actions, attributes, modifiers, status effects | [`gameplay_actions_attributes_status.md`](docs/components/gameplay_actions_attributes_status.md) |
| Movement + camera | 2D/3D input, motors, camera rigs | [`gameplay_movement_camera.md`](docs/components/gameplay_movement_camera.md) |
| Pooling + targeting | pools, spawners, sensing, targeting | [`gameplay_pooling_targeting.md`](docs/components/gameplay_pooling_targeting.md) |
| World presentation | adaptive decals and reusable world feedback | [`world_decals.md`](docs/components/world_decals.md) |
| UI + accessibility | focus, navigation, motion, toast/modal/tooltip, layout | [`ui_and_accessibility.md`](docs/components/ui_and_accessibility.md) |
| Animation | AnimationTree-facing integration | [`animation_integration.md`](docs/components/animation_integration.md) |
| Camera/game feel | shake, impulses, feedback and motion policy | [`camera_game_feel.md`](docs/components/camera_game_feel.md) |

Optional modules currently cover EventBus, networking, Inventory / Equipment,
Probability / Loot, Persistent World State, AI / Navigation, online replication,
and provider-neutral platform services.

If you know the game problem but not the Nucleus subsystem, start with
[`docs/guides/real_game_patterns.md`](docs/guides/real_game_patterns.md). It maps
every component group and optional module to recognizable game-shaped use cases.

## Input that stays out of the player's way

Nucleus uses Godot's `Input` and `InputMap`; it does not replace them.

The baseline supports:

- keyboard/mouse and gamepad defaults;
- automatic active-device detection;
- one-player keyboard/gamepad hot-swap without replacing the local-player seat;
- device-aware prompts and controller-family labels;
- runtime rebinding persisted through Settings;
- scene-owned controller connection/disconnection toasts;
- explicit local-player ownership for couch multiplayer.

A key boundary is intentional:

```text
ui_accept / ui_cancel
    → active UI navigation, menus and dialogs

move_* / interact / primary_action / secondary_action / pause / game actions
    → gameplay semantics
```

A world scene should not interpret `ui_cancel` as "leave the game". The same
physical B/Circle button may be a gameplay action while an open menu still uses
it to go back. See
[`settings_input_quickstart.md`](docs/guides/settings_input_quickstart.md).

## Start a new game

Use a **versioned Nucleus package or pinned commit**, not an unpinned moving
branch.

1. Obtain Nucleus and create a new repository for the game.
2. Open it with the Godot version declared in
   [`docs/policies/godot_compatibility.md`](docs/policies/godot_compatibility.md).
3. Change `application/config/name` and project-specific presentation defaults.
4. Create the game's main scene and assign it in Project Settings.
5. Keep the baseline Autoloads until you intentionally replace a documented
   dependency.
6. Run validation before game-specific work begins.

Detailed setup, including PowerShell and Git workflows, is in
[`docs/guides/installation.md`](docs/guides/installation.md).

## Validation and CI

Fast local checks:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py
```

Authoritative Godot checks:

```bash
godot --headless --path . --import
godot --headless --path . --check-only --script res://tests/headless/test_runner.gd
godot --headless --path . --script res://tests/headless/test_runner.gd
godot --headless --path . res://tests/smoke/smoke_main.tscn
```

Editor regression tests are also available through
`tests/editor/test_runner.tscn` with **F6**.

GitHub Actions runs the same product contracts and additionally smoke-exports
Linux, Windows, and Web. The badge at the top of this README always links to the
current workflow state.

See
[`docs/guides/validation_ci_quickstart.md`](docs/guides/validation_ci_quickstart.md).

## Documentation map

Start with [`docs/README.md`](docs/README.md).

```text
docs/guides/        task-oriented workflows and practical recipes
docs/components/    baseline ownership and technical contracts
docs/modules/       optional module contracts
docs/architecture/  dependency direction and design rationale
docs/policies/      compatibility and stability promises
docs/roadmap/       iterations, evidence and future direction
```

Important product contracts:

- [Installation](docs/guides/installation.md)
- [Real-game patterns](docs/guides/real_game_patterns.md)
- [Versioning](docs/policies/versioning.md)
- [Godot compatibility](docs/policies/godot_compatibility.md)
- [API stability](docs/policies/api_stability.md)
- [Deprecation](docs/policies/deprecation.md)
- [Releasing and packaging](docs/guides/releasing.md)
- [Changelog](CHANGELOG.md)

## Versioning

Nucleus follows Semantic Versioning for the **template itself**.

The source of truth is [`VERSION`](VERSION), deliberately independent from the
consuming game's `application/config/version`.

Before 1.0, public APIs may evolve between Nucleus minor versions. Intentional
breaking changes still require changelog and migration documentation.

See [`docs/policies/versioning.md`](docs/policies/versioning.md).

## Open source

Nucleus is developed in the open under the [MIT License](LICENSE). Issues and
pull requests are welcome when they preserve the template's scope and ownership
rules.

Before contributing code, read [`AGENTS.md`](AGENTS.md) and the technical
contract for the subsystem you are changing. The goal is not to grow the largest
framework; it is to keep a small, dependable foundation that real games can
build on.

## Barebone lineage

Nucleus is the successor to the author's earlier `Barebone` Godot template.
Reusable ideas and selected implementation work were salvaged or redesigned,
but Nucleus does **not** provide a Barebone compatibility layer.

New projects should depend only on Nucleus contracts.

## License

Nucleus is licensed under the [MIT License](LICENSE).

A game created from Nucleus may use another license, including a proprietary
one. When redistributing Nucleus-derived code, retain the MIT notice for the
Nucleus portions as required by the license.
