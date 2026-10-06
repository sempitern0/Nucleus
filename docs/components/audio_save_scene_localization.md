# Audio, Save, Scene Flow, and Localization Contract

## Scope

```text
core/audio
core/save
core/scene_flow
core/localization
```

These are cross-scene runtime services and therefore are part of the default
Autoload set.

## Audio

`NucleusAudio` composes the audio service, music service, and one-shot playback
pool around Godot's audio buses and `AudioStreamPlayer` nodes.

`NucleusAudioCue` is reusable cue data. `NucleusAudioBuses` provides the built-in
bus identifiers shipped with the template.

Godot's audio bus layout remains authoritative; Nucleus does not implement a
parallel mixer.

Use one-shot pooling for transient SFX instead of repeatedly constructing and
destroying players.

## Save system

`NucleusSave` owns save infrastructure, not game-specific serialization.

The save stack separates:

```text
session/service
profile/policy
document/result model
codec registry
binary/text/JSON codecs
storage/repository/paths
validation
integrity/security
migrations
autosave
```

Game systems supply serializable data through their own capture/restore
contracts. The save service decides how the document is encoded, protected,
migrated, backed up, and stored.

Encryption/integrity credentials are runtime secrets and must not be committed
inside reusable Resource assets or export credentials.

Save files live under writable `user://` paths, never `res://`.

## Scene Flow

`NucleusSceneFlow` owns application-level scene replacement and its observable
lifecycle. Godot `SceneTree`, `ResourceLoader`, and `PackedScene` remain the
engine source of truth.

The service adds reusable policy around them:

```text
request admission / busy state
threaded loading with synchronous fallback
load progress
PackedScene preflight instantiation
optional screen-space transition presentation
switch watchdog
explicit failure diagnostics
best-effort rollback when a switch loses the current scene
return-to-previous-scene convenience
```

### Transaction boundary

A file-backed target is loaded as a `PackedScene` and instantiated before the
current scene is removed.

This means the common failure cases remain safe:

```text
missing target
wrong resource type
parse/load failure
missing dependency that aborts resource loading
PackedScene with no instantiable root
custom transition overlay that cannot start
```

The outgoing scene remains current when those failures occur.

Only a successfully prepared Node is handed to:

```gdscript
SceneTree.change_scene_to_node()
```

This uses Godot's native ownership and replacement semantics instead of
reimplementing the scene tree.

### Visual transitions

Visuals are optional. A transition is described by:

```text
NucleusSceneTransitionProfile
```

The built-in temporary `NucleusSceneTransitionOverlay` supports:

```text
fade
curtain, horizontal or vertical
flash
canvas-item shader progress
```

The supplied tile shader is an example, not a required style. Projects can
assign another `Shader` or a custom `overlay_scene` derived from
`NucleusSceneTransitionOverlay`.

Scene Flow owns only the sequencing contract:

```text
load + cover
    -> target prepared + screen covered
    -> native scene switch
    -> transition_completed
    -> reveal
    -> transition_finished / idle
```

Transition UI is created under the root viewport only for the duration of the
change, so it survives replacement without forcing the game world to persist.

### Failure reporting

The original signal remains:

```text
transition_failed(path, error)
```

For diagnosis use:

```text
transition_failed_detailed(details)
get_last_failure()
```

The detail dictionary records:

```text
target path
previous path
rollback path
failure stage
Error value + name
```

Presentation failure after a successful scene switch is reported separately by
`transition_visual_failed`; it does not pretend that the new gameplay scene
failed to load.

### Rollback limits

Most failures happen before the switch and require no rollback because the old
scene never left the tree.

If a switch is accepted but the expected `scene_changed` completion does not
materialize, Scene Flow uses a watchdog and can reload:

```text
fallback_scene_path
    or, when omitted,
the previous file-backed scene
```

This is best-effort recovery. It recreates the scene from its resource and does
**not** reconstruct unsaved runtime state from the former instance.

Godot also cannot classify an arbitrary error printed by a destination scene's
`_ready()` or later gameplay code as a failed scene transaction. When a game
knows that its own initialization failed after the switch, it may explicitly
call:

```gdscript
NucleusSceneFlow.return_to_previous_scene()
```

or route to a known safe scene.

## Localization

`NucleusLocalization` is a stateless facade over `TranslationServer`.

Locale catalogs/definitions provide metadata and resolution. The engine remains
responsible for translations and the active locale.

UI localization bindings should observe the locale rather than caching
translated strings as permanent data.

## Failure boundaries

Storage, decoding, integrity, and migration failures must remain explicit save
results/errors. Network or platform availability is not silently inferred from a
save failure.

Scene transition failures remain owned by Scene Flow. Do not convert them into a
global EventBus event unless a project genuinely needs a decoupled subscriber.

## Extension rule

Add codecs, migrations, or save policies behind existing save interfaces. Add
audio behavior by composing cues/services. Add locale metadata around
`TranslationServer`; do not build a second localization database.

For Scene Flow, add presentation by supplying a transition profile, shader, or
custom overlay. Keep map selection, checkpoints, session state, retry policy,
and game-specific fatal-error UX in the consuming game.
