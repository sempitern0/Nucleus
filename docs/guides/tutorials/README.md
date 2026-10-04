# Hands-on Nucleus tutorials

The quickstarts explain what each Nucleus area owns. These tutorials explain how
to build small, working game features with the public API.

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

The tutorials intentionally use native Godot nodes wherever Nucleus does not own
the behavior.

Named games are used only as product/design analogies. They are not claims about
another game's source code or internal architecture.

## Recommended first hour

Follow these in order:

1. [`core_services.md`](core_services.md) — use the default Autoload services.
2. [`bindings.md`](bindings.md) — build an options/rebinding UI without manual
   synchronization code.
3. [`gameplay_actions.md`](gameplay_actions.md) — distinguish InputMap actions
   from executable gameplay actions.
4. [`platformer_2d.md`](platformer_2d.md) — build a responsive side-view
   controller with keyboard and gamepad.

After that, use:

- [`components_first_steps.md`](components_first_steps.md) for health, damage,
  interaction, state, pooling, targeting, and UI composition;
- [`modules_first_steps.md`](modules_first_steps.md) for optional EventBus,
  networking, inventory, loot, persistent world, AI, replication, and platform
  services;
- [`../real_game_patterns.md`](../real_game_patterns.md) when you know the game
  problem but do not yet know which Nucleus subsystem fits it.

## Learning paths

### I am building a 2D action/platform game

```text
core_services
→ bindings
→ platformer_2d
→ gameplay_actions
→ components_first_steps
→ animation_integration_quickstart
→ camera_game_feel_quickstart
```

### I am building a 3D action/survival game

```text
core_services
→ bindings
→ gameplay_foundation_quickstart
→ gameplay_actions
→ real_game_patterns
→ inventory / loot / persistent world as needed
```

For movement, compose `NucleusMotionInput`,
`NucleusCharacterMotor3D`, and the appropriate camera components.

### I am building an RPG/ARPG systems layer

```text
gameplay_actions
→ components_first_steps
→ inventory_equipment_quickstart
→ loot_quickstart
→ persistent_world_quickstart
```

### I am building multiplayer

Start single-player gameplay first, then:

```text
optional_modules_quickstart
→ modules_first_steps
→ online_replication_quickstart
```

Nucleus networking does not remove the need to decide authority.

## Tutorial format

Every tutorial aims to answer the same questions:

1. What are we building?
2. Which nodes/resources do I add?
3. Which Inspector properties matter?
4. What code, if any, belongs in the game?
5. What should happen when it works?
6. What should remain game-specific?
7. What are the common mistakes?
8. Where is the technical contract?

## Public API rule

Tutorials should use public `Nucleus*` APIs and native Godot APIs.

Do not teach a private underscore-prefixed helper as a supported integration
point.

If an example needs direct access to a lower-level Godot API already owned by
Nucleus, the tutorial should explain why instead of silently bypassing the
Nucleus boundary.

## Tutorial versus production code

Tutorial values are starting points, not balance recommendations.

For example, the platformer tutorial uses coyote time, jump buffering, and
variable jump height to demonstrate the motor. A real game still owns movement
feel, animation timing, level metrics, accessibility options, and game-specific
mechanics.
