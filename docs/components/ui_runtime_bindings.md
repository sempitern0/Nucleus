# UI Runtime Bindings Contract

Target engine: Godot 4.7.x.

## Scope

This contract covers scene-owned adapters that project existing Nucleus runtime
state into existing UI presentation components.

Public types:

```text
NucleusUIValuePoolProgressBinding
NucleusUIResourceLoadBinding
NucleusUISceneLoadBinding
```

They do not introduce UI authority, gameplay authority, a global HUD manager, or
another resource-loading owner.

## Ownership

Use the following direction:

```text
runtime owner
    NucleusValuePool / NucleusResourceLoadQueue / NucleusSceneFlow
        ↓ public signals and getters
scene-owned UI binding
        ↓
Control / NucleusUIProgressFeedback
```

The binding observes. It does not mutate gameplay state, choose destination
scenes, start retries, or decide when a loading panel should be visible.

## ValuePool progress binding

`NucleusUIValuePoolProgressBinding` maps the normalized ratio from one
`NucleusValuePool` into one `NucleusUIProgressFeedback`.

Use it for reusable numeric pools such as:

```text
health
shield
stamina
mana
fuel
oxygen
```

The source remains authoritative. The UI binding never applies damage, healing,
regeneration, limits, or overflow rules.

Typical scene composition:

```text
Player
└── Health : NucleusValuePool

HUD
└── HealthBar
    ├── Primary : ProgressBar
    ├── Trailing : ProgressBar
    ├── ProgressFeedback : NucleusUIProgressFeedback
    └── HealthBinding : NucleusUIValuePoolProgressBinding
```

Set:

```text
HealthBinding.source = Player/Health
HealthBinding.target = ProgressFeedback
```

`animate_changes` controls only presentation interpolation. `snap_initial`
prevents an unnecessary startup animation by default.

## Resource-load presentation binding

`NucleusUIResourceLoadBinding` observes one scene-owned
`NucleusResourceLoadQueue`.

It can drive:

```text
NucleusUIProgressFeedback
or a native Range
optional processed/total Label
optional current-item Label
```

The binding listens to the queue's existing public lifecycle:

```text
batch_started
progress_changed
item_started
batch_completed
batch_failed
batch_cancelled
```

It does not start a plan and does not decide how failures are handled.

When `progress_feedback` is assigned, it is the progress owner. `progress_target`
is only used when no progress feedback component is assigned, avoiding two
writers fighting over the same Range.

`animate_progress` defaults to `false`. ResourceLoader already reports changing
progress and repeatedly restarting UI Tweens can add unnecessary work and make a
loading bar lag behind the real state. Enable smoothing only when the consuming
presentation needs it.

The default count template is:

```text
{processed} / {total}
```

`NucleusLoadEntry.display_name` remains the source for the current item label.
Use localized/project-owned display metadata when that label is player-facing.

## Scene-load presentation binding

`NucleusUISceneLoadBinding` observes the existing `NucleusSceneFlow` Autoload.

It maps:

```text
NucleusSceneFlow.load_progress
    ↓
NucleusUIProgressFeedback or Range
```

It also emits local presentation lifecycle signals:

```text
loading_started(scene_path)
loading_finished(scene_path, succeeded)
```

Those signals are convenient for a scene-owned presenter to show/hide its own
loading panel without introducing a UI singleton.

The adapter intentionally does not render the raw scene path as player-facing
copy. A game may map the path to a localized destination name, tip, image, or
other presentation metadata.

## Static loading screens and scene changes

For a bootstrap/load-plan screen:

```text
Bootstrap
├── ResourceLoadQueue
└── LoadingUI
    ├── ProgressFeedback
    ├── CountLabel
    ├── ItemLabel
    └── ResourceLoadBinding
```

For a direct scene change:

```text
PersistentUIShell
└── LoadingUI
    ├── ProgressFeedback
    └── SceneLoadBinding
```

The same authored UI can use either adapter, but Nucleus does not require both
sources to be connected to one presentation simultaneously.

## Performance

Bindings are signal-driven and do not poll each frame.

Keep `animate_progress = false` for high-frequency load progress unless visual
profiling justifies smoothing. `NucleusUIProgressFeedback` itself remains the
owner of trailing bars and pulse effects.

## Failure boundary

Bindings never decide:

```text
retry
fallback scene
fatal error dialog
DLC download
save recovery
network reconnect
```

Those decisions belong to the coordinator that owns the corresponding runtime
operation.

## Godot 4.7 default audio bus startup warning

Nucleus references its default AudioBusLayout from `project.godot` using:

```text
res://default_bus_layout.tres
```

rather than a `uid://` value. Godot 4.7 can report an unrecognized UID for
resources resolved very early from project settings before its UID cache is
fully available. The AudioBusLayout resource may still keep its own UID; only
the early project-setting reference uses the stable resource path.

## Extension rule

Add another binding only when multiple projects repeatedly write the same signal
to presentation glue. Do not create a generic reflection/data-binding framework
or a UI service locator.
