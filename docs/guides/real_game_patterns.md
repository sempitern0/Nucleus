# Real-game application patterns

This guide answers a practical question:

> "I know the kind of game behavior I need. Which Nucleus area should I start
> with?"

The named games below are **design analogies**, not claims about their internal
source code, engine, or architecture. They provide a recognizable product shape
for a Nucleus capability.

For implementation details, follow the linked technical contract after choosing
the area.

## Component and service map

| Nucleus area | Use it when your game needs | Game-shaped analogy | Start with |
| --- | --- | --- | --- |
| Core runtime | lifecycle, platform paths, diagnostics, window/app behavior | a polished PC/console game that boots, exits, logs, and handles platform differences consistently | [`core_runtime.md`](../components/core_runtime.md) |
| Settings + Input | options, rebinding, prompts, controller hot-swap, local seats | the "touch controller and keep playing" feel expected in games such as Rocket League or Celeste | [`settings_and_input.md`](../components/settings_and_input.md) |
| Audio / Save / Scene / Localization | persistent progress, audio buses, scene changes, locales | an RPG or survival game with save slots, language selection, and reliable world/menu transitions | [`audio_save_scene_localization.md`](../components/audio_save_scene_localization.md) |
| Gameplay foundation | health/resources, damage, interaction, cooldowns, simple state | a Hades-like combatant with health, hit reactions, interactions, timers, and stateful abilities | [`gameplay_foundation.md`](../components/gameplay_foundation.md) |
| Actions / Attributes / Status | reusable abilities, stats, modifiers, buffs/debuffs | Diablo/Hades-style temporary buffs, equipment modifiers, poison, stun, haste, or damage bonuses | [`gameplay_actions_attributes_status.md`](../components/gameplay_actions_attributes_status.md) |
| Movement + Camera | 2D/3D character movement, camera-relative motion, camera rigs | third-person adventure movement, top-down action movement, or an orbital survival-game camera | [`gameplay_movement_camera.md`](../components/gameplay_movement_camera.md) |
| Pooling + Targeting | repeated projectiles/enemies, sensing, target selection | Vampire Survivors-scale repeated spawns or Zelda-like target selection | [`gameplay_pooling_targeting.md`](../components/gameplay_pooling_targeting.md) |
| World time + Environment | simulation time, day periods, native daylight presentation | survival/farming/adventure worlds where gameplay and presentation share one scene-owned clock | [`world_time_environment.md`](../components/world_time_environment.md) |
| World surfaces | footsteps, impacts or gameplay need semantic material identity | shooters/survival games where wood, metal, sand or water produce different local responses | [`world_surfaces.md`](../components/world_surfaces.md) |
| World decals | bullet marks, scorch marks, footprints, contextual surface marks | impact decals in a shooter or temporary combat marks on environment geometry | [`world_decals.md`](../components/world_decals.md) |
| UI + Accessibility | controller focus, modal flow, toasts, layout, reduced motion | console-friendly menus with clear focus, connection notices, and accessibility-aware UI motion | [`ui_and_accessibility.md`](../components/ui_and_accessibility.md) |
| Animation integration | gameplay state needs to drive AnimationTree cleanly | a character whose locomotion, attacks, hit states, and abilities feed an animation graph | [`animation_integration.md`](../components/animation_integration.md) |
| Camera + Game Feel | shake, impulses, recoil, impact feedback, motion policy | punchy action feedback such as hit shake, weapon recoil, or damage camera response | [`camera_game_feel.md`](../components/camera_game_feel.md) |

## Optional module map

| Module | Use it when your game needs | Game-shaped analogy | Start with |
| --- | --- | --- | --- |
| EventBus | rare cross-feature notifications without direct ownership | an achievement/tutorial layer hearing that a boss died without the boss knowing about either system | [`event_bus.md`](../modules/event_bus.md) |
| Networking | transport/session helpers and LAN-facing connectivity | a small co-op title that needs host/join/session plumbing before gameplay replication | [`networking.md`](../modules/networking.md) |
| Inventory / Equipment | stacks, slots, weight/capacity, equippable modifiers | Diablo-like item storage and equipment affecting character attributes | [`inventory_equipment.md`](../modules/inventory_equipment.md) |
| Probability / Loot | deterministic weighted/chance tables and unique drops | Diablo/Borderlands-shaped enemy or chest reward generation | [`probability_loot.md`](../modules/probability_loot.md) |
| Persistent World State | doors, chests, pickups, entities surviving scene reloads | a metroidvania/adventure world where opened chests and defeated unique entities stay changed | [`persistent_world_state.md`](../modules/persistent_world_state.md) |
| AI / Navigation | utility scoring, patrol/wander, chase and path following | action/stealth enemies choosing patrol, investigate, chase, or attack behavior | [`ai_navigation.md`](../modules/ai_navigation.md) |
| Online Replication | authoritative intent admission and transform snapshots | a Valheim-shaped host-authoritative co-op world where clients request actions and receive replicated state | [`online_replication.md`](../modules/online_replication.md) |
| Platform Services | identity, capabilities, achievements/storefront adapters | a Steam/Epic/console build needing provider-neutral identity and platform features | [`platform_services.md`](../modules/platform_services.md) |

## Recipe: a controller should "just work"

For a one-player game, the game should not care whether movement currently comes
from WASD or the left stick.

A typical scene composition is:

```text
Session
├── LocalInput              NucleusLocalInputSession
└── Player                  CharacterBody3D
    └── MotionInput         NucleusMotionInput
```

Configure:

```text
LocalInput.max_players = 1
LocalInput.single_player_hot_swap = true
```

Create one stable player seat and bind it once. Nucleus can then move that seat
between keyboard/mouse and the active gamepad.

Use the scene-owned input-device toast layer if the game should visibly announce
controller connect/disconnect events.

## Recipe: B/Circle is both "back" and a gameplay action

This is normal.

```text
Main menu
    B / Circle → ui_cancel → close submenu / go back

Gameplay
    B / Circle → dodge / melee / project action

Pause menu
    B / Circle → ui_cancel → close pause menu
```

Do not make the gameplay world interpret `ui_cancel` as "return to main menu".

Use a gameplay action such as `pause` to open the pause layer:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(NucleusInputActions.PAUSE):
		open_pause_menu()
```

The active menu can then use native Godot UI navigation.

This separation is enough for ordinary games and avoids adding a second input
framework before a real project proves it necessary.

## Recipe: survival-game player foundation

A survival character often starts with composition similar to:

```text
Player
├── MotionInput
├── CharacterMotor3D
├── Health / Stamina value pools
├── Interaction component
├── Attributes
└── Status-effect receiver
```

The game owns survival-specific rules such as hunger, thirst, swimming,
temperature, encumbrance, or boat control. Nucleus supplies the reusable
building blocks, not the final survival design.

This is the same boundary a project such as Nautica should use: generic movement
and input in Nucleus; ocean movement, raft rules, and survival balance in the
game.

## Recipe: one collision drives several surface responses

Keep classification separate from presentation/gameplay response:

```text
RayCast3D / KinematicCollision3D
        ↓
SurfaceResolver3D
        ↓
SurfaceProfile = metal
        ↓
project-owned consumers
   ├── footstep audio
   ├── impact particles
   ├── SmartDecal selection
   └── game-specific interaction rules
```

The surface profile contains semantic identity, not every possible response
asset. This lets audio, decals and gameplay evolve independently while sharing
the same collision classification.

Use shape-owned providers when one physics body contains different materials,
and collider/ancestor providers for coherent fallbacks.

## Recipe: ARPG-style combatant

For a combatant with temporary buffs and debuffs:

```text
damage/hitbox
→ value pool
→ status effect
→ attribute modifier
→ presentation/animation feedback
```

Use Nucleus components for the reusable state transitions. Keep skill trees,
specific attacks, damage formulas, animation content, and balance data in the
game.

The result can support a Hades/Diablo-shaped product without turning Nucleus into
a genre-specific combat framework.

## Recipe: loot feeds inventory

When a chest/enemy reward becomes a real item:

```text
Probability / Loot
    produces result data
        ↓
Inventory
    accepts runtime stacks
        ↓
Equipment
    applies attribute modifiers
```

Keep the roll and the storage separate. This makes deterministic loot testing
possible without requiring an inventory UI and lets inventory behavior remain
useful for games with no random loot at all.

## Recipe: persistent interactable world

For a unique chest, door, pickup, switch, or destroyed object:

```text
stable world identity
→ persistent state adapter
→ SaveSession
→ scene reload reconciliation
```

Do not persist arbitrary node paths as identity. Use the Persistent World State
contract when the same logical world entity must survive scene unload/reload.

## Recipe: AI chooses, navigation moves

Keep decision and locomotion separate:

```text
Utility AI / state
    chooses "patrol", "investigate", "chase", "attack"
        ↓
Navigation follower
    moves toward the selected target
        ↓
Gameplay action
    performs the attack
```

This makes it possible to replace the decision model without rewriting native
Godot navigation and to reuse the same movement behavior across multiple enemy
archetypes.

## Recipe: online gameplay stays authoritative

For a networked action:

```text
client input
→ intent request
→ server admission/validation
→ authoritative gameplay mutation
→ replicated state/snapshot
→ client presentation
```

Nucleus online helpers support that shape without hiding Godot's native
multiplayer primitives.

Do not start by synchronizing every property. First decide who owns the action
and which state actually needs replication.

## Recipe: platform features remain replaceable

Gameplay should ask a provider-neutral boundary for platform capabilities rather
than importing a storefront SDK throughout the project.

For example:

```text
game achievement event
→ platform-services boundary
→ active Steam/Epic/console/standalone provider
```

The standalone provider keeps normal development and tests usable when no store
SDK is present.

## What Nucleus should not decide for you

Nucleus intentionally stops before project-specific product policy.

Examples that remain game-owned:

- whether `B/Circle` means dodge, melee, crouch, or interact;
- whether a camera is first-person, over-the-shoulder, orbital, or top-down;
- hunger/thirst/crafting rules in a survival game;
- exact loot probabilities and item rarity design;
- enemy tactics and encounter pacing;
- whether the game is peer-hosted, dedicated-server, or single-player;
- art, audio content, UI visual language, progression, and balance.

If a game-specific policy keeps appearing in unrelated projects, that repeated
evidence is a reason to revisit the Nucleus boundary.
