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

## Scene flow

`NucleusSceneFlow` owns application-level scene transitions. It should be the
single integration point for transition sequencing and scene replacement where
projects need more than a direct `SceneTree.change_scene_to_*()` call.

Individual scenes should not become persistent solely to coordinate transitions.

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

Scene transition failure should not be converted into an EventBus event unless a
project has a genuinely decoupled subscriber requirement.

## Extension rule

Add codecs, migrations, or save policies behind existing save interfaces. Add
audio behavior by composing cues/services. Add locale metadata around
`TranslationServer`; do not build a second localization database.
