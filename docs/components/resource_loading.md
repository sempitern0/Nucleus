# Resource Loading Contract

Target engine: Godot 4.7.x.

## Scope

```text
core/loading
```

Resource Loading is Nucleus infrastructure for explicit asynchronous batches of
Godot Resources. It is designed for:

```text
bootstrap preloading
large menu/gameplay transitions
runtime anticipation of upcoming content
optional content bundles
custom loading presentation
```

Public types:

```text
NucleusLoadEntry
NucleusLoadPlan
NucleusResourceLoadQueue
```

There is no loading Autoload and no global asset registry.

Godot `ResourceLoader` remains authoritative for:

```text
resource formats
imports
threaded loading
dependency loading
resource cache
```

Nucleus adds scheduling and observation around those native facilities.

## Ownership

Use this split:

```text
ResourceLoader
    resource import/cache/threaded work

NucleusResourceLoadQueue
    explicit batch + bounded concurrency + progress + retention

NucleusSceneFlow
    application-level scene replacement

game-owned coordinator
    decides what to preload and when to transition

game-owned presentation
    decides how loading looks
```

The queue does not change scenes.

Scene Flow does not become a universal resource manager.

The UI does not know how resources are loaded.

## NucleusLoadEntry

Each entry describes one explicit resource request:

```text
path
display_name
type_hint
priority
weight
required
retain
use_sub_threads
```

`path` uses an absolute Godot resource path such as:

```text
res://game/world/world.tscn
```

`display_name` is presentation metadata. If omitted,
`get_display_name()` falls back to the filename.

`type_hint` is optional and is forwarded to `ResourceLoader`.

### Priority

Built-in priorities are:

```text
BACKGROUND
NORMAL
HIGH
CRITICAL
```

Priority affects which pending entries start first. It does not interrupt an
already-running ResourceLoader request.

Entries with equal priority keep plan order.

### Weight

`weight` controls aggregate visual progress.

For example:

```text
tiny icon        weight 0.25
common audio     weight 1.0
large world      weight 5.0
```

The queue exposes both:

```text
weighted progress 0..1
processed item count / total item count
```

A presentation can therefore choose between:

```text
63%
```

and:

```text
44 / 70
```

or show both.

Weights are developer-authored estimates. Nucleus does not profile resources and
silently rewrite them.

### Required versus optional

A failed `required` entry makes the final batch state `FAILED`.

A failed optional entry remains observable through `item_failed` and
`get_failures()`, but the batch may still complete successfully.

All entries are allowed to settle so the caller receives a complete diagnostic
picture instead of only the first error.

### Retention

`retain = true` tells the queue to keep a strong Resource reference after load.

Retrieve it with:

```gdscript
queue.get_retained(path)
```

Release it explicitly with:

```gdscript
queue.release_retained(path)
```

or:

```gdscript
queue.release_all_retained()
```

Nucleus does not implement an independent LRU cache or force-unload Resources
that may still be owned by live scenes.

`retain = false` is useful when a consumer takes ownership from
`item_completed`.

## NucleusLoadPlan

A plan is an authored Resource containing an ordered list of
`NucleusLoadEntry`.

Example:

```text
BootstrapPlan
├── UI theme
├── common audio
├── player scene
└── initial world scene
```

Plans reject duplicate paths.

This keeps:

```text
item counts
weight aggregation
retention ownership
error reporting
```

deterministic.

If two unrelated systems need the same Resource, Godot's ResourceLoader cache
remains the underlying sharing mechanism.

## NucleusResourceLoadQueue

Typical scene ownership:

```text
Bootstrap
├── ResourceLoadQueue
└── LoadingUI
```

or:

```text
LevelCoordinator
├── ResourceLoadQueue
└── RuntimeLoadingIndicator
```

The queue must be inside a live `SceneTree` before starting a threaded plan.

Basic use:

```gdscript
@export var bootstrap_plan: NucleusLoadPlan
@onready var loader: NucleusResourceLoadQueue = $ResourceLoadQueue


func _ready() -> void:
    loader.progress_changed.connect(_on_progress)
    loader.batch_completed.connect(_on_loaded)

    var error := loader.start(bootstrap_plan)
    if error != OK:
        push_error(error_string(error))
```

## Progress contract

The main progress signal is:

```gdscript
progress_changed(
    progress: float,
    processed_items: int,
    total_items: int,
)
```

`progress` is weighted.

`processed_items` counts terminal entries, including optional failures.

This means a simple counter can display:

```text
1 / 70
2 / 70
...
70 / 70
```

without pretending that every resource has equal cost.

Per-item presentation can observe:

```text
item_started
item_progress
item_completed
item_failed
```

The entry object includes its `display_name`.

## Threading and concurrency

The queue calls:

```text
ResourceLoader.load_threaded_request()
ResourceLoader.load_threaded_get_status()
ResourceLoader.load_threaded_get()
```

Status is polled over normal frames. There is no busy wait.

`max_concurrent_requests` defaults to `2`.

A large plan does not start every item simultaneously.

This limits:

```text
I/O pressure
dependency spikes
CPU contention
main-thread disruption
```

Each entry defaults to:

```text
use_sub_threads = false
```

Godot may use more worker threads for one resource when this is enabled, but
that can increase contention with the main thread. Enable it only after profiling
the actual game and target hardware.

When `NucleusPlatform.supports_threads()` is false, the queue falls back to
normal `ResourceLoader.load()` and admits one pending resource per frame. This
keeps the same observable batch contract without pretending that synchronous
resource parsing becomes free.

## Native cache reuse

Before creating a new threaded request, the queue checks:

```text
retained resources
ResourceLoader native cache
```

A cached resource completes immediately.

The queue also tolerates a threaded request that is already in progress in
ResourceLoader and observes that request instead of requiring a second private
loader implementation.

There is no Nucleus-wide service locator for Resources.

## Cancellation

`cancel()` stops pending requests from being admitted.

Godot does not expose cancellation for a ResourceLoader threaded request already
running. Therefore active requests are drained to a terminal engine state and
their newly loaded Resources are discarded by the cancelling queue.

This is best-effort admission cancellation, not thread termination.

## Bootstrap loading

A bootstrap scene can own both loader and presentation:

```text
Bootstrap
├── ResourceLoadQueue
├── LoadingPresentation
└── BootstrapCoordinator
```

The coordinator starts a plan and changes scene only after successful completion.

The loading UI can be any authored `Control` or `CanvasLayer`.

Nucleus supplies state, not visual style.

## Runtime anticipation

The same queue can preload resources before they are needed:

```text
player approaches harbour
        ↓
game-owned trigger/coordinator
        ↓
LoadPlan for harbour content
        ↓
ResourceLoadQueue
        ↓
gameplay continues
        ↓
content is retained for later use
```

Do not start background loads merely because files exist on disk.

The game remains responsible for deciding likely future needs.

## Scene changes

For a single scene replacement, prefer the existing:

```gdscript
NucleusSceneFlow.change_scene(scene_path)
```

Scene Flow already owns threaded scene loading, progress, preflight
instantiation, transition presentation, failure handling, and rollback.

Observe:

```gdscript
NucleusSceneFlow.load_progress
```

when a custom loading screen needs scene-transition progress.

For a larger bundle where a scene and supporting resources must be ready first:

```text
NucleusResourceLoadQueue
    preload bundle
        ↓
get_retained(scene_path) as PackedScene
        ↓
NucleusSceneFlow.change_scene_to_packed(...)
```

This avoids loading the target scene twice.

## Presentation is intentionally separate

There is no `NucleusLoadingScreen` with required styling.

A presentation consumes public signals and can display:

```text
ProgressBar
1 / 70 counter
percentage
current resource label
animated icon
tips
video
3D loading scene
accessibility-safe static screen
nothing at all
```

Static/bootstrap presentation normally listens to
`NucleusResourceLoadQueue`.

A direct scene-change presentation normally listens to
`NucleusSceneFlow`.

The tutorial shows both without introducing a hidden coupling between UI,
ResourceLoadQueue, and SceneFlow.

## preload() versus the queue

Use native `preload()` for small hard dependencies required by a script:

```gdscript
const ICON := preload("res://ui/icon.tres")
```

Use a load plan for:

```text
large resources
optional resources
runtime-selected content
bootstrap bundles
future zones
large scenes
```

The queue is not a replacement for ordinary script dependencies.

## Performance rules

Prefer:

```text
small explicit plans
bounded concurrency
native cache reuse
use_sub_threads = false until profiled
retention only for Resources that must stay warm
```

Avoid:

```text
directory-wide auto loading
hundreds of concurrent requests
polling in a tight loop
duplicating ResourceLoader cache
holding every loaded asset forever
```

Resource loading can still cause frame-time pressure from dependency parsing,
GPU uploads, shader compilation, or scene instantiation even when file loading
is threaded.

Measure the consuming game on target hardware.

## Failure boundary

The queue reports ResourceLoader failures.

It does not decide:

```text
retry UX
fallback content
network downloads
store entitlement
DLC verification
fatal-error screens
```

Content Packs remains the owner for verification and mounting of official
external PCKs before their resources are requested.

## What stays game-owned

```text
which assets belong in each plan
weight tuning
loading-screen art and copy
tips and marketing content
world streaming heuristics
predictive loading rules
memory budgets
retry/fallback policy
when a preloaded Resource is actually instantiated
```

Repeated production evidence can justify narrower helpers later without turning
Nucleus into an Addressables-style asset database.
