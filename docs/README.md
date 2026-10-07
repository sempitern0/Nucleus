# Nucleus Documentation

Nucleus documentation is organized by task and ownership. Start from the
smallest document that answers the current problem, then move to the technical
contract when you need lifetime, extension points, or limitations.

## Find what you need

| Goal | Read |
| --- | --- |
| Start a new project | `guides/installation.md` |
| Understand the baseline | `guides/foundation_quickstart.md` |
| Learn by building | `guides/tutorials/README.md` |
| Match a game problem to a subsystem | `guides/real_game_patterns.md` |
| Configure project/rendering defaults | `guides/project_configuration.md` |
| Configure settings, input, and rebinding | `guides/settings_input_quickstart.md` |
| Use audio, save, and localization | `guides/runtime_services_quickstart.md` |
| Build scene transitions and recovery | `guides/scene_flow_quickstart.md` |
| Build common gameplay composition | `guides/gameplay_foundation_quickstart.md` |
| Use actions, attributes, status effects | `guides/actions_attributes_status_quickstart.md` |
| Build movement/camera | `components/gameplay_movement_camera.md` |
| Add world time/daylight/localized FX | `components/world_time_environment.md` |
| Classify collision surfaces | `components/world_surfaces.md` |
| Add bounded world-space visual history | `components/world_feedback.md` |
| Replace prototype geometry with an animated 3D rig | `guides/tutorials/character_animation_3d.md` |
| Wire AnimationTree/Nucleus adapters | `guides/animation_integration_quickstart.md` |
| Generate procedural 3D terrain / islands | `guides/terrain_generation_quickstart.md` |
| Add pooling and targeting | `guides/pooling_targeting_quickstart.md` |
| Add camera feedback/game feel | `guides/camera_game_feel_quickstart.md` |
| Add inventory/equipment | `guides/inventory_equipment_quickstart.md` |
| Add deterministic loot | `guides/loot_quickstart.md` |
| Persist world state | `guides/persistent_world_quickstart.md` |
| Add Utility AI/navigation | `guides/ai_navigation_quickstart.md` |
| Profile performance | `guides/performance_quickstart.md` |
| Use Development Tools | `guides/development_tools_quickstart.md` |
| Create custom development commands | `guides/custom_development_commands_tutorial.md` |
| Inspect/move runtime scene objects | `guides/scene_object_console_quickstart.md` |
| Validate scenes/resources | `guides/development_validation_quickstart.md` |
| Host/join multiplayer | `guides/networking_quickstart.md` |
| Build authoritative replication | `guides/online_replication_quickstart.md` |
| Deploy a dedicated game server | `guides/multiplayer_deployment_quickstart.md` |
| Integrate platform/store providers | `guides/platform_services_quickstart.md` |
| Add signed DLC / safe data mods | `guides/content_packs_quickstart.md` |
| Add touch/mobile support | `guides/mobile_quickstart.md` |
| Diagnose integration problems | `guides/troubleshooting.md` |
| Run validation and CI | `guides/validation_ci_quickstart.md` |
| Package Nucleus | `guides/releasing.md` |

## Documentation layers

```text
guides/*_quickstart.md
    fast ownership and setup

guides/tutorials/
    concrete scenes, Inspector setup, and minimal code

components/ and modules/
    public technical contracts and limitations

architecture/
    dependency direction and design rationale

policies/
    compatibility, stability, versioning, and deprecation rules
```

Tutorials are practical entry points. Technical contracts remain the source of
truth for public behavior.

## Technical contracts

Baseline component groups:

- `components/core_runtime.md`
- `components/settings_and_input.md`
- `components/audio_save_scene_localization.md`
- `components/gameplay_foundation.md`
- `components/gameplay_actions_attributes_status.md`
- `components/gameplay_movement_camera.md`
- `components/gameplay_pooling_targeting.md`
- `components/world_time_environment.md`
- `components/world_surfaces.md`
- `components/world_feedback.md`
- `components/world_decals.md`
- `components/ui_and_accessibility.md`
- `components/animation_integration.md`
- `components/camera_game_feel.md`

Optional modules:

- `modules/development_tools.md`
- `modules/event_bus.md`
- `modules/networking.md`
- `modules/online_replication.md`
- `modules/performance.md`
- `modules/terrain_generation.md`
- `modules/inventory_equipment.md`
- `modules/probability_loot.md`
- `modules/persistent_world_state.md`
- `modules/ai_navigation.md`
- `modules/platform_services.md`
- `modules/content_packs.md`
- `modules/mobile.md`

No optional module is loaded by default in `project.godot`.

## Product policies

- `policies/versioning.md`
- `policies/godot_compatibility.md`
- `policies/api_stability.md`
- `policies/deprecation.md`

These define promises made by the template rather than implementation details.

## Machine-checkable coverage

`documentation_coverage.json` maps subsystem directories to technical docs.

Run:

```bash
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py
```

Documentation in the repository is intended to help users integrate, operate,
extend, validate, or maintain Nucleus. Historical iteration logs and planning
roadmaps are intentionally kept outside the source tree.
