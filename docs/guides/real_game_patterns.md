# Real-game Application Patterns

Use this guide when you know the game behavior you need but not which Nucleus
owner should provide the reusable primitive.

## Capability map

| Need | Nucleus owner | Start with |
| --- | --- | --- |
| lifecycle, paths, diagnostics | Core runtime | [`../components/core_runtime.md`](../components/core_runtime.md) |
| options, rebinding, hot-swap | Settings + Input | [`settings_input_quickstart.md`](settings_input_quickstart.md) |
| save, audio, locale, scene changes | Runtime services | [`runtime_services_quickstart.md`](runtime_services_quickstart.md) |
| health/resources/damage/state | Gameplay foundation | [`gameplay_foundation_quickstart.md`](gameplay_foundation_quickstart.md) |
| abilities/stats/buffs | Actions / attributes / status | [`actions_attributes_status_quickstart.md`](actions_attributes_status_quickstart.md) |
| character motion/camera | Movement + Camera | [`../components/gameplay_movement_camera.md`](../components/gameplay_movement_camera.md) |
| repeated spawns / target selection | Pooling + Targeting | [`pooling_targeting_quickstart.md`](pooling_targeting_quickstart.md) |
| focus/UI/accessibility | UI | [`ui_quickstart.md`](ui_quickstart.md) |
| performance evidence | Performance | [`performance_quickstart.md`](performance_quickstart.md) |
| frame-spike mitigation | Runtime optimization | [`runtime_optimization_quickstart.md`](runtime_optimization_quickstart.md) |
| AI choices/path following | AI / Navigation | [`ai_navigation_quickstart.md`](ai_navigation_quickstart.md) |
| inventory/equipment | Inventory | [`inventory_equipment_quickstart.md`](inventory_equipment_quickstart.md) |
| deterministic rewards | Loot | [`loot_quickstart.md`](loot_quickstart.md) |
| durable doors/chests/entities | World State | [`persistent_world_quickstart.md`](persistent_world_quickstart.md) |
| transport / LAN session | Networking | [`networking_quickstart.md`](networking_quickstart.md) |

## Pattern: controller should just work

For one player, keep one stable `NucleusLocalPlayerInput` and let
`NucleusLocalInputSession` hot-swap its source. UI prompts follow active source;
gameplay does not cache physical device IDs.

For local multiplayer, stop using global active-device state as ownership and
assign devices to seats explicitly.

## Pattern: UI cancel and gameplay action share a button

This is normal. The active consumer supplies context:

```text
menu       B/Circle → ui_cancel
world      B/Circle → dodge / melee / project action
pause UI   B/Circle → ui_cancel
```

Use a gameplay action such as `pause` to open UI; do not let the world interpret
`ui_cancel` as a global exit command.

## Pattern: survival/action player

Compose generic state locally:

```text
Player
├── MotionInput
├── motor / camera
├── Health / Stamina
├── Interaction
├── Attributes
└── Status effects
```

Keep hunger, temperature, vehicle handling, swimming rules, crafting balance and
other product mechanics game-owned.

## Pattern: one collision, several responses

```text
Godot collision
→ NucleusSurfaceResolver3D
→ SurfaceProfile
→ game-owned audio / VFX / decal / gameplay mapping
```

Classification is reusable; content selection remains game policy.

## Pattern: performance spike

```text
repeatable workload
→ PerformanceSampler / native profiler
→ identify pressure
→ scheduler / gate / prewarm / audit / warmup as appropriate
→ repeat identical workload
→ compare report
```

Do not introduce an optimizer that silently changes quality or simulation rules.
