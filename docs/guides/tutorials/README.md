# Hands-on Nucleus tutorials

Tutorials build concrete features in the Godot editor. Use them after a quickstart
when you want scene trees, Inspector wiring, and minimal game-owned code.

The recommended documentation flow is:

```text
Quickstart
    ownership and minimum setup
        ↓
Tutorial
    build one complete example
        ↓
Technical contract
    lifetime, API, limits, extension points
```

## Recommended learning path

1. [`core_services.md`](core_services.md) — default services and ownership.
2. [`bindings.md`](bindings.md) — settings/input UI and rebinding.
3. [`graphics_settings.md`](graphics_settings.md) — runtime graphics policy.
4. [`performance_profiling.md`](performance_profiling.md) — budgets and profiling.
5. [`localization.md`](localization.md) — languages and persisted choice.
6. [`audio.md`](audio.md) — cues, buses, and persistent volume.
7. [`save_system.md`](save_system.md) — scene-owned participant state.
8. [`scene_flow.md`](scene_flow.md) — observable scene transitions.
9. Choose a movement path:
   - [`platformer_2d.md`](platformer_2d.md)
   - [`third_person_3d.md`](third_person_3d.md)
10. For a 3D character, continue with
    [`character_animation_3d.md`](character_animation_3d.md).
11. For generated 3D worlds:
    - [`terrain_preview_and_presets.md`](terrain_preview_and_presets.md)
    - [`procedural_terrain_3d.md`](procedural_terrain_3d.md)
    - [`terrain_streaming_runtime.md`](terrain_streaming_runtime.md)
12. [`gameplay_actions.md`](gameplay_actions.md) — actions/costs/effects.
13. [`components_first_steps.md`](components_first_steps.md) — common components.
14. [`local_multiplayer.md`](local_multiplayer.md) — local input seats.
15. [`modules_first_steps.md`](modules_first_steps.md) — optional modules.
16. [`networking.md`](networking.md) — localhost to authoritative deployment path.
17. [`../online_replication_quickstart.md`](../online_replication_quickstart.md) —
    authoritative gameplay replication.
18. [`content_packs.md`](content_packs.md) — signed DLC and safe data mods.
19. [`mobile.md`](mobile.md) — touch, haptics, orientation, lifecycle.

## Tutorials by area

| Area | Tutorial | You build |
| --- | --- | --- |
| Core | [`core_services.md`](core_services.md) | game shell using default services |
| Settings/Input | [`bindings.md`](bindings.md) | options + prompts + rebinding |
| Graphics | [`graphics_settings.md`](graphics_settings.md) | runtime graphics policy |
| Performance | [`performance_profiling.md`](performance_profiling.md) | budgets + diagnostics |
| Localization | [`localization.md`](localization.md) | two-language menu |
| Audio | [`audio.md`](audio.md) | cues, buses, and persistent volume |
| Save | [`save_system.md`](save_system.md) | participant save/load |
| Scene Flow | [`scene_flow.md`](scene_flow.md) | loading overlay |
| 2D Movement | [`platformer_2d.md`](platformer_2d.md) | platform controller |
| 3D Movement | [`third_person_3d.md`](third_person_3d.md) | body + orbit camera |
| 3D Animation | [`character_animation_3d.md`](character_animation_3d.md) | imported rig + retargeting + IK + ragdoll |
| Terrain Preview | [`terrain_preview_and_presets.md`](terrain_preview_and_presets.md) | presets + cheap editor previews |
| Procedural Terrain | [`procedural_terrain_3d.md`](procedural_terrain_3d.md) | bounded island chain |
| Terrain Streaming | [`terrain_streaming_runtime.md`](terrain_streaming_runtime.md) | runtime moving chunk window |
| Gameplay Actions | [`gameplay_actions.md`](gameplay_actions.md) | action/cost/cooldown/effect |
| Components | [`components_first_steps.md`](components_first_steps.md) | common composition |
| Local Input | [`local_multiplayer.md`](local_multiplayer.md) | hot-swap + couch seats |
| Modules | [`modules_first_steps.md`](modules_first_steps.md) | optional module survey |
| Networking | [`networking.md`](networking.md) | host/join through dedicated server |
| Content Packs | [`content_packs.md`](content_packs.md) | signed DLC + data-only mod |
| Mobile | [`mobile.md`](mobile.md) | touch controls for existing gameplay |

## Learning paths by game type

### 3D action/survival

```text
project_configuration
→ core_services
→ bindings
→ third_person_3d
→ character_animation_3d
→ terrain_preview_and_presets when the world is generated
→ gameplay_actions
→ inventory / loot / world state as needed
→ networking when online play is actually required
```

### Online/co-op

Build the local gameplay first, then:

```text
performance_profiling
→ networking
→ online_replication_quickstart
→ multiplayer_deployment_quickstart
→ platform_services_quickstart when provider integration is needed
```

Connection transport does not decide gameplay authority.

## Tutorial contract

A tutorial should answer:

1. What are we building?
2. Which Nodes/Resources are added?
3. Which Inspector properties matter?
4. What game-owned code is required?
5. What should happen when it works?
6. What remains game-specific?
7. What are the common mistakes?
8. Which technical contract is authoritative?

Tutorials use public `Nucleus*` APIs and native Godot APIs. They do not teach
underscore-prefixed helpers as supported integration points.
