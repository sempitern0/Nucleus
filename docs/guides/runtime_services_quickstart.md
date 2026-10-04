# Runtime Services Quickstart

## Audio

Use `NucleusAudio` for shared audio/music/one-shot behavior and keep bus names
aligned with `NucleusAudioBuses`.

Create reusable `NucleusAudioCue` Resources for repeatable cue policy.

Do not create a fresh AudioStreamPlayer for every transient SFX when the
one-shot pool already solves that lifecycle.

## Save

Use `NucleusSave` infrastructure for encoding/storage/security/migration policy.

Your game should:

1. capture stable plain data from its systems;
2. place that data in its save payload/document contract;
3. ask the save service to persist it;
4. restore game state through game-owned restore methods.

Do not persist live Node references.

Keep encryption/integrity secrets outside committed Resources.

## Scene flow

Use `NucleusSceneFlow` when a transition needs sequencing or shared transition
policy. For a trivial isolated scene change, Godot's SceneTree remains valid.

## Localization

Store translation keys/source data and let `TranslationServer` +
`NucleusLocalization` resolve the active locale.

Do not serialize translated display strings as durable game data.

## Ownership reminder

These services are already default Autoloads because their responsibilities are
cross-scene. Game-facing gameplay components should remain scene-owned.
