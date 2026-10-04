# Nucleus API Stability Expectations

## Current stability level

Nucleus is usable but currently **pre-1.0**.

The existing public surface is intentionally documented and tested, but the
first production game may reveal abstractions that should change before a stable
1.0 contract is declared.

Pin the Nucleus version or commit used to start a game.

## Public API

Unless a technical document says otherwise, the following are public contracts:

```text
Nucleus-prefixed class_name types
mandatory default Autoload names and their documented public methods/signals
documented public methods and signals on reusable components/resources
documented exported properties whose values are serialized in scenes/resources
documented settings/save schema boundaries
documented reusable scene/resource entry points
```

Public does not mean immutable before 1.0. It means a change requires explicit
versioning, changelog, and migration consideration.

## Internal API

The following are not compatibility contracts by default:

```text
underscore-prefixed functions and fields
private scene child names
implementation-only script paths
tests and test helpers
CI and release scripts
validation fixtures
temporary roadmap internals
undocumented implementation resources
```

Internal code may change without deprecation when public behavior is preserved.

## File paths

Nucleus is a project template, so paths sometimes matter through `project.godot`
or serialized Godot resources.

Paths explicitly referenced by project configuration or public documentation are
treated as integration contracts. Other implementation paths should not be used
as an API when a `class_name`, resource, scene, or documented service exists.

## Autoload stability

The baseline Autoload names are:

```text
NucleusApp
NucleusSettings
NucleusInput
NucleusAudio
NucleusSave
NucleusSceneFlow
```

Changing/removing one is a public-contract change.

Optional modules do not become baseline dependencies merely because they expose
public Nucleus classes.

## Signals over hidden global coupling

Local signals are preferred public integration points for scene-owned systems.
The optional EventBus is not a compatibility substitute for direct component
contracts.

## Source ownership in a consuming game

Nucleus is intended to be copied into a game repository and then owned by that
project.

A consuming game may modify any source. Once it does, automatic upgrades from a
newer Nucleus release are not guaranteed. Upgrades should be selective merges
guided by the changelog and migration notes.

## 1.0 threshold

Nucleus should not declare 1.0 solely because the feature list is large.

A stable 1.0 is appropriate after:

- at least one real game has exercised the baseline;
- recurring API friction has been resolved;
- public/core boundaries have proven durable;
- Godot compatibility policy is stable;
- release and migration processes have been exercised.
