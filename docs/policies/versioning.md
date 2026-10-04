# Nucleus Versioning Policy

## Scope

Nucleus versions the reusable **template**, not the game created from it.

The source of truth is:

```text
VERSION
```

Do not couple the Nucleus version to a consuming game's
`application/config/version` or release number.

## Scheme

Nucleus uses Semantic Versioning:

```text
MAJOR.MINOR.PATCH
```

Prerelease identifiers may be used:

```text
0.1.0-dev.1
0.1.0-alpha.1
0.1.0-rc.1
```

Git tags use the same version with a `v` prefix:

```text
v0.1.0
v1.2.3
```

The tag version and `VERSION` must match exactly apart from that prefix.

## Before 1.0

The first real consuming projects are part of API discovery.

For `0.x` releases:

- PATCH means bug fixes and documentation corrections with no intentional
  public-contract break;
- MINOR may contain breaking public API changes;
- breaking changes must be called out in `CHANGELOG.md`;
- migration guidance is required when the change affects commonly used public
  contracts;
- deprecation periods are best-effort rather than guaranteed.

A consuming game should pin the exact Nucleus version or commit it started from.

## From 1.0 onward

After `1.0.0`:

- PATCH contains backward-compatible bug fixes;
- MINOR adds backward-compatible functionality and may introduce deprecations;
- MAJOR may remove deprecated APIs or otherwise break public contracts.

Changing the minimum supported Godot minor version is considered a compatibility
break after 1.0 unless the previously supported line remains release-gated.

## What drives a version bump

Public API is defined in `docs/policies/api_stability.md`.

Examples that require a version decision include:

```text
renaming/removing a public Nucleus class_name
renaming/removing a documented public method or signal
changing required Autoload names
changing exported property meaning or serialized representation
changing documented save/settings contracts
raising the minimum supported Godot version
changing required default project wiring
```

Private helpers, tests, CI scripts, implementation details, and undocumented
underscore-prefixed members do not independently require a compatibility bump.

## Changelog discipline

Before tagging a release:

1. update `VERSION`;
2. move the relevant `CHANGELOG.md` entries from `Unreleased` into a versioned
   section with the release date;
3. verify compatibility and deprecation documentation;
4. require a green Nucleus CI run;
5. generate the release package;
6. verify its SHA-256 checksum;
7. tag the exact packaged commit.

Do not reconstruct historical Nucleus versions from Barebone. Nucleus versioning
starts with its own explicit version contract.
