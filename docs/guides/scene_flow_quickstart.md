# Scene Flow Quickstart

Use `NucleusSceneFlow` when scene replacement needs a shared loading/transition
contract.

For a loading-screen example, see:

[`tutorials/scene_flow.md`](tutorials/scene_flow.md)

## 1. Request a transition

```gdscript
const WORLD_SCENE := "res://game/world.tscn"


func start_game() -> void:
    if NucleusSceneFlow.is_busy():
        return

    var error: Error = NucleusSceneFlow.change_scene(WORLD_SCENE)

    if error != OK:
        push_error(error_string(error))
```

## 2. Observe progress instead of owning loading yourself

The service emits:

```text
transition_started
load_progress
transition_completed
transition_failed
busy_changed
```

A scene-owned loading overlay can present those signals.

`NucleusSceneFlow` intentionally owns no visual transition.

## 3. Background loading

`change_scene()` can request background loading.

When the platform supports threads, Nucleus uses Godot's threaded resource
loading path. On threadless platforms it falls back to synchronous loading.

Game code should not need separate scene-transition implementations for those
platforms.

## 4. Avoid duplicate requests

Before accepting another menu button/portal request:

```gdscript
if NucleusSceneFlow.is_busy():
    return
```

`ERR_BUSY` is a valid response when a transition is already active.

## 5. Reload the current scene

```gdscript
NucleusSceneFlow.reload_current_scene()
```

Autoload services remain alive while the current scene is replaced.

## 6. Already-loaded scenes

For a `PackedScene` you already own:

```gdscript
NucleusSceneFlow.change_scene_to_packed(scene)
```

## When native SceneTree is enough

For a trivial, isolated change with no shared transition/loading policy, native
Godot `SceneTree` APIs remain valid.

Use Nucleus when the game benefits from one observable transition contract.

## Common mistakes

- putting loading UI inside the global service;
- making gameplay scenes persistent only to survive transitions;
- accepting multiple transition requests while the service is busy;
- storing game state inside the scene-flow service;
- using an EventBus just to forward signals that already have a natural owner.

## Related documentation

- [`tutorials/scene_flow.md`](tutorials/scene_flow.md)
- [`runtime_services_quickstart.md`](runtime_services_quickstart.md)
- [`../components/audio_save_scene_localization.md`](../components/audio_save_scene_localization.md)
