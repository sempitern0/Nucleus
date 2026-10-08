# Audio, Save, Scene Flow, and Localization Contract

## Audio

`NucleusAudio` composes bus preferences, music and a pooled non-positional one-shot
surface around Godot's AudioServer/AudioStreamPlayer APIs. Godot's bus layout
remains authoritative.

`NucleusAudioCue` owns reusable one-shot data including relative `voice_priority`.
When the one-shot pool is saturated, equal priorities preserve oldest-first
recycling; a lower-priority incoming voice may be rejected rather than stealing a
more important active voice. Positional AudioStreamPlayer2D/3D ownership remains
scene/game policy.

## Save

`NucleusSave` owns document format, validation, codecs, storage, integrity,
migrations and slot policy. `NucleusSaveSession` owns scene-level coordination of
explicit capture/restore participants.

Participants return save-safe plain data. The global service never scans the
SceneTree or imports gameplay types.

For large participant sets, `NucleusSaveCaptureJob` and incremental save helpers
spread capture across rendered frames while keeping callbacks on the main thread.
Lifecycle saves on pause/quit remain synchronous.

## Scene Flow

`NucleusSceneFlow` owns application-level scene replacement, threaded loading,
progress, PackedScene preflight, transition presentation and failure/rollback
reporting. It keeps the outgoing scene alive until the destination is loadable and
instantiable.

For a single scene replacement, use Scene Flow directly. For a larger explicit
resource bundle, compose `NucleusResourceLoadQueue`, then hand a retained
`PackedScene` to `change_scene_to_packed()`.

## Localization

`NucleusLocalization` remains a thin facade around `TranslationServer` and locale
metadata. Translation resources and actual localized content remain Godot/game
owned.

## Boundaries

- settings preferences do not belong in save-game payloads;
- save failures remain explicit `NucleusSaveResult` values;
- audio cues do not choose game-specific content policy;
- scene-flow failures are not converted into a global EventBus by default;
- locale selection does not create a second translation database.
