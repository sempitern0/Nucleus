# Hands-on Nucleus Tutorials

Tutorials build one concrete integration in the Godot editor. The preferred
reading order is:

```text
Quickstart → Tutorial → Technical contract
```

## Recommended learning path

1. [`core_services.md`](core_services.md) — baseline services and ownership.
2. [`bindings.md`](bindings.md) — settings, accessibility preferences, prompts and rebinding.
3. [`graphics_settings.md`](graphics_settings.md) — runtime graphics policy.
4. [`ui_polish.md`](ui_polish.md) — presentation, focus/glyph feedback and accessibility-safe motion.
5. [`performance_profiling.md`](performance_profiling.md) — measure a real workload.
6. [`runtime_optimization.md`](runtime_optimization.md) — apply bounded runtime interventions.
7. [`audio.md`](audio.md) — cues, buses and volume.
8. [`save_system.md`](save_system.md) — participant state and incremental capture.
9. [`scene_flow.md`](scene_flow.md) — observable scene transitions.
10. [`resource_loading.md`](resource_loading.md) — load plans, progress and first-use warmup.
11. Choose a movement path: [`platformer_2d.md`](platformer_2d.md) or [`third_person_3d.md`](third_person_3d.md).
12. Add [`character_animation_3d.md`](character_animation_3d.md) for imported 3D rigs.
13. Continue into gameplay actions, components and optional modules as required.

## By area

| Area | Tutorial |
| --- | --- |
| Core | [`core_services.md`](core_services.md) |
| Settings / Input | [`bindings.md`](bindings.md) |
| Graphics | [`graphics_settings.md`](graphics_settings.md) |
| UI / Accessibility | [`ui_polish.md`](ui_polish.md) |
| Performance | [`performance_profiling.md`](performance_profiling.md) |
| Runtime optimization | [`runtime_optimization.md`](runtime_optimization.md) |
| Audio | [`audio.md`](audio.md) |
| Save | [`save_system.md`](save_system.md) |
| Scene Flow | [`scene_flow.md`](scene_flow.md) |
| Resource Loading | [`resource_loading.md`](resource_loading.md) |
| 2D movement | [`platformer_2d.md`](platformer_2d.md) |
| 3D movement | [`third_person_3d.md`](third_person_3d.md) |
| 3D animation | [`character_animation_3d.md`](character_animation_3d.md) |
| Terrain preview | [`terrain_preview_and_presets.md`](terrain_preview_and_presets.md) |
| Procedural terrain | [`procedural_terrain_3d.md`](procedural_terrain_3d.md) |
| Terrain streaming | [`terrain_streaming_runtime.md`](terrain_streaming_runtime.md) |
| Gameplay actions | [`gameplay_actions.md`](gameplay_actions.md) |
| Common components | [`components_first_steps.md`](components_first_steps.md) |
| Local multiplayer | [`local_multiplayer.md`](local_multiplayer.md) |
| Networking | [`networking.md`](networking.md) |
| Content packs | [`content_packs.md`](content_packs.md) |
| Mobile | [`mobile.md`](mobile.md) |

Tutorials use public `Nucleus*` APIs and native Godot APIs. Underscore-prefixed
helpers are implementation details, not integration contracts.
