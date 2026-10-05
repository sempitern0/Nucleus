# Tutorial: save and restore scene-owned game state

This tutorial builds a `NucleusSaveSession` with explicit participants.

The example stores player coins and the current checkpoint without making the
global save service understand a Player script.

## 1. Create a persistent session scene

```text
GameSession : Node
├── SaveSession : NucleusSaveSession
├── Player
└── World
```

The `SaveSession` is scene-owned. `NucleusSave` remains the global storage
service.

Set:

```text
SaveSession.slot_id = slot_1
```

## 2. Give the Player explicit capture/restore methods

Example game-owned Player script:

```gdscript
extends CharacterBody3D

var coins: int = 0
var checkpoint_id: StringName = &"beach"


func capture_state() -> Dictionary:
    return {
        "coins": coins,
        "checkpoint_id": String(checkpoint_id),
        "position": [
            global_position.x,
            global_position.y,
            global_position.z,
        ],
    }


func restore_state(data: Dictionary) -> void:
    coins = int(data.get("coins", 0))
    checkpoint_id = StringName(
        data.get("checkpoint_id", "beach")
    )

    var p: Array = data.get("position", [])

    if p.size() == 3:
        global_position = Vector3(
            float(p[0]),
            float(p[1]),
            float(p[2]),
        )
```

The point is not this exact schema. The point is that the Player owns knowledge
of its state shape.

## 3. Register the participant

On `GameSession`:

```gdscript
@onready var save_session: NucleusSaveSession = %SaveSession
@onready var player = %Player


func _ready() -> void:
    var error: Error = save_session.register_participant(
        &"player",
        player.capture_state,
        player.restore_state,
    )

    if error != OK:
        push_error(error_string(error))
```

The saved payload now gets a stable top-level participant key:

```text
player
```

## 4. Save manually

```gdscript
func save_game() -> void:
    var result: NucleusSaveResult = save_session.save_manual()

    if not result.succeeded():
        push_error("Save failed: %s" % error_string(result.error))
```

`SaveSession` calls every participant's capture function, builds one snapshot,
and passes it to `NucleusSave`.

## 5. Load and restore

```gdscript
func load_game() -> void:
    var result: NucleusSaveResult = save_session.load_manual()

    if not result.succeeded():
        push_error("Load failed: %s" % error_string(result.error))
```

On success, `SaveSession` routes each participant's saved data to its restore
callable.

## 6. Add metadata for a slot-selection screen

```gdscript
func _ready() -> void:
    save_session.set_metadata_provider(_capture_save_metadata)


func _capture_save_metadata() -> Dictionary:
    return {
        "area": String(player.checkpoint_id),
        "coins": player.coins,
    }
```

Metadata can help render a save-slot card, but it is not a substitute for the
actual restore payload.

## 7. Add autosave policy

Create a `NucleusAutosavePolicy` Resource and assign it to `SaveSession`.

Example starting values:

```text
enabled = true
interval_seconds = 120
max_slots = 3
save_on_application_pause = true
save_on_application_quit = true
save_on_focus_lost = false
minimum_interval_seconds = 5
```

Call:

```gdscript
save_session.autosave(true)
```

when a game event explicitly needs an immediate autosave, such as reaching a
checkpoint.

The policy also supports automatic interval/application lifecycle saves.

## 8. Register multiple systems

A larger session might register:

```text
player
inventory
quests
world_state
run_progress
```

Each subsystem owns its own state shape.

Do not create one 2,000-line save manager that reaches into every node.

## 9. Respect dependency order

If Equipment restore expects Inventory runtime stack IDs, make sure Inventory is
registered/restored before Equipment when you control explicit manual ordering.

For persistent authored world objects, prefer the Nucleus World State module
instead of inventing NodePath-based identity inside the save tutorial.

## 10. Late scene loading

`NucleusSaveSession` stores pending loaded participant payload.

That means a participant registered after `apply_snapshot()` can still receive
its saved data when its restore callable becomes available.

This is useful when a session loads save data before a particular gameplay scene
is instantiated.

## Validation

1. collect coins and move the player;
2. save;
3. change both values;
4. load;
5. confirm coins, checkpoint and position restore;
6. restart the application and load the same slot;
7. enable autosave and confirm rotated autosave slots are produced according to
   policy.

## Related docs

- [`../save_quickstart.md`](../save_quickstart.md)
- [`../persistent_world_quickstart.md`](../persistent_world_quickstart.md)
- [`../../components/audio_save_scene_localization.md`](../../components/audio_save_scene_localization.md)
