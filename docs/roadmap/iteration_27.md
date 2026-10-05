# Iteration 27 — Performance Observability / Diagnostics

## Goal

Give consuming games a useful performance control surface from early development
without making profiling a baseline runtime dependency or replacing Godot's
native tooling.

## Delivered

```text
modules/performance
    NucleusPerformanceMetricIds
    NucleusPerformanceProfile
    NucleusPerformanceSnapshot
    NucleusPerformanceDiagnostic
    NucleusPerformanceAdvisor
    NucleusPerformanceSampler
    NucleusPerformancePanel
```

The module is optional and scene-owned.

## Native-first boundary

Godot remains authoritative for measurement and deep profiling.

Nucleus consumes:

```text
Performance.get_monitor()
Performance.add_custom_monitor()
Godot Debugger > Profiler
Godot Debugger > Network Profiler
Godot Debugger > Video RAM
```

Nucleus adds:

```text
normalized snapshots
short history
game-owned budgets
bounded recommendations
trace markers
JSON reports
custom probes
compact development panel
```

It does not implement another CPU/GPU profiler.

## Target policy

Only the frame target has a reusable default.

Project-specific budgets such as draw calls, VRAM, node counts, physics pairs,
and navigation agents remain disabled until a consuming game opts in.

Hardware tiers belong to the game/product requirements. Nucleus does not assume
that every game must support low-end PCs.

## Diagnostics

The first advisor pass covers:

```text
frame budget/headroom
FPS below target without obvious CPU overrun
physics/navigation time
render draw/object/primitive budgets
VRAM/static memory
node/orphan counts
2D/3D active bodies and collision pairs
2D/3D navigation agents
runtime draw/surface pipeline compilation
```

Recommendations route the developer toward evidence and native profilers. They
never mutate gameplay, renderer, physics, or quality settings automatically.

## Trace/report workflow

Game code may annotate meaningful events:

```text
scene/stream transition
spawn wave
inventory open
VFX activation
network population change
```

The sampler can export history + traces + current diagnostics as JSON for
comparison and bug reports.

## Validation

A headless suite covers profile defaults, snapshot deltas, frame/render budgets,
pipeline-compilation detection, and disabled-budget behavior.

The module remains debug-only by default in runtime use.

## Follow-up evidence

Future optimization helpers should graduate only after consuming games expose a
repeatable bottleneck.

Likely next evidence areas:

```text
physics/collision scene audits
pooling/lifecycle counters
render/visibility diagnostics
network traffic/replication probes
navigation/AI scheduling
resource-loading/stutter instrumentation
```

Those should reuse this sampling/reporting contract instead of building separate
diagnostic frameworks.
