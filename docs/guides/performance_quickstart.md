# Performance / Diagnostics Quickstart

Use this optional module when a project needs continuous, low-overhead visibility
into performance without keeping Godot's full Profiler running.

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

The panel samples every 0.5 seconds by default.

## Read the dashboard

The top row answers four questions quickly:

```text
FPS
    are we sustaining the configured target?

PACING P95
    are almost all frames arriving consistently?

PHYSICS
    how much native physics time is being reported?

NAVIGATION
    how much native navigation time is being reported?
```

The pacing history adds:

```text
P50
    normal frame cadence

P95
    slower tail of ordinary frames

MAX
    worst interval in each sampling window
```

At 60 FPS the nominal cadence is 16.67 ms. Nucleus does not mark a frame as
critical merely because Godot `TIME_PROCESS` is near or above that value.
Effective FPS and recent pacing windows decide frame health.

## Define the target before optimizing

The embedded sampler uses a default 60 FPS development target.

For a real project, create a `NucleusPerformanceProfile` Resource and assign it
to the Sampler.

Example:

```text
target_name = "Mid desktop / 1080p / 60"
target_fps = 60

max_draw_calls = measured project budget
max_video_memory_mb = measured project budget
max_physics_ms = measured project budget
...
```

Do not fill every budget immediately. Start with the actual product frame target
and add subsystem limits only after representative scenes provide evidence.

## Capture a baseline

Run a repeatable workload long enough to fill a useful history window, then save:

```gdscript
var error := performance_sampler.save_report(
    "user://baseline.json"
)
```

A useful baseline should record its scenario outside the JSON as part of your
test workflow, for example:

```text
main menu idle
harbor 60 boats
combat arena wave 5
streaming route A -> B
4-player LAN session
```

Do not compare unrelated workloads and call the result a regression.

## Compare after a change

Load the baseline and compare the current capture:

```gdscript
var baseline := NucleusPerformanceReportComparator.load_report(
    "user://baseline.json"
)

var comparison := performance_sampler.compare_report(
    baseline,
    0.10,
    0.25,
)
```

The example flags roughly 10% relative regressions as warnings and 25% as
critical comparison changes.

Always inspect:

```gdscript
comparison["comparable_context"]
comparison["context_warnings"]
```

A benchmark run from editor embedding should not be treated as equivalent to a
standalone exported debug build. Renderer, OS, target FPS, and Godot major/minor
changes also affect comparability.

## Inspect history programmatically

Statistics:

```gdscript
var stats := performance_sampler.get_metric_statistics(
    NucleusPerformanceMetricIds.FRAME_INTERVAL_P95_MS,
    60,
)
```

Ordered series:

```gdscript
var values := performance_sampler.get_metric_series(
    NucleusPerformanceMetricIds.FRAME_INTERVAL_P95_MS,
    60,
    true,
)
```

Use these APIs for project-specific debug views instead of creating another
parallel sampler.

## Mark important events

```gdscript
performance_sampler.mark_trace(
    &"inventory_open",
    {"slots": inventory.slot_count},
)
```

Useful trace points include scene loads, streaming boundaries, spawn waves,
procedural generation, large VFX events, and multiplayer population changes.

## Add a game-specific metric

```gdscript
performance_sampler.register_probe(
    &"world/active_fish",
    func() -> int:
        return active_fish.size(),
)
```

To also publish it in Godot Debugger > Monitors, pass `true` as the third
argument. Keep probes cheap.

## Follow diagnostics into native tooling

```text
Frame / CPU warning
    -> Debugger > Profiler

VRAM warning
    -> Debugger > Video RAM

Multiplayer traffic problem
    -> Debugger > Network Profiler

GPU-bound suspicion
    -> renderer metrics, then platform/vendor GPU profiler
```

Nucleus routes the investigation; it does not reproduce those profilers.

## Release safety

The sampler defaults to `debug_build_only = true` and the panel defaults to
`hide_in_release = true`.

If a release-like export is profiled intentionally, remember that some Godot
`Performance` monitors are unavailable outside debug builds.

## Next

For deeper methodology, continue with:

[`tutorials/performance_profiling.md`](tutorials/performance_profiling.md)

The technical contract is:

[`../modules/performance.md`](../modules/performance.md)
