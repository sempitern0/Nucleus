# Nucleus Documentation

Nucleus documentation is organized by **task first** and **technical ownership
second**. Start with a quickstart; use a tutorial when you want a complete example;
open the component/module contract when you need API guarantees, limits or extension
rules.

## Start here

| Goal | Read |
| --- | --- |
| **Find a feature by game behavior** | **[`guides/use_case_catalog.md`](guides/use_case_catalog.md)** — 68 use cases / casos de uso |
| **Have an AI generate a mechanic safely** | **[`guides/ai_composition_workflow.md`](guides/ai_composition_workflow.md)** |
| **See multi-system composition examples** | **[`guides/composition_recipes.md`](guides/composition_recipes.md)** |
| Decide between native Godot, Nucleus and game code | [`architecture/component_selection.md`](architecture/component_selection.md) |
| Create a game from Nucleus | [`guides/installation.md`](guides/installation.md) |
| Understand the baseline architecture | [`guides/foundation_quickstart.md`](guides/foundation_quickstart.md) |
| Learn by building | [`guides/tutorials/README.md`](guides/tutorials/README.md) |
| Match a game problem to a subsystem | [`guides/real_game_patterns.md`](guides/real_game_patterns.md) |
| Configure project/rendering defaults | [`guides/project_configuration.md`](guides/project_configuration.md) |
| Validate locally and in CI | [`guides/validation_ci_quickstart.md`](guides/validation_ci_quickstart.md) |
| Diagnose integration problems | [`guides/troubleshooting.md`](guides/troubleshooting.md) |

Use the catalog first when the question is **what behavior should exist?** Use
technical contracts first when the question is **how does an identified API
behave?** The registry [`use_case_registry.json`](use_case_registry.json) exposes
the same discovery routes for machine-assisted tools. It does not execute code.

## Core and player-facing systems

| Goal | Read |
| --- | --- |
| Settings, input, rebinding and device hot-swap | [`guides/settings_input_quickstart.md`](guides/settings_input_quickstart.md) |
| UI, focus, accessibility and presentation | [`guides/ui_quickstart.md`](guides/ui_quickstart.md) |
| Audio, save and localization | [`guides/runtime_services_quickstart.md`](guides/runtime_services_quickstart.md) |
| Save directories, formats, security, backups and migrations | [`components/save_system.md`](components/save_system.md) |
| Continue/resume newest save | [`components/save_resume.md`](components/save_resume.md) |
| Scene transitions and recovery | [`guides/scene_flow_quickstart.md`](guides/scene_flow_quickstart.md) |
| Resource batches / loading presentation | [`guides/resource_loading_quickstart.md`](guides/resource_loading_quickstart.md) |
| Gameplay foundation | [`guides/gameplay_foundation_quickstart.md`](guides/gameplay_foundation_quickstart.md) |
| Safe spawn / teleport / exit placement | [`components/safe_placement_queries.md`](components/safe_placement_queries.md) |
| Actions, attributes and status effects | [`guides/actions_attributes_status_quickstart.md`](guides/actions_attributes_status_quickstart.md) |
| Pooling and targeting | [`guides/pooling_targeting_quickstart.md`](guides/pooling_targeting_quickstart.md) |
| Humanoid ragdoll authoring | [`guides/ragdoll_authoring_quickstart.md`](guides/ragdoll_authoring_quickstart.md) |

## Performance and runtime efficiency

Use these in order:

1. [`guides/performance_quickstart.md`](guides/performance_quickstart.md) — measure and establish budgets.
2. [`guides/tutorials/performance_profiling.md`](guides/tutorials/performance_profiling.md) — reproduce and diagnose a real workload.
3. [`guides/runtime_optimization_quickstart.md`](guides/runtime_optimization_quickstart.md) — choose a bounded runtime intervention.
4. [`guides/tutorials/runtime_optimization.md`](guides/tutorials/runtime_optimization.md) — compose scheduler, gates, prewarm, audits and warmup.
5. [`components/runtime_optimization.md`](components/runtime_optimization.md) — canonical public contract.

Terrain/world streaming have their own performance rules; the runtime optimization
contract above covers general systems outside those domains.

## Accessibility

Accessibility is split deliberately:

- [`components/ui_and_accessibility.md`](components/ui_and_accessibility.md) — UI behavior, focus, motion and presentation boundaries.
- [`components/accessibility_preferences.md`](components/accessibility_preferences.md) — persisted UI scale/contrast intent, sensitivity, deadzones and hold/toggle behavior.
- [`guides/settings_input_quickstart.md`](guides/settings_input_quickstart.md) — source-aware input and controller hot-swap.

## Optional modules

| Module | Contract |
| --- | --- |
| Performance | [`modules/performance.md`](modules/performance.md) |
| Development tools | [`modules/development_tools.md`](modules/development_tools.md) |
| EventBus | [`modules/event_bus.md`](modules/event_bus.md) |
| Networking | [`modules/networking.md`](modules/networking.md) |
| Online replication | [`modules/online_replication.md`](modules/online_replication.md) |
| Inventory / equipment | [`modules/inventory_equipment.md`](modules/inventory_equipment.md) |
| Probability / loot | [`modules/probability_loot.md`](modules/probability_loot.md) |
| Persistent world state | [`modules/persistent_world_state.md`](modules/persistent_world_state.md) |
| AI / navigation | [`modules/ai_navigation.md`](modules/ai_navigation.md) |
| Platform services | [`modules/platform_services.md`](modules/platform_services.md) |
| Content packs | [`modules/content_packs.md`](modules/content_packs.md) |
| Mobile | [`modules/mobile.md`](modules/mobile.md) |
| Terrain | [`modules/terrain_generation.md`](modules/terrain_generation.md) |

## World and presentation contracts

Useful focused contracts include:

```text
components/world_time_environment.md
components/celestial_environment.md
components/rendering_quality.md
components/lighting_shadows_3d.md
components/world_scheduling_and_batched_fx.md
components/world_surfaces.md
components/world_buoyancy.md
components/world_feedback.md
components/world_decals.md
components/world_fields.md
components/gameplay_movement_camera.md
components/safe_placement_queries.md
components/animation_integration.md
components/ragdoll_authoring_3d.md
components/camera_game_feel.md
components/ui_runtime_bindings.md
components/ui_world_anchors.md
components/validated_action_history.md
components/spatial_rect_index_2d.md
modules/packed_scene_preflight.md
```

Quickstarts:

```text
guides/celestial_environment_quickstart.md
guides/rendering_quality_quickstart.md
guides/lighting_shadows_quickstart.md
guides/ragdoll_authoring_quickstart.md
```

## Documentation layers

```text
guides/use_case_catalog.md
    find reusable tools by player/developer intent

guides/ai_composition_workflow.md and composition_recipes.md
    compose native Godot, Nucleus and game-owned mechanics

guides/*_quickstart.md
    minimum setup + ownership

guides/tutorials/
    concrete build-along examples

components/ and modules/
    public behavior, limits, persistence/network/performance boundaries

architecture/
    dependency direction and design rationale

policies/
    compatibility, stability, versioning and deprecation
```

Technical contracts describe the current product. Migration history and iteration
journals belong in Git history, releases and pull requests rather than current-use
documentation.

## Machine-checkable coverage

`documentation_coverage.json` maps every top-level subsystem directory to one or
more technical documents. `use_case_registry.json` maps common developer needs
to existing contracts; `scripts/ci/use_case_audit.py` validates these references.
Edit the JSON registry and run `scripts/ci/build_use_case_catalog.py` to regenerate
the human-readable catalog; CI rejects out-of-sync copies.

Run:

```bash
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/use_case_audit.py
python3 scripts/ci/build_use_case_catalog.py --check
python3 scripts/ci/productization_audit.py
```
