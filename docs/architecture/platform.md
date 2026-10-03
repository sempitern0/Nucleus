# Nucleus Platform and Paths

Target engine: Godot 4.7.x.

## Goal

Platform-specific behavior is expressed through Godot capabilities rather than
hardcoded operating-system filesystem paths or scattered string comparisons.

Two stateless classes provide this policy:

```text
NucleusPlatform
NucleusPaths
```

Neither is an Autoload.

## NucleusPlatform

`NucleusPlatform` wraps application-level capability queries that are shared by
multiple Core modules.

Examples:

```gdscript
NucleusPlatform.is_web()
NucleusPlatform.is_mobile_host()
NucleusPlatform.supports_threads()
NucleusPlatform.supports_programmatic_quit()
NucleusPlatform.uses_managed_window_mode()
NucleusPlatform.is_user_data_persistent()
```

The implementation delegates to `OS.has_feature()`, `OS.get_name()`, and
`OS.is_userfs_persistent()`.

The goal is not to hide Godot. The goal is to keep decisions such as
"window modes are managed on Web/mobile" in one place.

## NucleusPaths

Persistent application data derives from:

```gdscript
OS.get_user_data_dir()
```

Nucleus then creates project-specific subdirectories:

```text
<user data directory>/
├── logs/
├── saves/
└── settings/
    └── settings.cfg
```

No platform-specific host path is hardcoded.

Examples:

```gdscript
NucleusPaths.logs_directory()
NucleusPaths.saves_directory()
NucleusPaths.settings_file()
```

## Resource paths are different

`res://` remains the correct abstraction for project resources:

```text
scenes
textures
audio
Resources
scripts
```

Scene Flow therefore accepts `res://...` scene paths and loads them through
`ResourceLoader`.

Persistent user data and packaged project resources solve different problems
and deliberately use different Godot abstractions.

## Web

On Web, `OS.get_user_data_dir()` points to a browser-managed virtual filesystem.

Persistence may depend on browser IndexedDB/cookie availability. Games can query:

```gdscript
NucleusPlatform.is_user_data_persistent()
```

and decide whether to warn users about unavailable durable saves.

## Cross-platform rule

Core code should prefer:

```text
capability query
```

over:

```text
if Windows ...
elif Linux ...
elif Web ...
```

unless behavior truly depends on one named platform rather than a capability.
