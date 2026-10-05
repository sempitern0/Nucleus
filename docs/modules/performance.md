# Optional Performance / Diagnostics Module

## Status

`modules/performance` is optional and is not loaded by default.

It is development tooling around Godot's native performance APIs. It does not
replace the Godot Profiler, Network Profiler, Video RAM panel, external GPU
profilers, or platform-specific tooling.

The module is scene-owned by default.

## Purpose

The native Godot debugger exposes detailed measurements, but teams still need a
small layer that answers higher-level questions consistently:

```text
Are we inside the frame target?
Which subsystem is consuming the budget?
Did this workload regress?
What changed near the spike?
Which native profiler should we open next?
```

Nucleus adds:

```text
sampling
history
target profiles
budget checks
human-readable diagnostics
trace markers
JSON reports
custom game probes
Debugger custom-monitor integration
```

The measurements themselves still come from Godot.

## Public types

```text
NucleusPerformanceMetricIds
NucleusPerformanceProfile
NucleusPerformanceSnapshot
NucleusPerformanceDiagnostic
NucleusPerformanceAdvisor
NucleusPerformanceSampler
NucleusPerformancePanel
```

The ready-to-instance development panel is:

```text
res://modules/performance/performance_panel.tscn
```

## Ownership

A normal development scene can own the tooling directly:

```text
World
├── ...
└── PerformancePanel
    └── Sampler
```

Or a persistent development shell can own a sampler while scenes change:

```text
DevelopmentSession
├── PerformanceSampler
└── GameRoot
```

Do not promote the module to a baseline Autoload. A consuming game decides
whether profiling should survive scene replacement.

The default panel contains its own sampler for the lowest-friction setup.

## Godot-native sources

`NucleusPerformanceSampler` reads `Performance.get_monitor()`.

Current sampled groups include:

```text
time
    FPS
    process/frame time
    physics time
    navigation time

memory / objects
    static memory
    message-buffer high-water mark
    object count
    resource count
    node count
    orphan-node count

rendering
    rendered objects
    primitives
    draw calls
    video/texture/buffer memory

physics 2D / 3D
    active rigid bodies
    collision pairs
    islands

navigation 2D / 3D
    regions
    avoidance agents
    obstacles

render pipelines
    canvas
    mesh
    surface
    draw
    specialization compilation counters
```

Time monitors are normalized to milliseconds in Nucleus snapshots.

Some Godot monitors are debug-only and report zero in release builds. Some are
updated less frequently than every frame. Nucleus does not hide those engine
limitations.

## Native Debugger integration

When enabled, the sampler registers these custom monitors through
`Performance.add_custom_monitor()`:

```text
Nucleus/FrameBudget
Nucleus/Warnings
Nucleus/Criticals
```

They appear beside built-in monitors in the Godot Debugger.

Games can register numeric custom probes:

```gdscript
sampler.register_probe(
    &"world/active_fish",
    func() -> int:
        return active_fish.size(),
    true,
)
```

Publishing a probe to the Debugger uses the `NucleusGame` monitor category.
Snapshot/report IDs retain the original game-owned ID.

Custom probes are optional and should stay cheap. A probe is sampled repeatedly;
do not perform expensive searches merely to measure an expensive system.

## Performance profiles

`NucleusPerformanceProfile` is game-owned policy.

The only universal default is a 60 FPS development frame target. Optional
subsystem budgets are disabled until the game enables them.

Supported optional budgets include:

```text
physics time
navigation time
draw calls
rendered objects
primitives
video memory
static memory
node count
orphan nodes
2D/3D active physics objects
2D/3D collision pairs
2D/3D navigation agents
```

Zero means "not budgeted" for these maxima. `max_orphan_nodes = -1` disables the orphan-node check. Set it to `0` when
any debug orphan should be reviewed.

A project should create target-specific resources such as:

```text
performance_mid_desktop.tres
performance_high_desktop.tres
performance_handheld.tres
```

only when those targets exist in the product requirements.

Nucleus deliberately does not define universal Low/Medium/High hardware budgets.
A renderer-heavy strategy game, stylized platformer, and simulation cannot share
meaningful draw-call, body-count, or memory limits.

## Diagnostics

`NucleusPerformanceAdvisor` evaluates only measurements that have enough evidence
for a bounded recommendation.

Examples include:

```text
frame budget missed
frame budget low on headroom
FPS below target while CPU/frame monitor still has headroom
physics-time budget exceeded
navigation-time budget exceeded
draw/object/primitive budget exceeded
video/static memory budget exceeded
unexpected orphan nodes
physics body/pair budget exceeded
navigation-agent budget exceeded
render pipeline compilation after warmup
```

A diagnostic contains:

```text
severity
stable code
title
summary
evidence
suggested next steps
```

Recommendations identify the next investigation path. They are not automatic
optimization actions.

Nucleus will not silently:

```text
lower rendering quality
disable collisions
change physics tick rate
disable navigation
delete nodes
change gameplay replication
```

Those are product/gameplay decisions.

## Trace markers

The sampler can mark game events:

```gdscript
sampler.mark_trace(
    &"island_streamed",
    {
        "island_id": island_id,
        "entities": spawned_count,
    },
)
```

A trace stores:

```text
label
timestamp
nearest sample sequence
JSON-safe game metadata
```

Use traces to correlate a frame/memory/physics change with an authored event.

Trace markers are not function-level CPU traces. Use Godot's Profiler for that.

## Reports

The current history, traces, diagnostic events, active target profile,
engine/platform information, and latest diagnostics can be saved:

```gdscript
var error := sampler.save_report(
    "user://performance_report.json"
)
```

Reports are intended for development comparison, bug reports, CI/lab tooling, or
sharing a reproducible workload snapshot.

They are not a production telemetry backend.

## Relationship with Godot profilers

Use Nucleus to answer "where should I look?"

Then use the native specialist:

```text
CPU/script/frame timing
    Godot Debugger > Profiler

high-level multiplayer traffic
    Godot Debugger > Network Profiler

GPU resource memory
    Godot Debugger > Video RAM

long-lived monitor trends
    Godot Debugger > Monitors
    Nucleus history/report

GPU-specific bottlenecks
    platform/vendor GPU profiler when needed
```

The Godot Profiler has measurable overhead and is intentionally not always on.
Nucleus sampling is much lighter, but it also does not provide per-function
timings.

## Debug/release behavior

`NucleusPerformanceSampler.debug_build_only` defaults to `true`.

`NucleusPerformancePanel.hide_in_release` defaults to `true`.

This prevents accidental development HUD/profiling cost in release exports. A
game may explicitly sample in release-like builds, but it must remember that
some native Godot monitors are unavailable outside debug builds.

A representative exported debug build is often a better profiling target than
the editor when editor embedding or editor overhead changes the workload.

## Cost model

Sampling defaults to every `0.5` seconds, not every frame.

The history defaults to 120 samples.

The trace buffer defaults to 128 events.

These limits are configurable. Do not lower the interval aggressively without
measurement: observability itself can become part of the workload.

## Non-goals

The module is not:

```text
a replacement for Godot's Profiler
a GPU profiler
a packet sniffer
an automatic optimizer
a benchmark database
a hardware tier detector
a remote analytics SDK
a promise that a budget fits every game
```

Networking-specific traffic instrumentation can build on the same sampling/probe
contract in a later iteration without making this module depend on networking.

## Related documentation

- `docs/guides/performance_quickstart.md`
- `docs/guides/tutorials/performance_profiling.md`
- `docs/guides/project_configuration.md`
- `docs/guides/validation_ci_quickstart.md`
