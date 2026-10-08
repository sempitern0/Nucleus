# Save Quickstart

Nucleus separates global storage/format policy from scene-owned game-state capture.

## Choose the entry point

Use `NucleusSave` when you already have a plain-data payload. Use
`NucleusSaveSession` when several systems own independent capture/restore state.

```text
GameSession
├── SaveSession : NucleusSaveSession
├── Player
├── Inventory
└── WorldState
```

Register explicit participants:

```gdscript
save_session.register_participant(
	&"player",
	player.capture_state,
	player.restore_state,
)
```

The save service never scans the SceneTree to discover gameplay state.

## Save-safe data

Prefer stable plain data:

```text
bool / numbers / strings
arrays / dictionaries
stable IDs
explicit snapshots
```

Do not persist live Nodes, Callables, transient instance IDs or translated display
strings as authoritative state.

## Manual / quick / autosave

The synchronous methods remain:

```text
save_manual
save_quick
autosave
```

They are appropriate for small/medium snapshots and lifecycle boundaries that
must complete immediately.

## Continue / resume the newest snapshot

When a Continue action should restore whichever successful snapshot is newest,
use:

```gdscript
var result := save_session.load_latest()
```

By default Nucleus considers:

```text
autosave
quicksave
manual
```

but timestamp wins before kind preference. The kind list only breaks an exact
timestamp tie.

To restrict the eligible kinds:

```gdscript
var result := NucleusSave.load_latest(
	"slot_1",
	PackedInt32Array([
		NucleusSaveTypes.Kind.MANUAL,
		NucleusSaveTypes.Kind.AUTOSAVE,
	]),
)
```

New save documents store microsecond update timestamps so rapid manual/autosave
sequences do not collapse into the same whole second. Older documents remain
compatible through whole-second fallback.

See [`../components/save_resume.md`](../components/save_resume.md).

## Large participant sets

When capture itself causes a visible spike, create a bounded capture job:

```gdscript
var job := save_session.create_capture_job()

while not job.is_completed():
	job.step(8)
	await get_tree().process_frame

var payload := job.take_snapshot()
```

Or use:

```gdscript
var payload := await save_session.capture_snapshot_incremental(8)
```

Convenience incremental save methods are also available for manual, quick and
explicit autosave flows.

Capture callbacks may touch Nodes, so Nucleus keeps them on the main thread. A
participant registered after a job starts belongs to the next snapshot.

Application pause/quit autosaves intentionally stay synchronous because another
rendered frame may never arrive.

## Restore order and late binding

When one participant depends on another, register/restore the dependency first
when order matters. Loaded payload remains pending so participants that register
after `apply_snapshot()` can still receive their state.

Hands-on: [`tutorials/save_system.md`](tutorials/save_system.md).
