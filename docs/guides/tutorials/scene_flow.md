# Tutorial: add an observable loading overlay to SceneFlow

This tutorial keeps scene transition policy in `NucleusSceneFlow` and visuals in
a normal game-owned UI scene.

## 1. Create two destination scenes

For example:

```text
res://game/menu.tscn
res://game/world.tscn
```

## 2. Create a loading overlay

```text
LoadingOverlay : CanvasLayer
└── Panel
    └── VBoxContainer
        ├── Label
        └── ProgressBar
```

Attach:

```gdscript
extends CanvasLayer


func _ready() -> void:
    hide()
    NucleusSceneFlow.transition_started.connect(_on_started)
    NucleusSceneFlow.load_progress.connect(_on_progress)
    NucleusSceneFlow.transition_completed.connect(_on_completed)
    NucleusSceneFlow.transition_failed.connect(_on_failed)


func _on_started(_from: String, to: String) -> void:
    %Label.text = "Loading %s" % to.get_file()
    %ProgressBar.value = 0.0
    show()


func _on_progress(_path: String, progress: float) -> void:
    %ProgressBar.value = progress * 100.0


func _on_completed(_path: String, _scene: Node) -> void:
    hide()


func _on_failed(path: String, error: Error) -> void:
    %Label.text = "Failed to load %s: %s" % [
        path,
        error_string(error),
    ]
```

The visual layer owns presentation. SceneFlow owns transition state.

## 3. Request the transition from a menu button

```gdscript
func _on_new_game_pressed() -> void:
    if NucleusSceneFlow.is_busy():
        return

    var error: Error = NucleusSceneFlow.change_scene(
        "res://game/world.tscn"
    )

    if error != OK:
        push_error(error_string(error))
```

## 4. Disable repeated activation while busy

A menu can also bind button availability to:

```text
busy_changed
```

Example:

```gdscript
func _ready() -> void:
    NucleusSceneFlow.busy_changed.connect(_on_busy_changed)


func _on_busy_changed(busy: bool) -> void:
    %NewGame.disabled = busy
```

This prevents double-click/confirm spam from becoming multiple transition
requests.

## 5. Understand background-loading fallback

The same call can use background loading on platforms with threads.

On platforms where Nucleus reports no thread support, SceneFlow falls back to a
synchronous `ResourceLoader` path.

The UI may receive a simpler/shorter progress sequence there; game logic should
still depend on the same transition signals.

## 6. Reload the current scene

For a restart/checkpoint flow:

```gdscript
var error: Error = NucleusSceneFlow.reload_current_scene()
```

Global Autoload services survive while the current scene is recreated.

Game state that must survive the reload should live in the appropriate service,
session, or save/world-state system—not inside SceneFlow.

## 7. Loading screen lifetime

A loading overlay that must exist *during* replacement should live outside the
scene being replaced, for example in a persistent game shell/session/UI root.

Do not keep the entire world persistent just to retain a progress bar.

## Validation

- transition from menu to world;
- press the button repeatedly and confirm only one transition starts;
- inspect progress updates;
- intentionally provide a missing path and verify failure remains explicit;
- reload the current scene;
- confirm SceneFlow returns to idle after completion/failure.

## Related docs

- [`../scene_flow_quickstart.md`](../scene_flow_quickstart.md)
- [`core_services.md`](core_services.md)
- [`../../components/audio_save_scene_localization.md`](../../components/audio_save_scene_localization.md)
