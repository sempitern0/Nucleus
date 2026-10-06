# Nucleus Deprecation Policy

## Purpose

Deprecation makes intentional public-API evolution visible without preserving
obsolete abstractions indefinitely.

Nucleus does not maintain compatibility aliases merely because an older
Barebone or Nucleus implementation once exposed a name.

## What can be deprecated

Deprecation applies to public contracts such as:

```text
public Nucleus class_name identifiers
documented public methods
documented signals
required Autoload names
exported properties with serialized meaning
documented settings/save contracts
documented reusable scene/resource entry points
```

Private implementation details are changed directly.

## Before 1.0

Nucleus is currently pre-1.0. Breaking changes may occur in a MINOR version.
When practical:

1. mark the old API as deprecated in its technical documentation;
2. provide the replacement API;
3. document migration where a commonly used contract changes;
4. preserve the old contract through at least one subsequent prerelease or
   minor development cycle;
5. remove it only after the replacement path is clear.

This grace period is a goal, not a hard pre-1.0 guarantee. Early production use
may expose contracts that are actively harmful to preserve.

## From 1.0 onward

For stable public API:

1. deprecate in a MINOR release;
2. keep the deprecated contract functional for at least that release line;
3. document migration;
4. remove it only in a MAJOR release.

Security, data-loss, or engine-compatibility problems may justify faster
removal. Such exceptions must be explicit in the affected technical/release
documentation.

## Runtime warnings

Use runtime/editor warnings only when they are actionable, emitted at a useful
boundary, unlikely to spam every frame, and able to identify the replacement.

## Serialized data

Renaming exported properties, Resources, settings keys, or save fields can
outlive source-level APIs.

Where Nucleus owns persisted data, use an explicit migration path when feasible.
Save-data schema migration is governed by the save system and must not rely only
on source-level aliases.

## Removal checklist

Before removing a deprecated public contract:

- search documentation and examples;
- search tests;
- update migration guidance;
- update the relevant version;
- ensure CI is green without the old API.
