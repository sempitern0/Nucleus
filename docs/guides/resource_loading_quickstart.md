# Resource Loading Quickstart

Use `NucleusResourceLoadQueue` when several Resources should be prepared
asynchronously without turning resource ownership into a global manager.

For one ordinary scene change, keep using `NucleusSceneFlow.change_scene()`.

Hands-on tutorial:

[`tutorials/resource_loading.md`](tutorials/resource_loading.md)

## 1. Add a queue

Create a scene-owned queue:

```text
Bootstrap
├── ResourceLoadQueue : NucleusResourceLoadQueue
├── LoadingUI
└── BootstrapCoordinator
```

A good starting value is:

```text
max_concurrent_requests = 2
```

Do not make it an Autoload just because loading is reusable.

If the queue must survive a specific scene replacement, own it from an existing
persistent game/session shell.

## 2. Create a load plan

Create a `NucleusLoadPlan` Resource and add `NucleusLoadEntry` Resources.

Example:

```text
BootstrapPlan
    InitialWorld
        path = res://game/world/world.tscn
        type_hint = PackedScene
        priority = Critical
        weight = 5
        retain = true

    Player
        path = res://game/player/player.tscn
        priority = High
        weight = 2
        retain = true

    CommonAudio
        path = res://audio/common_audio.tres
        priority = Normal
        weight = 1
        retain = true
```

`display_name` is optional and exists only for presentation.

## 3. Start the plan

```gdscript
@export var bootstrap_plan: NucleusLoadPlan
@onready var queue: NucleusResourceLoadQueue = $ResourceLoadQueue


func _ready() -> void:
    queue.batch_completed.connect(_on_batch_completed)
    queue.batch_failed.connect(_on_batch_failed)

    var error := queue.start(bootstrap_plan)

    if error != OK:
        push_error(error_string(error))
```

The queue polls threaded ResourceLoader requests over normal frames.

## 4. Add any custom presentation

The loader does not instantiate a loading screen.

Connect your own UI:

```gdscript
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var count_label: Label = %CountLabel
@onready var item_label: Label = %ItemLabel


func bind_loader(queue: NucleusResourceLoadQueue) -> void:
    queue.progress_changed.connect(_on_progress)
    queue.item_started.connect(_on_item_started)


func _on_progress(
    progress: float,
    processed: int,
    total: int,
) -> void:
    progress_bar.value = progress * 100.0
    count_label.text = "%d / %d" % [processed, total]


func _on_item_started(entry: NucleusLoadEntry) -> void:
    item_label.text = entry.get_display_name()
```

Replace those Controls with any presentation you want.

The loading system never depends on this scene.

## 5. Change to a preloaded scene

After the plan completes:

```gdscript
const WORLD_PATH := "res://game/world/world.tscn"


func _on_batch_completed(_plan: NucleusLoadPlan) -> void:
    var world := queue.get_retained(WORLD_PATH) as PackedScene

    if world == null:
        push_error("Initial world was not retained.")
        return

    NucleusSceneFlow.change_scene_to_packed(
        world,
        WORLD_PATH,
    )
```

`change_scene_to_packed()` preflights and switches the already loaded scene.

The target is not loaded a second time.

## Direct SceneFlow loading presentation

If only one destination scene needs loading, do not create a LoadPlan merely to
obtain a progress bar.

Use Scene Flow directly:

```gdscript
NucleusSceneFlow.load_progress.connect(_on_scene_progress)
NucleusSceneFlow.change_scene("res://game/world/world.tscn")
```

```gdscript
func _on_scene_progress(
    _scene_path: String,
    progress: float,
) -> void:
    progress_bar.value = progress * 100.0
```

A project-owned `CanvasLayer` or `Control` can display that progress until the
scene switch occurs.

Use `NucleusSceneTransitionProfile` independently when the switch also needs a
fade, curtain, shader, or custom transition overlay.

## Runtime preloading

Plans are not bootstrap-only.

A level coordinator can start a small plan while gameplay continues:

```gdscript
func prepare_harbour() -> void:
    if queue.is_busy():
        return

    queue.start(harbour_plan)
```

After completion, keep the resources retained until the owning feature no longer
needs them.

Then release them:

```gdscript
queue.release_all_retained()
```

Do not confuse releasing queue references with forcibly unloading Resources
owned by live Nodes or other systems.

## Required and optional entries

Required failure:

```text
batch result = FAILED
```

Optional failure:

```text
item_failed emits
failure remains queryable
batch may still complete
```

Use optional entries for presentation or secondary content that has a real
fallback.

Do not mark critical gameplay content optional merely to hide an error.

## Cancellation

`cancel()` prevents pending items from starting.

Already-running Godot threaded loads cannot be forcibly terminated. The queue
drains those requests and then emits `batch_cancelled`.

## Performance defaults

Start with:

```text
max_concurrent_requests = 2
use_sub_threads = false
```

Increase only after profiling.

Threaded loading reduces blocking I/O but does not make every later operation
free. Instantiation, shader compilation, GPU upload, and project-specific setup
can still affect frames.

On platforms without thread support, Nucleus falls back to one synchronous
ResourceLoader admission per frame. Profile those exports separately.

## Read next

- [`../components/resource_loading.md`](../components/resource_loading.md)
- [`tutorials/resource_loading.md`](tutorials/resource_loading.md)
- [`scene_flow_quickstart.md`](scene_flow_quickstart.md)
