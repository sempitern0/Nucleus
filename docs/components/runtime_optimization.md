# Runtime Optimization Contract

## Scope

This contract covers reusable frame-cost controls outside terrain and world
streaming:

```text
components/gameplay/timing
components/gameplay/lifecycle
components/gameplay/pooling
modules/ai integration
```

The goal is not to create an OptimizationManager. Godot remains authoritative
for frame processing, physics, rendering, navigation and profiling. Nucleus adds
small scene-owned tools that reduce repeated production wiring around cadence,
activity and allocation spikes.

## Staggered update scheduler

`NucleusUpdateScheduler` is for work that does not need to run every rendered or
physics frame.

Typical examples:

```text
utility-AI decisions
target rescoring
expensive awareness checks
secondary HUD refreshes
ambient simulation
low-frequency diagnostics
```

Register a callback with:

```gdscript
var token := scheduler.register_task(
    _refresh_awareness,
    0.25,
)
```

The callback receives elapsed seconds since its previous execution.

A negative phase selects automatic staggering. Registration order is distributed
across the interval so systems created in the same frame do not all wake on the
same later frame.

The scheduler enforces:

```text
max_callbacks_per_frame
frame_budget_usec
```

These are admission budgets, not profiler substitutes. A callback that already
started is never interrupted.

### No catch-up spiral

If a task was delayed, the scheduler executes it once and schedules the next run
from the current clock. It deliberately does not replay every missed interval.

That policy favors frame pacing over simulation catch-up and is therefore only
appropriate for work whose cadence is approximate. Fixed-step gameplay,
movement integration, authoritative timers and deterministic simulation should
continue using their normal physics/gameplay owner.

### Inspector adapter

`NucleusScheduledUpdate` exposes one scheduler task as a scene component and
emits:

```text
tick(elapsed)
```

Use an explicit scheduler reference or parent it below a scheduler ancestor.

## Activity gating

`NucleusActivityGate` applies an explicit active/inactive state to a scene-owned
target. The game decides when the target is relevant.

The gate can optionally manage:

```text
root process_mode
root visibility
particle emission
RigidBody sleeping
```

Only process mode is enabled by default. Visibility, particles and physics sleep
are opt-in because they can change presentation or gameplay behavior.

The gate snapshots authored state once and restores it on reactivation.
`recapture_baseline()` is available after an intentional runtime reconfiguration.
It refuses to capture while inactive so disabled state cannot accidentally
become the new baseline.

Nucleus deliberately does not infer distance, camera visibility, combat state or
network relevance. Those are consuming-game policies that call:

```gdscript
gate.set_active(relevant)
```

A child using `PROCESS_MODE_ALWAYS` can remain active when an ancestor is
disabled. Such exceptional children should be gated explicitly when required.

## Incremental pool prewarming

`NucleusObjectPool.prewarm()` remains synchronous for compatibility.

For large capacities use:

```gdscript
await pool.prewarm_incremental(200, 8)
```

This creates at most eight instances per rendered frame until the requested
capacity is reached.

For scene-authored automatic prewarming:

```text
auto_prewarm = true
prewarm_count = 200
auto_prewarm_instances_per_frame = 8
```

Zero `auto_prewarm_instances_per_frame` preserves the previous synchronous
behavior.

`prewarm_progress(created_count, total_count, target_total)` lets loading UI or
development tooling observe warmup without polling.

Incremental prewarming reduces scene-instantiation spikes; it does not make
instantiation free. Measure representative PackedScenes and choose a batch size
that preserves the product frame target.

## Utility AI scheduling

`NucleusAIUtilityBrain` can now consume an optional `NucleusUpdateScheduler`.
When all of the following are true:

```text
active
automatic_evaluation
update_scheduler assigned
evaluation_interval > 0
```

the brain disables its fallback physics polling and registers one scheduled
evaluation task.

`evaluation_phase = -1` uses automatic staggering, so many brains entering the
scene together are distributed across their decision interval.

Context-provider changes still call `request_evaluation()`. With a scheduler,
that request makes the task eligible for the next scheduler dispatch rather than
waiting for the normal interval.

If no scheduler is assigned, existing physics-driven behavior is preserved.
An `evaluation_interval` of zero also keeps the old per-physics-frame path.

## Recommended composition

A common NPC hierarchy can remain explicit:

```text
World
├── UpdateScheduler
└── NPC
    ├── ActivityGate
    ├── UtilityBrain -> UpdateScheduler
    ├── Targeting
    └── Movement
```

The gate decides whether the NPC subtree should remain active. The scheduler
spreads expensive low-frequency decisions. Per-frame movement remains under the
normal movement/physics owner.

## Performance boundaries

Do not move work into the scheduler merely because it is expensive.

Good candidates are tasks that tolerate bounded latency. Poor candidates are:

```text
player input
camera motion
CharacterBody movement
physics integration
hit resolution
network authority deadlines
frame-exact animation/gameplay events
```

Use `NucleusPerformanceSampler` and Godot's Profiler to verify that staggering or
gating improves the real workload. Architecture alone is not performance
evidence.
