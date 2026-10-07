# Runtime Efficiency Finishing Contract

Target baseline: Nucleus 0.20.x.

This contract closes the current general optimization pass outside terrain and
world streaming. It covers three residual sources of churn:

```text
non-positional audio voice pressure
bursty UI refreshes
large save-participant capture spikes
```

The systems remain explicit and do not introduce another global optimization
manager.

## Audio voice budgeting

`NucleusAudioOneShotPool` still grows from `initial_players` to `max_players`.
When capacity is exhausted, each request now carries an integer voice priority.

The default is:

```text
voice_priority = 0
```

so existing content preserves the former behavior: equal-priority voices recycle
the oldest active player.

When priorities differ, the pool selects the oldest voice among the lowest
active priority. A new request may replace that voice only when its priority is
greater than or equal to the victim priority. Otherwise the request returns
`null` and emits `voice_rejected`.

A successful replacement emits:

```text
voice_stolen(previous_priority, new_priority)
```

`NucleusAudioCue.voice_priority` lets authored cues carry this policy. Direct
playback may pass the final optional argument to:

```gdscript
NucleusAudio.play_one_shot(
    stream,
    NucleusAudioBuses.SFX,
    1.0,
    1.0,
    0.0,
    25,
)
```

Priority values are relative project policy. Nucleus deliberately does not
hard-code "dialogue", "weapon", "ambient" or genre-specific tiers.

This budget only covers the shared non-positional one-shot pool. Positional
`AudioStreamPlayer2D/3D` ownership remains scene/game policy.

## UI refresh coalescing

Nucleus UI remains signal-driven. Polling every frame is still discouraged.
However, several signals may fire in one operation and cause repeated writes to
the same Controls before the frame is presented.

`NucleusUIRefreshCoalescer` collapses those bursts:

```text
signal A ─┐
signal B ─┼→ request_refresh()
signal C ─┘
              ↓ deferred once
          refresh_due
```

Example:

```gdscript
source.value_changed.connect(coalescer.request_refresh)
source.limits_changed.connect(coalescer.request_refresh)
coalescer.refresh_due.connect(_refresh_hud)
```

`flush_now()` preserves an explicit synchronization escape hatch.

`NucleusUIResourceLoadBinding.coalesce_progress_updates` applies the same idea to
high-frequency loading progress. It defaults to `false` so existing immediate
presentation timing does not change silently. Start/finish lifecycle updates
remain immediate even when progress coalescing is enabled.

Do not coalesce input focus, confirmation, modal ownership or other semantics
where one-frame latency changes interaction correctness.

## Save capture budgeting

Save serialization and storage remain owned by `NucleusSave`. Gameplay state
capture remains owned by explicit `NucleusSaveSession` participants.

Capture callbacks may touch Nodes and must therefore stay on the main thread.
Nucleus does not move arbitrary gameplay capture onto worker threads.

`NucleusSaveCaptureJob` instead snapshots the registered participant callbacks
and exposes bounded steps:

```gdscript
var job := save_session.create_capture_job()

while not job.is_completed():
    job.step(8)
    await get_tree().process_frame

var payload := job.take_snapshot()
```

A participant registered after job creation belongs to the next snapshot. A
captured Callable that becomes invalid before its step is skipped safely.

For the common path, use:

```gdscript
var payload := await save_session.capture_snapshot_incremental(8)
```

or the convenience save methods:

```text
save_manual_incremental
save_quick_incremental
autosave_incremental
```

The integer budget is participants per rendered frame, not milliseconds. Games
with unusually expensive participant captures should split their own durable
state into sensible participant boundaries rather than hiding a huge capture
behind one callback.

Built-in application pause/quit autosaves intentionally remain synchronous.
Those lifecycle boundaries may not provide another rendered frame in which an
incremental capture can finish reliably.

## What this optimization pass now covers

Together with the preceding runtime optimization releases, Nucleus now provides:

```text
staggered low-frequency update scheduling
explicit activity gating
incremental object-pool prewarming
Utility AI staggering
render and physics audits
first-use PackedScene warmup
audio one-shot voice budgeting
UI refresh coalescing
incremental save capture
performance sampling and regression comparison
```

The framework still avoids automatically rewriting scene structure, renderer
settings, physics policy, AI behavior, asset priorities or save boundaries.
Measure the consuming game and use these primitives only where evidence shows a
real cost.
