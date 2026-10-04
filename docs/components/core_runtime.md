# Core Runtime Contract

## Scope

This document covers:

```text
core/application
core/platform
core/window
core/diagnostics
core/utils
```

These systems provide process-wide infrastructure and small stateless helpers.
They should not become a Service Locator for game-facing systems.

## Ownership and lifetime

`NucleusApp` is a project Autoload because application lifecycle events genuinely
span scene changes. Platform, path, window, logging, and general utility classes
are primarily stateless APIs and should be called directly.

Scene-owned gameplay systems must not reach into a global registry to discover
each other.

## Application lifecycle

The application layer owns process-level startup/quit behavior. Games should use
it for lifecycle concerns rather than duplicating platform-specific shutdown
handling in scenes.

It does not own gameplay state.

## Platform and paths

`NucleusPlatform` centralizes runtime capability/platform queries.

`NucleusPaths` centralizes writable `user://` locations and path normalization.
Project assets continue to use `res://`.

Prefer capability checks over scattered operating-system name comparisons.
Web-specific restrictions should be handled at the boundary where a feature is
requested.

## Window helpers

`NucleusWindow` contains stateless viewport/desktop-window calculations. Godot's
`Window` and `DisplayServer` remain the underlying source of truth.

## Diagnostics

`NucleusLog` is the stable logging facade. `NucleusFileLogger` integrates with
Godot's logger API when file capture is installed.

Logging is diagnostic infrastructure, not an event system.

## Utilities

The utility layer includes narrowly scoped helpers such as:

```text
arrays / dictionaries
nodes
files
time
UUID identity
semantic versions
random geometry
enum helpers
```

Use native Godot APIs directly when they already express the operation clearly.
A utility belongs here only when it removes repeated project code without hiding
important engine behavior.

## Thread/process assumptions

Unless an individual API explicitly documents otherwise, treat the application
and SceneTree-facing infrastructure as main-thread code. Pure value helpers may
be used wherever the Godot API they call is thread-safe.

## Extension rule

Add a helper when the operation is broadly reusable and stateless. Add an
Autoload only when cross-scene lifetime is intrinsic to the responsibility.
