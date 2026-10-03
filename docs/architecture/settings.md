# Nucleus Settings Architecture

Target engine: Godot 4.7.x.

## Goal

Settings provides a small, typed and editor-friendly API for application
preferences without coupling GUI controls to persistence or engine APIs.

## Architecture

```text
SettingDefinition Resources
          │
          ▼
 NucleusSettingsService
    │             │
    │             └── ConfigSettingsRepository ── user://settings/settings.cfg
    │
    ├── signals ──► Runtime appliers ──► Godot runtime APIs
    │
    └── API ◄──── Settings UI bindings / Core modules
```

The runtime value exists in exactly one place: `NucleusSettingsService`.

Setting Resources contain metadata only. They are safe to reuse from multiple
controls and scenes because UI changes never mutate the Resource.

## Why `NucleusSettings` is an Autoload

Settings owns persistent application-lifetime preferences that survive scene
changes and must be flushed during application pause and graceful shutdown.

## Public API

Typical code:

```gdscript
var vsync_mode: int = NucleusSettings.get_int(
	NucleusSettingIds.DISPLAY_VSYNC_MODE
)

NucleusSettings.set_value(
	NucleusSettingIds.GRAPHICS_MAX_FPS,
	120,
)
```

Structured preferences can use a generic dictionary definition. The Settings
module persists the Variant but does not interpret its domain-specific schema.

Input uses this for:

```text
input/bindings
```

This keeps the dependency direction:

```text
Settings ◄── Input
```

and never:

```text
Settings ──► Input
```

## Definitions and runtime state

Barebone's `GameSetting` Resource stored both definition metadata and mutable
runtime value. Nucleus deliberately separates them:

```text
.tres definition               runtime service
------------------             ---------------
section                        active value
key                            dirty state
default                        persistence state
range/options
presentation metadata
```

## Persistence

The repository uses Godot `ConfigFile`, with temporary writes, a last-known
backup, corruption quarantine, schema metadata, and debounced normal saves.

Critical lifecycle events call `save_now()` synchronously.

The settings file is intentionally not encrypted. User preferences are not
secrets.

## Definition types

Current generic definitions:

```text
NucleusBoolSettingDefinition
NucleusIntSettingDefinition
NucleusFloatSettingDefinition
NucleusStringSettingDefinition
NucleusVector2iSettingDefinition
NucleusIntOptionSettingDefinition
NucleusDictionarySettingDefinition
```

`NucleusDictionarySettingDefinition` supports structured Core preferences while
remaining completely domain-agnostic.

## Built-in definitions

```text
display/window_mode
display/borderless
display/vsync_mode

graphics/max_fps
graphics/msaa_3d

input/bindings
input/vibration_enabled
```

## UI binding pattern

Nucleus uses composition instead of subclassing Godot controls.

Settings itself ships:

- `NucleusBoolSettingBinding`
- `NucleusRangeSettingBinding`
- `NucleusIntOptionSettingBinding`
- `NucleusResetSettingsBinding`

Domain-specific modules may add bindings on top of the same service. Input does
this for rebinding controls and prompt labels.

## Dependency direction

```text
NucleusApp
    ▲
    │ lifecycle signals
    │
NucleusSettings
    │
    ├── definitions
    ├── repository
    └── appliers
          ▲
          │
     higher Core modules
```

`NucleusApp` does not know that Settings exists.
Settings does not know which higher-level module owns a structured value.
