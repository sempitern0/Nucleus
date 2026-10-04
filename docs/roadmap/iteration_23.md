# Iteration 23 — Optional Persistent World State / Identity

## Objective

Make persistent world behavior usable from the first production scene without
serializing SceneTree structure or coupling world objects directly to the global
save service.

## Audited base

Prepared read-only against:

```text
sempitern0/Nucleus
main
72806e55866f1c3de4cac86346ce8c365c1d7bf3
```

Iteration 22 Probability / Loot is present and validated by the user.

## Barebone reuse audit

Barebone contains generic save-file infrastructure through Vault, but no clear
reusable system that solves stable authored/runtime world identity across scene
replacement.

No Barebone world-state implementation is copied.

Nucleus uses its current:

```text
NucleusSaveSession
NucleusUuid
NucleusNodeUtils
NucleusSceneFlow-compatible scene lifetime
```

as the foundation.

## Core problem

A `.tscn` reload reconstructs authored defaults.

Persistence therefore needs to distinguish:

```text
identity
state
lifecycle/removal
runtime materialization
```

SceneTree paths are not stable identity.

Plain `queue_free()` cannot mean permanent destruction because scene unloading
also frees Nodes.

## Architecture

```text
NucleusWorldStateService
        ↓
NucleusWorldStateStore
        ↓
NucleusWorldRegion
        ↓
NucleusWorldEntity
        ↓
NucleusWorldStateAdapter
```

Built-in adapters:

```text
NucleusPropertyStateAdapter
NucleusNodeStateAdapter
NucleusTransform2DStateAdapter
NucleusTransform3DStateAdapter
```

## Identity model

```text
region_id + persistent_id
```

is the stable key.

Authored identities are generated/stored in scenes.

Runtime persistent identities are UUIDs assigned during
`NucleusWorldRegion.spawn_persistent()`.

Renaming/reparenting nodes therefore does not change save identity.

## Cross-scene lifetime

`NucleusWorldStateService` remains optional.

For complete level scene replacement, the game must intentionally own it outside
the replaced scene:

```text
persistent GameSession
```

or optional Autoload.

Nucleus does not add another mandatory global.

## State ownership

WorldEntity never performs arbitrary reflection over a subtree.

Adapters explicitly declare state slices.

`NucleusNodeStateAdapter` lets existing stateful Nucleus components plug into
world persistence without new dependencies.

## Persistent removal

Explicit:

```text
world_entity.remove_persistently()
```

marks the stable identity removed before freeing the target.

Plain `queue_free()` remains temporary/runtime destruction semantics.

## Runtime persistent scenes

WorldRegion can spawn a real PackedScene and record:

```text
generated UUID
PackedScene resource_path
adapter state
removed status
```

When the region is recreated, missing live dynamic records are rematerialized.

## Save integration

WorldStateService is one explicit `NucleusSaveSession` participant.

Before save capture it commits active regions.

On restore it reloads the store and reconciles currently live regions.

A fresh/reloaded world scene is still recommended after in-game save switching
because previously freed authored Nodes cannot be recreated generically without
reinstantiating their owning scene.

## Save format

Built-in transform adapters use arrays of numbers and remain JSON-compatible.

Custom Property/Node adapter state must respect the project's selected save
codec.

## Networking

Persistent identity is not network authority.

Online games should normally let the authority own WorldState mutations and
replicate resolved state through game networking.

## Version

Development version:

```text
0.4.0-dev.1
→
0.5.0-dev.1
```

## Validation

Headless tests cover:

```text
store capture/restore
persistent removal
property adapter round-trip
Transform3D JSON-safe round-trip
region commit/reconcile
SaveSession late participant binding
```

CI remains the parser/runtime/export acceptance gate.

## Next module

After Persistent World State, the natural next optional module is:

```text
AI / Navigation helpers
```

That module should wrap recurring NavigationAgent2D/3D orchestration and
decision/composition helpers without inventing a second navigation system or a
monolithic Enemy base class.
