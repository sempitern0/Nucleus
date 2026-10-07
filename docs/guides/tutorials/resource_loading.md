# Tutorial: bootstrap and runtime loading presentation

This tutorial builds one resource-loading setup and then reuses the same visual
language for:

```text
A. static/bootstrap loading
B. a scene change
C. runtime anticipation while gameplay continues
```

The important rule is that presentation observes loading state. It does not own
ResourceLoader or scene replacement.

## 1. What we are building

Create:

```text
Bootstrap
├── ResourceLoadQueue : NucleusResourceLoadQueue
├── LoadingPresentation : Control
│   └── Panel
│       └── VBoxContainer
│           ├── Title : Label
│           ├── CurrentItem : Label
│           ├── ProgressBar : ProgressBar
│           └── Counter : Label
└── BootstrapCoordinator
```

Create a `NucleusLoadPlan` called:

```text
bootstrap_load.tres
```

The exact visual hierarchy is game-owned. A full-screen illustration, video,
animated 3D scene, simple bar, or accessibility-first static page all work with
the same signals.

## 2. Author the plan

Add several `NucleusLoadEntry` subresources.

A representative plan might contain:

```text
Initial world       Critical   weight 5
Player              High       weight 2
HUD                 High       weight 1
Common audio        Normal     weight 2
Optional ambience   Background weight 1 optional
```

Set a human-readable `display_name` when the raw filename is not appropriate for
the loading UI.

Set `retain = true` for resources the bootstrap coordinator needs after loading.

## 3. Build the custom presentation

Attach a project-owned script to `LoadingPresentation`.

```gdscript
extends Control

@onready var title: Label = %Title
@onready var current_item: Label = %CurrentItem
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var counter: Label = %Counter


func show_plan(plan: NucleusLoadPlan) -> void:
    title.text = (
        plan.display_name
        if not plan.display_name.is_empty()
        else "Loading..."
    )
    current_item.text = ""
    progress_bar.value = 0.0
    counter.text = "0 / %d" % plan.get_item_count()
    show()


func set_item(entry: NucleusLoadEntry) -> void:
    current_item.text = entry.get_display_name()


func set_progress(
    progress: float,
    processed: int,
    total: int,
) -> void:
    progress_bar.value = progress * 100.0
    counter.text = "%d / %d" % [processed, total]
```

This script knows only presentation values.

It does not call ResourceLoader.

It does not change scenes.

## 4. Wire bootstrap loading

Attach a coordinator:

```gdscript
extends Node

const WORLD_PATH := "res://game/world/world.tscn"

@export var load_plan: NucleusLoadPlan
@onready var queue: NucleusResourceLoadQueue = $ResourceLoadQueue
@onready var presentation = $LoadingPresentation


func _ready() -> void:
    queue.progress_changed.connect(presentation.set_progress)
    queue.item_started.connect(presentation.set_item)
    queue.batch_completed.connect(_on_completed)
    queue.batch_failed.connect(_on_failed)

    presentation.show_plan(load_plan)

    var error := queue.start(load_plan)
    if error != OK:
        push_error(error_string(error))


func _on_completed(_plan: NucleusLoadPlan) -> void:
    var world := queue.get_retained(WORLD_PATH) as PackedScene

    if world == null:
        push_error("World scene was not retained.")
        return

    NucleusSceneFlow.change_scene_to_packed(
        world,
        WORLD_PATH,
    )


func _on_failed(
    _plan: NucleusLoadPlan,
    failures: Array[Dictionary],
) -> void:
    push_error("Bootstrap loading failed: %s" % str(failures))
```

The bootstrap scene remains alive while the queue works.

When `change_scene_to_packed()` succeeds, the old bootstrap scene can disappear
normally.

## 5. Show `1 / 70` instead of a percentage

No special loader mode is needed.

The queue already reports:

```text
processed
total
```

Your UI decides what to show:

```gdscript
func set_progress(
    _progress: float,
    processed: int,
    total: int,
) -> void:
    counter.text = "%d / %d" % [processed, total]
```

If you want only a smooth bar:

```gdscript
progress_bar.value = progress * 100.0
```

If you want both, display both.

The counter and weighted bar intentionally represent different information.

## 6. Give large assets more visual weight

Suppose 69 small resources load quickly but the world scene is expensive.

Without weights, a count may reach:

```text
69 / 70
```

while significant work remains.

Give the world a larger `weight`.

The bar then advances according to each active threaded request's native progress
and your authored relative cost.

The counter remains truthful about item completion.

## 7. Custom presentation during a direct scene change

For a single scene target, use Scene Flow directly instead of creating a
one-entry plan.

Create a `Control` in the outgoing scene or in an existing persistent UI shell:

```gdscript
func _ready() -> void:
    NucleusSceneFlow.transition_started.connect(_on_transition_started)
    NucleusSceneFlow.load_progress.connect(_on_scene_load_progress)
    NucleusSceneFlow.transition_failed.connect(_on_transition_failed)
```

```gdscript
func _on_transition_started(
    _from_scene: String,
    _to_scene: String,
) -> void:
    show()


func _on_scene_load_progress(
    _scene_path: String,
    progress: float,
) -> void:
    progress_bar.value = progress * 100.0
```

If the Control belongs to the outgoing scene, normal scene replacement removes
it automatically once the target becomes current.

If it belongs to a persistent UI shell, also observe `transition_finished` and
hide it there.

The presentation remains custom.

`NucleusSceneFlow` remains the scene owner.

If you also want a fade, curtain, flash, or shader transition, pass a
`NucleusSceneTransitionProfile` to `change_scene()`.

The loading display and switch transition are separate responsibilities.

## 8. Presentation that must survive the scene switch

A Control owned by the outgoing gameplay scene is removed when that scene is
replaced.

If the presentation must remain visible across both sides of the switch, own it
from an existing persistent game/session shell or use a custom
`NucleusSceneTransitionOverlay`.

Do not create a global loading Autoload solely for convenience.

For the common case, the progress UI only needs to exist until the target is
ready, and the transition overlay covers the actual switch.

## 9. Runtime anticipation

Now reuse the same queue inside a gameplay scene:

```text
World
├── RuntimeLoadQueue
├── HarbourStreamingCoordinator
└── SmallLoadingIndicator
```

When the game has evidence the player is approaching the harbour:

```gdscript
func prepare_harbour() -> void:
    if load_queue.is_busy():
        return

    load_queue.start(harbour_plan)
```

Do not block movement while the plan is running.

A small indicator can connect to the same:

```text
progress_changed
item_started
batch_completed
batch_failed
```

signals.

When the harbour is actually needed, consume retained resources.

## 10. Release retained resources deliberately

When the owning gameplay scope no longer needs the preload:

```gdscript
load_queue.release_retained(HARBOUR_SCENE)
```

or:

```gdscript
load_queue.release_all_retained()
```

This releases only the queue's references.

If another scene or object still references the Resource, Godot keeps it alive.

## 11. Error presentation

Do not bury a required load failure behind a bar stuck at 99%.

Connect:

```gdscript
queue.batch_failed.connect(_on_batch_failed)
```

A game can then choose:

```text
Retry
Return to menu
Use known fallback
Show diagnostics in development
```

Nucleus reports the failure but does not choose the product UX.

Optional item failures remain available in:

```gdscript
queue.get_failures()
```

even when the batch completes.

## 12. Cancellation

A menu may close while background content is still loading.

Call:

```gdscript
queue.cancel()
```

Pending requests will not start.

Requests already executing inside ResourceLoader are allowed to finish and are
discarded by the cancelling queue because Godot does not expose hard cancellation
for them.

## 13. Performance checklist

Start with:

```text
max_concurrent_requests = 2
use_sub_threads = false
```

Then profile.

Watch for:

```text
frame spikes during scene instantiation
shader compilation
texture/GPU uploads
large dependency trees
memory retained too early
too many simultaneous plans
```

Threaded file loading is only one part of runtime smoothness.

On platforms where `NucleusPlatform.supports_threads()` is false, the queue
falls back to one synchronous resource admission per frame. Test Web and other
restricted targets independently instead of assuming desktop timings.

## 14. What remains game-owned

The game decides:

```text
which content is anticipated
loading art
loading copy and tips
whether a counter or bar is shown
resource weights
retry policy
memory budget
world-streaming heuristics
```

Nucleus owns only the reusable loading contract.

## 15. Verify it

Run:

```bash
godot --headless --path . --import
godot --headless --path . res://tests/headless/test_runner.tscn
godot --headless --path . res://tests/smoke/resource_loading_smoke.tscn
```

The smoke scene validates real threaded loading rather than only plan metadata.

## Technical contract

[`../../components/resource_loading.md`](../../components/resource_loading.md)
