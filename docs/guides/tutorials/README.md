# Hands-on Nucleus tutorials

The quickstarts explain ownership and the minimum public surface. These tutorials
teach Nucleus by building small features that you can reproduce in the Godot
editor.

Use the documentation in three layers:

```text
Quickstart
    choose the subsystem and learn the ownership rules
        ↓
Tutorial
    build one concrete feature step by step
        ↓
Technical contract
    inspect lifetime, signals, extension points, and limitations
```

The tutorials intentionally keep native Godot nodes/APIs visible wherever
Nucleus does not own the behavior.

## Recommended learning path

If Nucleus is new to you, this sequence covers most of the baseline without
requiring you to read the architecture first:

1. [`core_services.md`](core_services.md) — understand the default Autoloads.
2. [`bindings.md`](bindings.md) — build settings/input UI through composition.
3. [`graphics_settings.md`](graphics_settings.md) — configure runtime graphics
   while preserving scene ownership.
4. [`localization.md`](localization.md) — ship two languages and persist choice.
5. [`audio.md`](audio.md) — use cues, one-shots, buses and volume bindings.
6. [`save_system.md`](save_system.md) — save scene-owned participant state.
7. [`scene_flow.md`](scene_flow.md) — build a loading overlay around SceneFlow.
8. Choose a movement path:
   - [`platformer_2d.md`](platformer_2d.md)
   - [`third_person_3d.md`](third_person_3d.md)
9. [`gameplay_actions.md`](gameplay_actions.md) — executable gameplay actions.
10. [`components_first_steps.md`](components_first_steps.md) — common components.
11. [`local_multiplayer.md`](local_multiplayer.md) — explicit local input seats.
12. [`modules_first_steps.md`](modules_first_steps.md) — optional module survey.
13. [`networking.md`](networking.md) — prove host/join transport lifecycle.
14. [`../online_replication_quickstart.md`](../online_replication_quickstart.md) —
    move from connection to authoritative gameplay replication.
15. [`content_packs.md`](content_packs.md) — signed DLC and safe community data.
16. [`mobile.md`](mobile.md) — touch, haptics, orientation, and lifecycle.

Before choosing project-wide renderer or viewport defaults, read
[`../project_configuration.md`](../project_configuration.md). When behavior is
unexpected, use [`../troubleshooting.md`](../troubleshooting.md) before bypassing
an ownership boundary.

## Tutorials by area

| Area | Tutorial | You build |
| --- | --- | --- |
| Core | [`core_services.md`](core_services.md) | tiny game shell using default services |
| Settings/Input | [`bindings.md`](bindings.md) | options + prompts + rebinding |
| Graphics | [`graphics_settings.md`](graphics_settings.md) | runtime graphics + Environment policy |
| Localization | [`localization.md`](localization.md) | English/Spanish menu + selector |
| Audio | [`audio.md`](audio.md) | reusable UI cue + persistent volume |
| Save | [`save_system.md`](save_system.md) | participant save/load/autosave |
| Scene Flow | [`scene_flow.md`](scene_flow.md) | observable loading overlay |
| 2D Movement | [`platformer_2d.md`](platformer_2d.md) | responsive platform controller |
| 3D Movement | [`third_person_3d.md`](third_person_3d.md) | body + orbit camera |
| Gameplay Actions | [`gameplay_actions.md`](gameplay_actions.md) | action/cost/cooldown/effect |
| Components | [`components_first_steps.md`](components_first_steps.md) | common components |
| Local Input | [`local_multiplayer.md`](local_multiplayer.md) | hot-swap + couch seats |
| Modules | [`modules_first_steps.md`](modules_first_steps.md) | optional module survey |
| Networking | [`networking.md`](networking.md) | ENet Host / Join / Leave lab |
| Content Packs | [`content_packs.md`](content_packs.md) | signed DLC + data-only mod |
| Mobile | [`mobile.md`](mobile.md) | touch controller for existing gameplay |

## Learning paths by game type

### 2D platform/action game

```text
project_configuration
→ core_services
→ bindings
→ graphics_settings when user-facing quality options are needed
→ localization/audio/save as needed
→ platformer_2d
→ gameplay_actions
→ mobile (when targeting touch)
```

### 3D action/survival game

```text
project_configuration
→ core_services
→ bindings
→ graphics_settings
→ localization/audio/save/scene_flow
→ third_person_3d
→ gameplay_actions
→ inventory + loot + world state as needed
→ content_packs for DLC/mod data
→ mobile for phone/tablet targets
```

### RPG/ARPG systems layer

```text
gameplay_actions
→ components_first_steps
→ inventory_equipment_quickstart
→ loot_quickstart
→ persistent_world_quickstart
→ save_system
```

### Couch multiplayer

```text
bindings
→ local_multiplayer
→ movement tutorial for each local actor
→ gameplay_actions
```

### Online/co-op game

Build the local game first, then:

```text
networking
→ online_replication_quickstart
→ platform_services_quickstart when provider integration is needed
```

Connection transport does not decide gameplay authority.

## Tutorial format

Every tutorial should answer:

1. What are we building?
2. Which Nodes/Resources do I add?
3. Which Inspector properties matter?
4. What game-owned code is required?
5. What should happen when it works?
6. What should remain game-specific?
7. What are the common mistakes?
8. Which technical contract is authoritative?

## Public API rule

Tutorials use public `Nucleus*` APIs and native Godot APIs.

Do not teach underscore-prefixed implementation helpers as supported integration
points.

Named commercial games may appear only as product/design analogies, never as
claims about their source code or architecture.
