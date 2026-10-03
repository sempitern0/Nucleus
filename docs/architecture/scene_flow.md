# Nucleus Scene Flow Architecture

Target engine: Godot 4.7.x.

## Goal

Scene Flow coordinates scene loading and replacement without owning gameplay
state, loading-screen visuals, save data, or navigation policy.

```text
Game / UI
   │
   ▼
NucleusSceneFlow
   │
   ├── ResourceLoader
   └── SceneTree
```

## Why it is an Autoload

The coordinator must survive the scene it is replacing.

It owns only transient transition state:

```text
IDLE
LOADING
SWITCHING
```

No game session, player, inventory, route history, or arbitrary global state is
stored here.

## Basic usage

```gdscript
NucleusSceneFlow.change_scene(
    "res://scenes/game/game.tscn"
)
```

Reload:

```gdscript
NucleusSceneFlow.reload_current_scene()
```

Already-loaded scene:

```gdscript
NucleusSceneFlow.change_scene_to_packed(game_scene)
```

## Background loading

By default Scene Flow requests threaded loading when the runtime reports thread
support.

```text
ResourceLoader.load_threaded_request()
        │
        ▼
load_threaded_get_status()
        │
        ▼
load_threaded_get()
        │
        ▼
SceneTree.change_scene_to_packed()
```

Status is polled once per frame, matching Godot's recommended threaded-loading
workflow.

If the runtime does not expose the `threads` feature, loading falls back to
synchronous `ResourceLoader.load()`.

This matters for Web exports where thread availability depends on the export
and hosting environment.

## Signals

```gdscript
transition_started(from_scene, to_scene)
load_progress(scene_path, progress)
transition_completed(scene_path, scene)
transition_failed(scene_path, error)
busy_changed(is_busy)
```

A loading-screen scene or overlay can subscribe to these signals without Scene
Flow importing UI code.

## No built-in fade screen

Nucleus deliberately does not bake presentation into Scene Flow.

A project may implement:

```text
fade to black
animated loading screen
progress bar
tips
splash transition
```

as UI that observes the service.

## No navigation history by default

Games do not universally behave like browser stacks.

Nucleus therefore does not introduce:

```text
push_scene()
pop_scene()
back_stack
```

until a project actually requires that policy.

## No transition payload globals

Data that must survive scene replacement belongs to an explicit game/session
owner or the save system.

Scene Flow does not provide a hidden global Dictionary for passing gameplay
state between scenes.

## Resource portability

Scene paths are required to use:

```text
res://
```

They are loaded with `ResourceLoader`, which is the engine-supported path for
resources packaged into exported builds.

Host filesystem paths are intentionally rejected.
