# Nucleus Documentation

Nucleus documentation is split by audience and responsibility. The objective is
to make the template usable from the Godot editor without requiring users to
understand its internals, while preserving explicit contracts for maintainers.

## Start here

| Goal | Guide |
| --- | --- |
| Start a new game from Nucleus | `guides/installation.md` |
| Learn Nucleus by building small features | `guides/tutorials/README.md` |
| Match a game problem to a Nucleus component/module | `guides/real_game_patterns.md` |
| Understand the baseline and Autoloads | `guides/foundation_quickstart.md` |
| Configure settings, input, and rebinding | `guides/settings_input_quickstart.md` |
| Use audio, save, scene flow, and localization | `guides/runtime_services_quickstart.md` |
| Compose common gameplay building blocks | `guides/gameplay_foundation_quickstart.md` |
| Use actions, attributes, and status effects | `guides/actions_attributes_status_quickstart.md` |
| Set up pooling and targeting | `guides/pooling_targeting_quickstart.md` |
| Place adaptive world decals | `guides/smart_decals_quickstart.md` |
| Capture screenshots/marketing stills | `guides/screenshot_capture_quickstart.md` |
| Build production UI and accessibility | `guides/ui_quickstart.md` |
| Wire AnimationTree | `guides/animation_integration_quickstart.md` |
| Add camera/game-feel feedback | `guides/camera_game_feel_quickstart.md` |
| Use Inventory / Equipment | `guides/inventory_equipment_quickstart.md` |
| Build deterministic loot tables | `guides/loot_quickstart.md` |
| Persist world state across scenes | `guides/persistent_world_quickstart.md` |
| Compose Utility AI and navigation | `guides/ai_navigation_quickstart.md` |
| Build authoritative gameplay replication | `guides/online_replication_quickstart.md` |
| Integrate storefront/platform providers | `guides/platform_services_quickstart.md` |
| Add signed DLC and safe community mods | `guides/content_packs_quickstart.md` |
| Add touch/mobile support | `guides/mobile_quickstart.md` |
| Opt into optional modules | `guides/optional_modules_quickstart.md` |
| Run validation and CI | `guides/validation_ci_quickstart.md` |
| Package a Nucleus release | `guides/releasing.md` |

## Learn by building

The hands-on tutorial section is for developers who want concrete scene trees,
Inspector values, and minimal code before reading the full technical contract.

Start with:

```text
guides/tutorials/core_services.md
guides/tutorials/bindings.md
guides/tutorials/localization.md
guides/tutorials/audio.md
guides/tutorials/save_system.md
guides/tutorials/scene_flow.md
guides/tutorials/platformer_2d.md
guides/tutorials/third_person_3d.md
guides/tutorials/gameplay_actions.md
guides/tutorials/local_multiplayer.md
guides/tutorials/networking.md
guides/tutorials/content_packs.md
guides/tutorials/mobile.md
```

Examples answer questions such as:

- How do I use the default Core services from a real game scene?
- How do I get the most from settings/input bindings?
- How do I create an InputMap action?
- How do I build a responsive 2D or 3D controller?
- How do I persist, localize, and route audio correctly?
- How do I host/join before designing gameplay replication?
- How do I ship a signed DLC without auto-mounting arbitrary third-party PCKs?
- How do I let community mods add data without executing their code?
- How do I reuse the same gameplay actions on touchscreen?

`real_game_patterns.md` remains the practical index when a developer knows the
gameplay/product problem but not the Nucleus subsystem. Game references in that
guide are design analogies, not claims about another game's internal
implementation.

## Documentation layers

Use the shortest layer that answers the current question:

```text
guides/*_quickstart.md
    fast ownership/setup summary

guides/tutorials/
    build concrete features step by step

docs/components/ and docs/modules/
    technical contracts and limitations

docs/architecture/
    rationale and dependency direction

docs/policies/
    compatibility and stability promises
```

Tutorials should not become a second source of truth for public contracts. When
a public API changes, update both the contract and every affected tutorial.

## Product policies

`docs/policies/` defines promises that apply across components:

- `versioning.md`
- `godot_compatibility.md`
- `api_stability.md`
- `deprecation.md`

These policies are intentionally separate from implementation documentation.
They define how Nucleus may evolve, not how one component works internally.

## Technical contracts

`docs/components/` documents ownership, lifetime, data flow, signals, extension
points, persistence boundaries, Godot-native APIs, and known limitations.

The baseline is grouped into contracts rather than one file per script:

- `core_runtime.md`
- `settings_and_input.md`
- `audio_save_scene_localization.md`
- `gameplay_foundation.md`
- `gameplay_actions_attributes_status.md`
- `gameplay_movement_camera.md`
- `gameplay_pooling_targeting.md`
- `world_decals.md`
- `ui_and_accessibility.md`
- `animation_integration.md`
- `camera_game_feel.md`

## Optional modules

`docs/modules/` contains systems that are useful but not mandatory baseline
infrastructure:

- `event_bus.md`
- `networking.md`
- `inventory_equipment.md`
- `probability_loot.md`
- `persistent_world_state.md`
- `ai_navigation.md`
- `online_replication.md`
- `platform_services.md`
- `content_packs.md`
- `mobile.md`

No optional module is loaded by default in `project.godot`.

## Architecture

Use `docs/architecture/` for dependency direction and design rationale.

Key documents include:

- `documentation_model.md`
- `baseline_architecture.md`
- `production_hardening.md`
- the Iteration 17 reuse audit

## Roadmap and handoff

Use `docs/roadmap/` for status and future direction.

`iteration_18.md` records production hardening.

`iteration_19.md` records productization and first-project readiness.

`iteration_20.md` records proven presentation reuse.

`iteration_21.md` records Inventory / Equipment.

`iteration_22.md` records Probability / Loot.

`iteration_23.md` records Persistent World State / Identity.

`iteration_24.md` records AI / Navigation.

`iteration_25.md` records the final pre-game online/platform integration
checkpoint.

`iteration_26.md` records first consuming-game feedback: seamless gamepad
behavior, UI/gameplay input boundaries, project identity, and documentation
discoverability.

`next_chat_context.md` is the portable handoff document and should always
distinguish implemented, CI-validated, and future work.

## Machine-checkable documentation coverage

`docs/documentation_coverage.json` maps every direct subsystem directory under:

```text
core/*
modules/*
components/gameplay/*
components/ui/*
```

to at least one technical document.

Run:

```bash
python3 scripts/ci/documentation_audit.py
```

Product-level files and policies are checked separately:

```bash
python3 scripts/ci/productization_audit.py
```

This keeps both implementation documentation and release contracts inside CI.
