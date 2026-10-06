# Iteration 28 — Performance Trends / Regression Baselines

## Goal

Turn Performance / Diagnostics from a current-state HUD into a lightweight
regression workflow without building another profiler or benchmark service.

## Evidence

The first real dashboard run exposed two useful production facts:

```text
raw TIME_PROCESS can be misleading as a frame-budget decision source
stable 60 FPS needs historical pacing context, not one sampled number
```

After switching frame health to effective FPS and monotonic pacing windows, a
minimal Nucleus scene produced stable results around the target cadence. That
made history and comparison the next justified step.

## Delivered

```text
frame interval p50 metric
ordered metric-series API
30-second dashboard pacing history
P50 / P95 / MAX visualization
generic report metric summaries
report schema 3
NucleusPerformanceReportComparator
context-aware baseline comparison
regression / improvement classification
headless comparator coverage
```

The dashboard reuses sampler history. It does not create a second collector.

## Regression boundary

Comparison is deliberately contextual.

Nucleus surfaces mismatches for:

```text
operating system
renderer method
editor embedded vs standalone
configured target FPS
Godot major/minor version
```

Metric deltas are still returned, but mismatched captures are not presented as
strictly equivalent benchmarks.

## Default comparison policy

The convenience API defaults to relative thresholds of:

```text
warning  10%
critical 25%
```

These are tooling defaults, not product guarantees. A consuming game should use
its own tolerances for stable benchmark scenarios.

The comparator currently covers:

```text
effective FPS
frame pacing p95 / max
physics / navigation time
draw calls / rendered objects / primitives
video / static memory
node count
```

## Version

The development version advances to:

```text
0.11.0-dev.1
```

because the iteration adds public history/report-comparison APIs.

## Next evidence

Do not expand Performance / Diagnostics into a benchmark laboratory by default.
Future additions should be driven by real game friction.

The highest-value cross-project tooling candidates are now:

```text
development command palette / debug shell
scene and resource validation rules
reproducible gameplay scenario runner
resource-loading / streaming stutter traces
build/runtime fingerprint surfaced in bug reports
```

These should compose existing Nucleus owners rather than duplicating gameplay or
engine systems.
