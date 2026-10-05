# Profile a Real Gameplay Workload

This tutorial builds a repeatable performance workflow around Godot's native
monitoring/profiling tools and the optional Nucleus performance layer.

The goal is not to make a synthetic benchmark green. The goal is to answer:

```text
What is the product target?
Where is the current bottleneck?
What evidence supports that conclusion?
What changed near a spike?
Did the optimization improve the same workload?
```

## 1. Pick a representative workload

Do not profile an empty test scene and extrapolate to the game.

Choose a scene or sequence that represents real pressure. Examples:

```text
dense combat
large island/level view
inventory with realistic content
many AI agents
streaming boundary
multiplayer session with expected player count
large VFX event
```

Make the workload repeatable.

Write down:

```text
resolution
renderer
graphics preset
target FPS
player count
entity count
camera path or gameplay steps
build type
hardware
```

Without those conditions, two captures are not comparable.

## 2. Define the product target

Nucleus does not assume every game supports low-end PCs.

A project focused on mid/high desktop hardware might define:

```text
minimum target
    Mid desktop
    1920×1080
    60 FPS
    project's chosen quality preset

recommended target
    High desktop
    2560×1440
    60 or 120 FPS
```

A handheld/mobile product will use different profiles.

Create one `NucleusPerformanceProfile` Resource per target that matters.

Start with:

```text
target_name
target_fps
```

Leave optional budgets at `0` until you have evidence.

Why?

Because this:

```text
"500 draw calls is always good"
```

is not a useful cross-project rule.

A game with complex shadows, many materials, MultiMesh-heavy vegetation, or a
very different renderer can have a completely different cost shape.

## 3. Add the development panel

Instance:

```text
res://modules/performance/performance_panel.tscn
```

A simple tree is:

```text
World
├── Camera3D
├── Gameplay
└── PerformancePanel
    └── Sampler
```

Select `Sampler` and assign your `NucleusPerformanceProfile`.

Run the scene.

The panel is intentionally compact. It is a triage surface, not another Godot
Profiler.

## 4. Understand the first line

The panel shows:

```text
FPS
frame/process time
physics time
navigation time
```

For a 60 FPS target:

```text
1000 / 60 = 16.67 ms
```

For 120 FPS:

```text
1000 / 120 = 8.33 ms
```

The configured frame target is the most important budget.

Nucleus warns before/at the configured ratio so the project can keep headroom
for spikes and slower machines.

If frame time is over budget, do not immediately optimize whichever number looks
largest. Capture the same workload with Godot's Profiler.

## 5. Use the native Profiler for CPU/function timing

Godot's Profiler is intentionally not always enabled because detailed profiling
adds overhead.

When Nucleus reports a frame/CPU warning:

1. reproduce the workload;
2. open **Debugger > Profiler**;
3. start profiling;
4. execute the same sequence;
5. stop after the spike/slow interval;
6. inspect frame time, physics time, and expensive script functions;
7. change one bottleneck;
8. repeat the same sequence.

Nucleus is useful before this step because its lightweight history can tell you
*when* and *which subsystem* deserves a deeper capture.

It is not a substitute for per-function timing.

## 6. Read rendering pressure

The panel includes:

```text
draw calls
rendered objects
primitives
VRAM
```

Do not optimize any one value in isolation.

### Draw calls high

Typical investigation directions:

```text
many unique materials
many individually rendered repeated meshes
visibility too broad
objects that could use MultiMesh
material/state fragmentation
```

Potential improvements include:

```text
MultiMesh for repeated visual instances
shared materials
visibility ranges / LOD
occlusion where appropriate
reducing unnecessarily separate renderables
```

Only use them if the capture indicates rendering pressure.

### Primitives high

Inspect:

```text
mesh LOD
distant geometry
shadow-casting geometry
depth/shadow pass multiplication
```

A primitive count is not the same as authored triangle count because rendering
may include additional passes.

### VRAM high

Open **Debugger > Video RAM**.

That view can identify actual resources consuming GPU memory. Nucleus only
provides the trend/budget signal.

Common areas to inspect:

```text
large textures
unnecessary uncompressed formats
oversized render targets
duplicate resources
mesh buffers
```

## 7. Detect first-use pipeline stutter

Godot exposes pipeline compilation counters.

Nucleus compares cumulative counters between samples after the configured warmup
period.

A diagnostic such as:

```text
Rendering pipelines compiled during the measured workload
```

means new draw/surface pipelines appeared after startup.

This often correlates with first-use content:

```text
new material variant
first appearance of a VFX
new mesh/shader combination
scene entered for first time
```

Mark those events and reproduce from a clean run.

Do not build a custom shader cache before reviewing Godot's own pipeline
compilation guidance and deciding whether warming representative content solves
the actual hitch.

## 8. Investigate physics

Useful panel/native values include:

```text
physics time
2D/3D active objects
collision pairs
physics islands
```

A physics bottleneck is not solved automatically by lowering the physics tick.

Investigate first:

```text
rigid bodies that never sleep
distant simulation that remains active
unnecessary collision-layer/mask intersections
too many overlapping monitoring Areas
complex collision geometry
frequent body creation/destruction
```

For 3D, prefer simple collision shapes where accurate concavity is unnecessary.

For static world geometry, use static ownership instead of rigid simulation when
the object never needs to move physically.

If object churn is the problem, evaluate existing Nucleus pooling rather than
changing the physics model.

## 9. Investigate navigation / AI

Nucleus samples:

```text
navigation process time
2D/3D region counts
avoidance-agent counts
obstacles
```

A high agent count is primarily interesting when avoidance is enabled.

Questions to ask:

```text
Does every agent need avoidance all the time?
Are paths requested every frame?
Can distant/inactive AI update less frequently?
Is navigation rebuilding because world geometry changes?
```

Keep Godot `NavigationServer` as the source of truth. Optimize game policy around
it before replacing native navigation.

## 10. Mark gameplay events

A number spike is easier to understand when the report contains authored
context.

Example:

```gdscript
func spawn_wave(wave_index: int) -> void:
    performance_sampler.mark_trace(
        &"wave_spawn",
        {
            "wave": wave_index,
            "enemy_count": enemies_to_spawn.size(),
        },
    )

    _spawn_wave_contents()
```

Other useful markers:

```text
world chunk streamed
large save loaded
inventory populated
boss phase entered
weather/VFX activated
new multiplayer peers admitted
```

Markers should describe events, not spam every frame.

## 11. Add domain-specific probes

Godot cannot know every game concept.

For example:

```gdscript
func _ready() -> void:
    performance_sampler.register_probe(
        &"world/active_fish",
        _active_fish_count,
        true,
    )


func _active_fish_count() -> int:
    return active_fish.size()
```

That metric now appears in Nucleus snapshots/reports and, when published, in the
native Debugger monitor list under `NucleusGame`.

Good custom metrics are cheap counters already owned by the system.

Bad probes traverse the scene tree or perform expensive queries merely to
measure performance.

## 12. Save the evidence

After reproducing the workload:

```gdscript
performance_sampler.save_report(
    "user://performance_report.json"
)
```

Keep the report with:

```text
commit/build identifier
hardware
profile name
scene/workload description
```

This is much more useful than a screenshot of "FPS = 52" with no context.

## 13. Compare targets deliberately

A game may support:

```text
Mid desktop / 1080p / 60
High desktop / 1440p / 120
```

and explicitly not support low-end integrated GPUs.

That is valid.

Do not optimize against hardware outside the product requirement solely because
it is possible to create a lower budget.

Instead:

1. validate the minimum supported target;
2. keep reasonable headroom there;
3. validate the recommended target;
4. create additional profiles only if the product actually promises them.

If a low-end target is added later, create a new profile and measure what breaks.
Do not retroactively assume current budgets represented it.

## 14. Profile networking with Godot first

The performance module does not pretend to know every byte sent by every
`MultiplayerPeer`.

For high-level multiplayer traffic, start with:

```text
Debugger > Network Profiler
```

It reports communicating nodes and network interactions/bandwidth for the
high-level multiplayer API.

A later networking iteration can expose Nucleus-observed application counters
through `register_probe()`, but those counters must be labeled honestly when
they do not represent total transport traffic.

## 15. Editor versus exported debug build

The editor can affect performance through:

```text
editor overhead
embedded game behavior
debug tooling
window/focus behavior
```

Use the editor for fast iteration.

For a performance decision that matters to shipping hardware, reproduce the same
workload in a representative exported debug build as well.

The module defaults to debug-only because several native monitors are not
available in release builds.

## 16. Avoid observer effect

Sampling defaults to every 0.5 seconds.

Do not turn every probe into per-frame work.

Do not run the full Godot Profiler continuously during normal development and
then treat that performance as unprofiled runtime.

Use:

```text
lightweight monitoring continuously when useful
deep profiler captures only around the investigation
```

## 17. Recommended workflow from day one

A practical loop is:

```text
Define actual target
↓
Run representative workload
↓
Watch Nucleus panel/history
↓
Mark important transitions
↓
A budget/trend looks suspicious
↓
Open the native specialist profiler
↓
Find the real bottleneck
↓
Change one thing
↓
Repeat identical workload
↓
Compare evidence
```

This keeps optimization evidence-driven from early development without turning
the project into a permanent synthetic benchmark.

## Common mistakes

Avoid:

- inventing low-end budgets for hardware the game does not support;
- optimizing draw calls because a blog post gave a universal number;
- treating FPS alone as enough evidence;
- profiling only an empty scene;
- changing physics tick rate before inspecting bodies/pairs/time;
- replacing Godot navigation before checking request/avoidance policy;
- leaving expensive custom probes running every frame;
- treating editor results as the only shipping-hardware evidence;
- enabling detailed profiling permanently;
- letting an automatic tool change gameplay/quality to satisfy a budget.

## Technical contract

See:

[`../../modules/performance.md`](../../modules/performance.md)
