# Nucleus Local Multiplayer Input

Local multiplayer is an optional scene-owned extension of Nucleus Input.

It is not an Autoload because player seats belong to a game/session, not to the
application process.

## Session

Add:

```text
GameSession
└── NucleusLocalInputSession
```

By default:

- Up to 4 players.
- Player 0 is reserved for keyboard + mouse.
- Unassigned gamepads join when a button is pressed.
- Each gamepad can belong to only one player.
- Disconnected gamepads reserve their player seat and can reconnect by GUID.

## Per-player polling

```gdscript
var player_input := local_input.get_player(1)

var movement := player_input.get_vector(
    NucleusInputActions.MOVE_LEFT,
    NucleusInputActions.MOVE_RIGHT,
    NucleusInputActions.MOVE_FORWARD,
    NucleusInputActions.MOVE_BACK,
)
```

Unlike `Input.is_action_pressed()`, this only reads the hardware assigned to that
player.

Gamepad polling uses:

```text
Input.is_joy_button_pressed(device_id, ...)
Input.get_joy_axis(device_id, ...)
```

Keyboard/mouse polling uses the corresponding physical-key and mouse APIs.

The same InputMap and runtime rebinding data are shared by all players; only
the physical device state is separated.

## Discrete events

Each player exposes:

```gdscript
player_input.input_received.connect(_on_player_input)
```

The session only sends that player's hardware events to that player:

```gdscript
func _on_player_input(event: InputEvent) -> void:
    if event.is_action_pressed(NucleusInputActions.INTERACT):
        interact()
```

This avoids inventing a second `just_pressed` clock separate from Godot's input
event system.

## Keyboard limitation

Godot and desktop operating systems normally expose keyboard and mouse as shared
application devices. Nucleus therefore treats keyboard + mouse as one local
player seat.

Independent local players should use separate gamepads.

## Reconnection

When a controller disconnects:

```text
seat remains
player.connected = false
device_id = -1
```

If a controller with the same GUID reconnects, Nucleus restores the seat.

For multiple identical gamepads the GUID may be the same, so the first matching
disconnected seat is reclaimed. Games that require stronger identity can build
a lobby policy above this Core service.

## Vibration

Vibration routes through the player's assigned controller:

```gdscript
player_input.start_vibration(0.25, 0.8, 0.4)
```

The global `input/vibration_enabled` preference is still respected.
