# Settings and Input Quickstart

This page defines the ownership rules.

For step-by-step options, prompt, and rebinding UI examples, follow:

[`tutorials/bindings.md`](tutorials/bindings.md)

For graphics settings and scene-owned Environment policy:

[`tutorials/graphics_settings.md`](tutorials/graphics_settings.md)

For Core usage in a small game shell:

[`tutorials/core_services.md`](tutorials/core_services.md)

## Settings

Use `NucleusSettings` as the stable settings service.

The normal flow is:

```text
SettingDefinition Resource
→ SettingsCatalog
→ NucleusSettingsService
→ setting_changed
→ applier / game consumer
→ native Godot state
```

For a new setting:

1. classify its native owner;
2. define/register it using the existing definition/catalog pattern;
3. provide a safe default;
4. add an applier only when it changes runtime engine/scene state;
5. bind UI through the existing settings binding components;
6. let Settings persistence own the stored preference;
7. add a headless contract test when the definition/catalog behavior is reusable.

Do not make UI write engine state directly when an existing applier already owns
that behavior.

### Choose the correct owner

Use this decision table before adding another global service:

| Native owner | Nucleus integration |
| --- | --- |
| application-wide runtime state | core setting + focused applier |
| root viewport preference | `NucleusDisplaySettingsApplier` |
| scene node/resource | scene-owned component/consumer |
| game design/content | consuming-game setting/system |
| startup-only project policy | `project.godot` |

Do not mirror every `ProjectSettings` key into Nucleus. Some keys are startup
policy rather than mutable player preferences.

### Built-in runtime graphics

The default catalog includes reusable root-viewport preferences for:

```text
graphics/max_fps
graphics/render_scale
graphics/scaling_3d_mode
graphics/screen_space_aa
graphics/taa_enabled
graphics/msaa_2d
graphics/msaa_3d
graphics/debanding_enabled
```

SSAO, SSIL, glow, volumetric fog, SDFGI, and tonemapping remain properties of a
scene `Environment`. Nucleus provides optional definitions and
`NucleusEnvironmentSettingsApplier`, but the consuming game decides which of
those settings to register and where to compose the applier.

### Defaults and precedence

Use this order when tailoring the framework:

```text
Nucleus definition default
→ game-owned catalog/default override
→ game-selected platform recommendation
→ persisted user preference
```

Persisted explicit user choice wins. Platform recommendations are suitable for
first-run defaults, not repeated overrides.

Nucleus does not define Low/Medium/High/Ultra values because those labels depend
on the game's content and target hardware. A game can implement them as bundles
of ordinary setting values and derive `Custom` when values no longer match a
known bundle.

See [`project_configuration.md`](project_configuration.md) before choosing
renderer, resolution, scaling, or mobile defaults.

## Input model

Nucleus builds on Godot's `Input` and `InputMap`. It does not replace them.

Keep gameplay code semantic:

```gdscript
if Input.is_action_just_pressed(NucleusInputActions.INTERACT):
    # Ask the current interaction target to perform its game-specific action.
    pass
```

Use `NucleusInput` for active-device tracking, rebinding, prompt/label concerns,
vibration, and gamepad metadata.

Use `NucleusLocalInputSession` when one or more local players need explicit
device ownership.

## UI navigation is not gameplay

Treat Godot's `ui_*` actions as navigation for the **currently active UI layer**.

```text
ui_accept
ui_cancel
ui_left / ui_right / ui_up / ui_down
    → menu, dialog and Control navigation
```

Gameplay uses semantic actions:

```text
move_*
look_*
interact
primary_action
secondary_action
pause
project-specific gameplay actions
    → world/session behavior
```

A world scene should not do this:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(NucleusInputActions.UI_CANCEL):
        return_to_main_menu()
```

That makes a UI-navigation binding globally own gameplay behavior. On a gamepad,
B/Circle may later become dodge, melee, interact, cancel-target, or another
gameplay action.

Use a gameplay action instead:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(NucleusInputActions.PAUSE):
        open_pause_menu()
```

Once the pause/menu UI is open, that UI can consume `ui_cancel` to close itself.

### The same physical button may serve two contexts

Godot may legally map the same physical button to multiple actions.

For example:

```text
B / Circle
├── ui_cancel          active while navigating menus/dialogs
└── dodge              active in gameplay
```

This is not a conflict by itself. The active consumer defines the context.

Nucleus deliberately does not introduce a full mapping-context framework until a
real consuming game proves that consumer-side context is insufficient.

## Gamepad/touch hot-swap

For a normal one-player session:

```gdscript
var local_player := local_input.join_keyboard_mouse(0)
motion_input.bind_local_player_input(local_player)
```

With `max_players = 1` and `single_player_hot_swap = true`,
`NucleusLocalInputSession` keeps that same `NucleusLocalPlayerInput` object while
keyboard/mouse, gamepad, and touch activity swap the owned source/device.

Gameplay systems retain a stable player reference and do not need to react to
USB/Bluetooth connection details or create a mobile-specific movement API.

For couch multiplayer, set `max_players > 1`; explicit seat/device assignment
remains authoritative.

## Rebinding

Use the Nucleus capture/service path so bindings remain serializable and
source-aware.

Gamepad bindings normalized by `NucleusInputBindingCodec` target any compatible
gamepad rather than persisting one transient device id.

After a binding changes, prompts derive labels from `NucleusInput` helpers
instead of caching strings such as `E`, `A`, `Cross`, or `LMB`.

The complete editor-first recipe is in:

[`tutorials/bindings.md`](tutorials/bindings.md)

### UI action rebinding

Actions beginning with `ui_` are protected by default because removing the last
usable accept/cancel route can lock a user out of menus.

A project with a deliberate UI rebinding flow may opt in:

```gdscript
NucleusInput.allow_ui_action_rebinding = true
```

If you do this, always preserve a fallback route for accept/cancel and test the
flow using keyboard and at least one gamepad family.

## Controller connection feedback

Core emits device state. Presentation stays scene-owned.

Add:

```text
NucleusInputDeviceToastLayer
```

to an appropriate UI root to show controller connected/disconnected toasts
without making `core/input` depend on the UI system.

## Local multiplayer

Create a `NucleusLocalInputSession` and per-player inputs for explicit ownership.

Do not route every player through `NucleusInput.active_gamepad_id`; that value is
appropriate for global active-device presentation, not multiplayer seat
ownership.

## Common mistakes

- using `ui_cancel` as a global gameplay back/exit action;
- hard-coding physical keys or gamepad button indices in gameplay;
- caching prompt strings instead of deriving them from current bindings;
- replacing a local-player object when only its device/source changed;
- storing input/settings preferences inside save-game state;
- routing all local players through the globally active gamepad;
- writing runtime display/audio/viewport state directly from settings UI;
- making scene-owned Environment policy global without a game requirement.

For broader examples, see
[`real_game_patterns.md`](real_game_patterns.md), the hands-on
[`tutorials/bindings.md`](tutorials/bindings.md), the graphics
[`tutorials/graphics_settings.md`](tutorials/graphics_settings.md), and the
technical [`settings_and_input.md`](../components/settings_and_input.md) contract.
