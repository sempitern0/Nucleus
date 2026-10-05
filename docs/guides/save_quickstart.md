# Save Quickstart

Nucleus separates storage/format policy from game-owned state capture.

For a complete participant-based example, see:

[`tutorials/save_system.md`](tutorials/save_system.md)

## Choose the right entry point

Use `NucleusSave` directly when the payload is already available as plain data.

Use `NucleusSaveSession` when several scene/game systems each own part of the
state and should capture/restore themselves.

## Direct save

```gdscript
var result: NucleusSaveResult = NucleusSave.save_manual(
    "slot_1",
    {
        "coins": 25,
        "checkpoint": "harbor",
    },
)

if not result.succeeded():
    push_error(error_string(result.error))
```

Load:

```gdscript
var result: NucleusSaveResult = NucleusSave.load_manual("slot_1")

if result.succeeded():
    var payload: Dictionary = result.document.payload
```

## Scene-owned SaveSession

Typical structure:

```text
GameSession
├── SaveSession : NucleusSaveSession
├── Player
└── World
```

Register explicit participants:

```gdscript
save_session.register_participant(
    &"player",
    player.capture_state,
    player.restore_state,
)
```

The global save service never scans the SceneTree to discover gameplay state.

## Capture plain, stable data

Good save payloads contain stable values such as:

```text
bool
numbers
strings
arrays
dictionaries
stable IDs
explicit state snapshots
```

Do not save:

```text
live Node references
Callable objects
transient instance IDs
scene-tree addresses used as identity
translated display strings
```

## Manual, quick and autosave

`NucleusSaveSession` exposes:

```text
save_manual
save_quick
autosave
load_manual
load_quick
load_latest_autosave
```

Its optional `NucleusAutosavePolicy` controls:

```text
enabled
interval_seconds
max_slots
save_on_application_pause
save_on_application_quit
save_on_focus_lost
minimum_interval_seconds
```

## Metadata is not gameplay state

Use metadata for save-slot presentation:

```text
display name
playtime summary
chapter/area label
screenshot path
```

Keep authoritative gameplay restore data in the payload.

## Restore order

When one participant depends on another, restore the dependency first.

Examples:

```text
Inventory before Equipment
world identity before dependent quest presentation
player attributes before UI reads them
```

If a participant registers after a snapshot was loaded, `NucleusSaveSession`
keeps pending payload data and can apply that participant's restore callable when
it becomes available.

## Common mistakes

- serializing entire Nodes instead of explicit state;
- mixing user preferences/settings into save-game state;
- hiding load failures and continuing with partially invalid state;
- using localized strings as IDs;
- letting every component write its own unrelated file format;
- committing encryption/integrity credentials into reusable Resources.

## Related documentation

- [`tutorials/save_system.md`](tutorials/save_system.md)
- [`runtime_services_quickstart.md`](runtime_services_quickstart.md)
- [`persistent_world_quickstart.md`](persistent_world_quickstart.md)
- [`../components/audio_save_scene_localization.md`](../components/audio_save_scene_localization.md)
