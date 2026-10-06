<p align="center">
  <img src="icon.svg" width="112" height="112" alt="Nucleus icon">
</p>

<h1 align="center">Nucleus</h1>

<p align="center">
  A production-oriented Godot project foundation with stable core services,
  composable gameplay systems, optional production modules, and CI.
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

Nucleus is a reusable Godot 4.7 project foundation. It provides application
infrastructure and cross-genre building blocks while leaving game rules, content,
art direction, balance, backend policy, and product decisions to the consuming
project.

It is a **project template**, not an addon framework. Godot remains the source of
truth for scenes, physics, animation, rendering, multiplayer, resources, and UI.
Nucleus adds policy only where a reusable ownership boundary is useful.

## Status

| Contract | Current state |
| --- | --- |
| Template version | [`VERSION`](VERSION) |
| Reference engine | Godot `4.7.2-stable` |
| API stability | Pre-1.0; public contracts may still evolve |
| Runtime validation | Native headless tests + smoke scene |
| Export validation | Linux, Windows, Web smoke exports |
| License | [MIT](LICENSE) |

The template intentionally has **no main game scene**. A game owns its entry
point and opts into the systems it needs.

## Start here

| You want to... | Read |
| --- | --- |
| Create a project from Nucleus | [Installation](docs/guides/installation.md) |
| Understand the baseline | [Foundation quickstart](docs/guides/foundation_quickstart.md) |
| Learn by building | [Tutorial index](docs/guides/tutorials/README.md) |
| Find a system from a game problem | [Real-game patterns](docs/guides/real_game_patterns.md) |
| Configure renderer/project defaults | [Project configuration](docs/guides/project_configuration.md) |
| Diagnose integration problems | [Troubleshooting](docs/guides/troubleshooting.md) |
| Run validation and CI | [Validation and CI](docs/guides/validation_ci_quickstart.md) |
| Package a Nucleus release | [Releasing](docs/guides/releasing.md) |

The full documentation index is [`docs/README.md`](docs/README.md).

## Core runtime

Nucleus keeps the global surface deliberately small:

```text
NucleusApp
NucleusSettings
NucleusInput
NucleusAudio
NucleusSave
NucleusSceneFlow
```

| Area | Guide / contract |
| --- | --- |
| Lifecycle, logging, paths, platform helpers | [Core runtime](docs/components/core_runtime.md) |
| Settings, input, rebinding, local devices | [Settings and input](docs/components/settings_and_input.md) |
| Audio, save, scene flow, localization | [Runtime services](docs/guides/runtime_services_quickstart.md) |
| UI, focus, responsive layout, accessibility | [UI quickstart](docs/guides/ui_quickstart.md) |

Optional modules are not promoted to Autoloads merely for convenience.

## Gameplay composition

| Need | Start here |
| --- | --- |
| Health/resources, damage, interaction, timers, state | [Gameplay foundation](docs/guides/gameplay_foundation_quickstart.md) |
| Actions, attributes, modifiers, status effects | [Actions / attributes / status](docs/guides/actions_attributes_status_quickstart.md) |
| 2D/3D movement and camera | [Movement / camera contract](docs/components/gameplay_movement_camera.md) |
| Third-person controller | [3D controller tutorial](docs/guides/tutorials/third_person_3d.md) |
| Pooling, spawning, targeting | [Pooling / targeting](docs/guides/pooling_targeting_quickstart.md) |
| Camera feedback and game feel | [Camera / game feel](docs/guides/camera_game_feel_quickstart.md) |
| World decals | [Smart decals](docs/guides/smart_decals_quickstart.md) |

Composition is preferred over inheritance. Scene-owned components communicate
through explicit references and local signals unless a broader lifetime is
actually required.

## 3D animation and character rigs

Nucleus does not replace Godot's animation stack. `AnimationPlayer`,
`AnimationTree`, `Skeleton3D`, `SkeletonModifier3D`, IK modifiers,
`PhysicalBoneSimulator3D`, `BoneAttachment3D`, and the importer remain native.

Nucleus provides small adapters for common gameplay integration:

```text
state machine → AnimationTree state machine
CharacterBody velocity → locomotion parameters
GameplayAction → AnimationTree state / OneShot
AnimationPlayer method tracks → local animation events
PhysicalBoneSimulator3D → reusable ragdoll lifecycle
```

Use these documents when moving from prototype geometry to a production rig:

- [Animation integration contract](docs/components/animation_integration.md)
- [Animation integration quickstart](docs/guides/animation_integration_quickstart.md)
- [3D character animation tutorial](docs/guides/tutorials/character_animation_3d.md)

The tutorial covers imported humanoids and reusable animation sets from common
pipelines such as Mixamo, KayKit, and Mesh2Motion, including Godot retargeting,
AnimationTree locomotion, SkeletonModifier3D/IK, attachments, and ragdoll.

## Optional production modules

| Capability | Documentation |
| --- | --- |
| Performance budgets, diagnostics, traces | [Performance](docs/guides/performance_quickstart.md) |
| Development command palette and validation | [Development tools](docs/modules/development_tools.md) |
| Networking bootstrap | [Networking](docs/guides/networking_quickstart.md) |
| Authoritative online replication | [Online replication](docs/guides/online_replication_quickstart.md) |
| Dedicated multiplayer deployment | [Multiplayer deployment](docs/guides/multiplayer_deployment_quickstart.md) |
| Inventory and equipment | [Inventory / equipment](docs/guides/inventory_equipment_quickstart.md) |
| Probability and loot | [Loot](docs/guides/loot_quickstart.md) |
| Persistent world state | [Persistent world](docs/guides/persistent_world_quickstart.md) |
| Utility AI and navigation | [AI / navigation](docs/guides/ai_navigation_quickstart.md) |
| Platform/store provider boundary | [Platform services](docs/guides/platform_services_quickstart.md) |
| Signed DLC and data-only community mods | [Content packs](docs/guides/content_packs_quickstart.md) |
| Touch, haptics, orientation, permissions | [Mobile](docs/guides/mobile_quickstart.md) |

## Development tools

The optional development shell provides a searchable command palette, typed
command arguments, bounded history, validation commands, and scene-object
inspection/manipulation intended for local development builds.

Start with:

- [Development Tools quickstart](docs/guides/development_tools_quickstart.md)
- [Custom command tutorial](docs/guides/custom_development_commands_tutorial.md)
- [Scene object console](docs/guides/scene_object_console_quickstart.md)
- [Development validation](docs/guides/development_validation_quickstart.md)

The command registry is an explicit allowlist. It is not an `eval` console,
remote administration surface, or arbitrary method/property executor.

## Multiplayer

Nucleus separates transport bootstrap from gameplay authority:

```text
NetworkHandler
    peer lifecycle / ENet / WebSocket

Godot MultiplayerAPI
    RPC / MultiplayerSpawner / MultiplayerSynchronizer

Nucleus replication helpers
    client intent admission / rate limits / transform interpolation

Game server
    authentication / semantic validation / authoritative gameplay
```

Recommended reading order:

1. [Networking quickstart](docs/guides/networking_quickstart.md)
2. [Networking tutorial](docs/guides/tutorials/networking.md)
3. [Online replication](docs/guides/online_replication_quickstart.md)
4. [Multiplayer deployment](docs/guides/multiplayer_deployment_quickstart.md)

## Secure extensible content

Trusted executable content and untrusted community data use different paths.
Official packs are verified before mounting; community mods remain data-only and
are never passed through Godot's executable resource-pack loading path.

See [Content Packs](docs/modules/content_packs.md).

## Validation

Fast repository checks:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py
```

Godot validation:

```bash
godot --headless --path . --import
godot --headless --path . --check-only --script res://tests/headless/test_runner.gd
godot --headless --path . --script res://tests/headless/test_runner.gd
godot --headless --path . res://tests/smoke/smoke_main.tscn
```

CI also smoke-exports Linux, Windows, and Web.

## Compatibility and public API

- [Godot compatibility](docs/policies/godot_compatibility.md)
- [API stability](docs/policies/api_stability.md)
- [Versioning](docs/policies/versioning.md)
- [Deprecation](docs/policies/deprecation.md)

Pin the Nucleus version or source commit used by a consuming game. Before 1.0,
public APIs can still change intentionally between minor versions.

## Contributing

Read [`AGENTS.md`](AGENTS.md) before modifying reusable contracts. The core rules
are Godot-native first, explicit ownership, scene ownership by default,
composition over inheritance, and no hidden dependencies between optional
modules.

## License

Nucleus is available under the [MIT License](LICENSE). A game built from the
template may use its own license while retaining the required notice for reused
Nucleus code.
