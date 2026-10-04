# Nucleus Documentation

Nucleus documentation is split by audience and by responsibility. The objective
is to make the template usable from the Godot editor without requiring users to
understand its internals, while keeping enough contract detail for maintainers.

## Start here

If you are integrating Nucleus into a game, use `docs/guides/`.

| Goal | Guide |
| --- | --- |
| Understand the baseline and Autoloads | `foundation_quickstart.md` |
| Configure settings, input, and rebinding | `settings_input_quickstart.md` |
| Use audio, save, scene flow, and localization | `runtime_services_quickstart.md` |
| Compose common gameplay building blocks | `gameplay_foundation_quickstart.md` |
| Use actions, attributes, and status effects | `actions_attributes_status_quickstart.md` |
| Set up pooling and targeting | `pooling_targeting_quickstart.md` |
| Build production UI and accessibility | `ui_quickstart.md` |
| Wire AnimationTree | `animation_integration_quickstart.md` |
| Add camera/game-feel feedback | `camera_game_feel_quickstart.md` |
| Opt into EventBus or networking | `optional_modules_quickstart.md` |
| Run validation and CI | `validation_ci_quickstart.md` |

## Technical contracts

`docs/components/` documents ownership, lifetime, data flow, signals, extension
points, persistence boundaries, Godot-native APIs, and known limitations.

The recovered baseline is grouped into contracts rather than one file per
script:

- `core_runtime.md`
- `settings_and_input.md`
- `audio_save_scene_localization.md`
- `gameplay_foundation.md`
- `gameplay_actions_attributes_status.md`
- `gameplay_movement_camera.md`
- `gameplay_pooling_targeting.md`
- `ui_and_accessibility.md`
- `animation_integration.md`
- `camera_game_feel.md`

## Optional modules

`docs/modules/` is reserved for systems that are useful but not mandatory
baseline infrastructure:

- `event_bus.md`
- `networking.md`

Neither module is an Autoload in the default `project.godot`.

## Architecture

Use `docs/architecture/` for dependency direction and design rationale.

The key documents are:

- `documentation_model.md`
- `baseline_architecture.md`
- `production_hardening.md`
- the existing Iteration 17 reuse audit

## Roadmap and handoff

Use `docs/roadmap/` for status and future direction.

`iteration_18.md` records the hardening delivery. `next_chat_context.md` remains
the portable handoff document. It should state what was implemented, what was
actually runtime-validated, and what remains pending without conflating those
states.

## Documentation coverage is machine-checkable

`docs/documentation_coverage.json` maps every direct subsystem directory under:

```text
core/*
modules/*
components/gameplay/*
components/ui/*
```

to at least one technical document. Run:

```bash
python3 scripts/ci/documentation_audit.py
```

A new top-level subsystem that is not mapped fails the audit. This makes the
documentation requirement part of production readiness instead of a cleanup
task performed after implementation.
