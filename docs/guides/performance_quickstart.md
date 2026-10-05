# Performance / Diagnostics Quickstart

Use this module when the project needs continuous, low-overhead visibility into
performance without keeping Godot's full Profiler running.

For the detailed investigation workflow, continue with:

[`tutorials/performance_profiling.md`](tutorials/performance_profiling.md)

## What Nucleus owns

The optional module owns:

```text
sampling native Performance monitors
short history
game-owned performance target profiles
budget evaluation
human-readable diagnostics
trace markers
JSON reports
small custom game probes
summary monitors in Godot Debugger
```

It does not own:

```text
Godot's CPU/script profiler
network profiler
Video RAM inspector
GPU profiling
renderer selection
physics implementation
automatic quality reduction
hardware-tier policy
```

## Fastest setup

Instance:

```text
res://modules/performance/performance_panel.tscn
```

under a development scene:

```text
World
├── Camera3D
├── Gameplay
└── PerformancePanel
    └── Sampler
```

Run the game.

The panel starts sampling every 0.5 seconds and displays:

```text
FPS / frame time
physics time
navigation time
draw calls / rendered objects / primitives
node/orphan counts
VRAM
3D active bodies / collision pairs
3D navigation agents
current diagnostics
```

It also publishes Nucleus summary monitors in the native Debugger monitor view.

## Define the target before optimizing

The embedded sampler uses a default 60 FPS development target.

For a real project, create a `NucleusPerformanceProfile` Resource and assign it
to the Sampler.

Example policy for a game whose minimum supported target is a mid-range desktop:

```text
target_name = "Mid desktop / 1080p / 60"
target_fps = 60

max_draw_calls = measured project budget
max_video_memory_mb = measured project budget
max_physics_ms = measured project budget
...
```

Do not fill every field immediately.

Start with the frame target. Add subsystem budgets after representative scenes
give you evidence for meaningful limits.

If low-end PCs are not a supported product target, do not optimize toward an
invented low-end budget. Define the actual minimum and recommended targets.

## Mark important events

```gdscript
performance_sampler.mark_trace(
    &"inventory_open",
    {"slots": inventory.slot_count},
)
```

Useful trace points include:

```text
scene loaded
streaming chunk entered
large enemy wave spawned
inventory opened
procedural generation completed
multiplayer session populated
large VFX event started
```

Trace metadata should be JSON-safe.

## Add a game-specific metric

```gdscript
performance_sampler.register_probe(
    &"world/active_fish",
    func() -> int:
        return active_fish.size(),
)
```

To also show it in Godot Debugger > Monitors:

```gdscript
performance_sampler.register_probe(
    &"world/active_fish",
    func() -> int:
        return active_fish.size(),
    true,
)
```

Keep probes cheap.

## Save a report

```gdscript
var error := performance_sampler.save_report(
    "user://performance_report.json"
)

if error != OK:
    push_error(error_string(error))
```

The report includes:

```text
engine/platform metadata
active profile
sample history
trace markers
diagnostic events
latest diagnostics
```

## Follow diagnostics into native Godot tooling

Treat a recommendation as a routing hint:

```text
Frame/CPU warning
→ Debugger > Profiler

VRAM warning
→ Debugger > Video RAM

Multiplayer traffic problem
→ Debugger > Network Profiler

GPU-bound suspicion
→ renderer metrics, then a platform/vendor GPU profiler
```

Nucleus does not reproduce those profilers.

## Release safety

The sampler defaults to `debug_build_only = true`.

The panel defaults to `hide_in_release = true`.

If you deliberately profile a release-like export, disable that guard knowingly
and remember that some Godot `Performance` monitors return zero outside debug
builds.

## Next

Build a repeatable profiling exercise in:

[`tutorials/performance_profiling.md`](tutorials/performance_profiling.md)

The technical contract is:

[`../modules/performance.md`](../modules/performance.md)
