# Performance / Diagnostics Quickstart

Performance work starts with a repeatable workload and a product target, not a
universal draw-call/FPS rule.

## 1. Add the optional sampler

Instance:

```text
res://modules/performance/performance_panel.tscn
```

under a development scene. The embedded sampler defaults to low-frequency
sampling and a 60 FPS development target.

Create a game-owned `NucleusPerformanceProfile` for each hardware/resolution/FPS
target the product actually promises.

## 2. Watch frame health, then open the specialist profiler

Useful groups include:

```text
frame pacing p50 / p95 / max
physics and navigation time
draw calls / objects / primitives
video and static memory
physics objects / collision pairs
navigation agents / obstacles
pipeline compilation counters
```

Nucleus answers "where should I look?" and "did this workload regress?". Use the
Godot Profiler, Network Profiler, Video RAM tools and platform GPU profilers for
deep investigation.

## 3. Mark authored events

```gdscript
performance_sampler.mark_trace(
    &"combat_wave_started",
    {"enemy_count": enemies.size()},
)
```

Trace scene transitions, spawn bursts, large saves, VFX first-use and other
meaningful events; do not emit markers every frame.

## 4. Capture and compare

```gdscript
performance_sampler.save_report("user://baseline.json")
```

After a change, compare the same workload under equivalent context. Inspect
`comparable_context` and its warnings before treating deltas as a regression.

## 5. Choose an intervention from evidence

Typical mapping:

| Evidence | Candidate tool |
| --- | --- |
| many low-frequency jobs align on one frame | `NucleusUpdateScheduler` |
| distant/inactive subtrees still process | `NucleusActivityGate` |
| pool creation hitches | incremental pool prewarm |
| Utility AI evaluates in bursts | scheduler-backed AI staggering |
| rendering budget pressure | `NucleusRenderAudit` + native profiler |
| physics pressure | `NucleusPhysicsAudit` + native profiler |
| first-use PackedScene hitch | `NucleusWarmupSequence` |
| first-use GPU pipeline hitch | game-authored rendered warmup after evidence |
| one-shot audio saturation | voice priorities |
| bursty UI writes | `NucleusUIRefreshCoalescer` |
| large participant capture spike | incremental save capture |

Continue with [`runtime_optimization_quickstart.md`](runtime_optimization_quickstart.md)
only after the measurement identifies one of these shapes.
