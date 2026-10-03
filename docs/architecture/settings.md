# Nucleus Settings Architecture

Target engine: Godot 4.7.x.

## Goal

Settings is the first stateful Core module after Application. It provides a
small, typed and editor-friendly API for game options without coupling GUI
controls to persistence or engine APIs.

## Architecture

```text
SettingDefinition Resources
          │
          ▼
 NucleusSettingsService
    │             │
    │             └── ConfigSettingsRepository ── user://settings/settings.cfg
    │
    ├── signals ──► DisplaySettingsApplier ──► Godot runtime APIs
    │
    └── API ◄──── Settings UI bindings
```

The runtime value exists in exactly one place: `NucleusSettingsService`.

Setting Resources contain metadata only. They are safe to reuse from multiple
controls and scenes because UI changes never mutate the Resource.

## Why `NucleusSettings` is an Autoload

Settings satisfies the Nucleus Autoload rule:

- It owns persistent cross-scene state.
- The state exists for the lifetime of the application.
- Unrelated scenes need to read and update it.
- It must flush during application pause and graceful shutdown.

This is application infrastructure rather than gameplay state.

## Public API

Typical code:

```gdscript
var vsync_mode: int = NucleusSettings.get_int(
    NucleusSettingIds.DISPLAY_VSYNC_MODE
)

NucleusSettings.set_value(
    NucleusSettingIds.GRAPHICS_MAX_FPS,
    120
)
```

Reset operations:

```gdscript
NucleusSettings.reset_setting(
    NucleusSettingIds.DISPLAY_VSYNC_MODE
)
NucleusSettings.reset_section(&"graphics")
NucleusSettings.reset_all()
```

Settings are persisted automatically after a short debounce. Critical lifecycle
events call `save_now()` synchronously.

## Definitions and runtime state

Barebone's `GameSetting` Resource stored both definition metadata and the
mutable runtime value. Nucleus deliberately separates them:

```text
.tres definition               runtime service
------------------             ---------------
section                        active value
key                            dirty state
default                        persistence state
range/options
presentation metadata
```

This prevents shared mutable Resource state and makes two-way UI synchronization
predictable.

## Persistence

The repository uses Godot `ConfigFile` because it natively stores Variant values
in a readable INI-like format.

Write flow:

```text
runtime values
     │
     ▼
settings.cfg.tmp
     │
     ├── previous settings.cfg ──► settings.cfg.bak
     │
     ▼
settings.cfg
```

If the primary file cannot be parsed, it is quarantined and the backup is tried.
If neither can be loaded, defaults are used and a fresh file is written.

The settings file is intentionally not encrypted. Display, input, audio and
accessibility preferences are not secrets, and fake encryption based on public
project metadata adds complexity without meaningful confidentiality.

## Schema versioning

Every file stores:

```ini
[__nucleus]
schema_version=1
```

Additive changes require no migration:

- New setting: the catalog default is used and the file is rewritten.
- Removed setting: the unknown old value is ignored on the next load.
- Invalid value: the definition default is used and the file is rewritten.

Explicit migration objects should only be introduced when Nucleus first needs a
breaking rename or value transformation.

## UI binding pattern

Nucleus uses composition instead of subclassing Godot controls.

Example scene:

```text
CheckButton
└── NucleusBoolSettingBinding
```

The binding can use its parent automatically, so the only required Inspector
field is the setting Resource.

Available bindings:

- `NucleusBoolSettingBinding` for CheckBox, CheckButton and toggle Buttons.
- `NucleusRangeSettingBinding` for Slider, SpinBox and other Range controls.
- `NucleusIntOptionSettingBinding` for OptionButton.
- `NucleusResetSettingsBinding` for reset buttons.

This keeps themes, custom control subclasses and UI layout completely separate
from the Settings implementation.

## Built-in definitions

Iteration 02 ships a deliberately small universal catalog:

```text
display/window_mode
display/borderless
display/vsync_mode
graphics/max_fps
graphics/msaa_3d
```

Input and Audio will add settings through their own Core iterations rather than
making this module depend on those systems.

## Patterns used

### Repository

`NucleusConfigSettingsRepository` owns filesystem and ConfigFile concerns.
`NucleusSettingsService` does not know how an INI file is written.

### Observer

`setting_changed` and `settings_loaded` let runtime appliers and UI react
without the Settings service importing them.

### Definition/Instance separation

Resources describe a setting. The service owns the live instance value. This is
similar to separating immutable configuration assets from mutable game state.

### Adapter / Binding component

Small child Nodes adapt vanilla Godot controls to the Settings API. Controls do
not need Settings-specific subclasses.

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

UI bindings ──► NucleusSettings
```

`NucleusApp` does not know that Settings exists.
