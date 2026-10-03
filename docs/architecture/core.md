# Nucleus Core Architecture

Target engine: Godot 4.7.x.

## Purpose

Core contains infrastructure that remains valid regardless of genre, camera
perspective, dimensionality, content, or game rules.

A Core module may depend on Godot and lower-level Core modules. It must not
depend on gameplay code, examples, optional addons, or project-specific assets.

## Current modules

```text
core/
├── application/
├── audio/
├── diagnostics/
├── input/
│   ├── bindings/
│   └── local/
├── localization/
├── platform/
├── save/
├── scene_flow/
├── settings/
├── utils/
└── window/
```

## Autoloads

```text
NucleusApp
NucleusSettings
NucleusInput
NucleusAudio
NucleusSave
NucleusSceneFlow
```

Every Autoload owns a distinct application-lifetime responsibility.

Scene-owned systems such as local-player assignment and save-session snapshot
capture remain regular Nodes.

## Dependency direction

```text
Godot APIs
    ▲
    │
Platform / Paths / Diagnostics / Window
    ▲
    │
NucleusApp
    ▲
    │ lifecycle
    │
NucleusSettings
    ▲
    ├──────────────┐
    │              │
NucleusInput   NucleusAudio
                   │
NucleusSave        │
                   │
NucleusSceneFlow ──┘
```

The diagram describes allowed infrastructure direction, not a requirement that
every module depend on every lower layer.

Gameplay sits above Core.

## Design rules

1. **No gameplay types in Core.**
2. **Autoloads require application-lifetime state or cross-scene ownership.**
3. **No global EventBus by default.**
4. **No Service Locator.**
5. **No legacy compatibility layer.**
6. **Public global class names use the `Nucleus` prefix.**
7. **Composition over inheritance for game-facing systems and UI bindings.**
8. **Critical persistence work is synchronous at lifecycle boundaries.**
9. **Project files define defaults; user data stores overrides/state.**
10. **Presentation metadata is not persistence data.**
11. **Platform decisions use Godot capability APIs.**
12. **Persistent data paths derive from `OS.get_user_data_dir()`.**
13. **Packaged resources continue to use `res://` + `ResourceLoader`.**
14. **Utilities stay narrow and never become another OmniKit-style catch-all.**

## Patterns currently used

### Observer

Lifecycle, Settings, Input, Save, and Scene Flow expose narrow signals instead
of importing their consumers.

### Facade

Small stable APIs sit over Godot facilities where they improve ergonomics
without replacing the engine.

### Adapter

File logging and UI binding components adapt Godot-native APIs.

### Repository

Settings and Save isolate filesystem persistence behind repositories.

### Strategy

Save codecs separate binary, text Variant, and JSON representations.

### Migration Pipeline

Save schema evolution is explicit and ordered.

### Snapshot + Override

Input stores only user binding overrides over project InputMap defaults.

### Composition Root ownership

Local multiplayer input and save snapshot capture are scene-owned because their
state belongs to one game session.

## Barebone concepts retained

Retained and redesigned:

- Application lifecycle and quit interception.
- Window helpers.
- File logging.
- Resource-driven Settings.
- Lightweight settings/input UI binding.
- Semantic input actions and gamepad support.
- Local multi-controller routing.
- Audio buses, one-shot pooling, and music crossfades.
- Save format strategies, slots, backups, autosave, encryption, and schema
  evolution.
- UUID, SemVer, shuffle-bag, collection, filesystem, time, node-traversal,
  enum, and random-geometry utilities selectively rescued from OmniKit.

Not carried into Core:

- `Globals`.
- `GlobalEvents`.
- Global player state.
- Gameplay collision constants.
- Generic EventBus.
- Generic Service Locator.
- Inventory, weapons, interactions, DLC, Terrainy, or other gameplay systems.


## Localization

Localization is Core infrastructure but does not add another Autoload.
`TranslationServer` owns the active runtime locale while `NucleusSettings`
persists the player's locale preference through a small settings applier.

The default locale catalog is presentation metadata only. Loaded Godot
translations remain the source of truth for supported languages.
