# High-leverage tooling candidates

This is an evidence queue, not a commitment to expand the template broadly.

Nucleus already covers most reusable runtime foundations. The next large gains
for new projects are more likely to come from reducing debugging, validation,
and reproduction time than from adding more generic gameplay systems.

## Priority 1 — Development command palette / debug shell

Potential owner:

```text
modules/development_tools/
```

High-value boundary:

```text
command registry
small in-game palette
argument parsing / history
project-owned command registration
```

Reusable commands can compose existing Nucleus owners for scene reloads,
settings, save inspection, performance report capture, input diagnostics, or
world-state inspection. Games register domain-specific commands such as spawn,
grant item, teleport, quest state, or encounter controls.

Do not turn this into a global cheat manager or duplicate gameplay APIs.

Expected leverage: **very high**. It removes repeated one-off debug UI and
shortens reproduce -> inspect -> retry loops across almost every project.

## Priority 2 — Scene / resource validation rules

Potential shape:

```text
NucleusValidationRule
NucleusValidationIssue
headless validator runner
optional editor entry point
```

Useful reusable checks include:

```text
duplicate authored persistent IDs
invalid catalog references
missing required InputMap actions
invalid performance profiles
broken optional-module wiring
unsafe data-mod configuration
scene ownership / lifecycle mistakes
```

The runner should be extensible so a game can add its own content rules and use
the same checks locally and in CI.

Expected leverage: **very high**. Moving errors from runtime/QA into import or CI
usually saves more time than another convenience abstraction.

## Priority 3 — Reproducible development scenario runner

A scenario should describe a repeatable workload rather than attempt full engine
determinism.

Potential responsibilities:

```text
open scene
apply known development settings
wait for warmup
mark authored phases
run for a bounded duration
capture performance report
capture screenshot
return pass/fail metadata
```

This composes naturally with Iteration 28 report comparison and can become the
bridge between local profiling and CI/lab regression runs.

Expected leverage: **very high** for performance, QA, and bug reproduction.

## Priority 4 — Development bug-report bundle

Create an explicit opt-in bundle containing selected development evidence:

```text
engine / OS / renderer fingerprint
Nucleus version
application version when available
recent Nucleus logs
performance report
screenshot
selected non-sensitive settings
optional game-owned repro metadata
```

Privacy and secrets must be explicit boundaries. Save files, account tokens,
platform identity, network credentials, and user paths should never be silently
included.

Expected leverage: **high** once more than one developer/tester is reporting
issues.

## Priority 5 — Resource-loading / stutter instrumentation

Nucleus SceneFlow already owns scene transition loading. Do not build a second
loader.

The useful missing layer is evidence around authored load events:

```text
threaded request duration
scene transition phases
large resource first-use
pipeline compilation near load boundaries
streaming trace markers
```

This should extend Performance / Diagnostics and SceneFlow rather than become a
new streaming framework.

Expected leverage: **high** for larger 3D projects, lower for small scene-based
games.

## Priority 6 — Semantic input session recording

Recording semantic gameplay actions can make intermittent bugs easier to
reproduce:

```text
action
pressed/released
strength
local player/device ownership
timestamp
```

This is not a promise of deterministic physics/world replay. Playback should be
described as input reproduction unless a consuming game provides deterministic
simulation guarantees.

Expected leverage: **medium-high**, but implementation risk is higher than the
priorities above.

## Lower-priority ideas

Avoid broad additions such as:

```text
generic quest framework
generic dialogue framework
universal behavior tree
universal streaming world manager
custom asset database
custom profiler
custom editor replacement
```

Those systems impose substantial game policy or duplicate Godot. They should
enter Nucleus only after multiple consuming games demonstrate the same reusable
boundary.
