# Iteration 19 — Productization and First-Project Readiness

## Objective

Turn the CI-validated Nucleus baseline into a versioned, installable,
maintainable template that can be used as the foundation of a real game.

No new gameplay subsystem is introduced in this iteration.

## Audited base

Productization was prepared against:

```text
sempitern0/Nucleus
main
285ba33a81a001647c79e2b0aef10303039a9e4e
```

The corresponding Nucleus CI run completed successfully.

## Gap audit

Before this iteration:

| Requirement | State |
| --- | --- |
| top-level README | missing |
| license | missing |
| changelog | missing |
| semantic versioning policy | only a SemVer utility existed; no repository policy |
| Godot compatibility policy | target/pin existed but no support contract |
| deprecation policy | missing |
| installation instructions | scattered quickstarts; no template installation contract |
| API stability expectations | implicit architecture only |
| release packaging | smoke game exports existed; template packaging did not |

## Productization decisions

### Initial template version

```text
0.1.0-dev.1
```

This is intentionally pre-1.0. The baseline is broad and CI-validated, but it has
not yet been exercised by a full production game.

### License

Nucleus is distributed under MIT.

The previous Barebone repository did not expose a root license in the audited
state. Nucleus establishes its own explicit license and does not claim Barebone
API compatibility.

### Godot support

The initial release-gated engine is:

```text
Godot 4.7.2-stable
```

The general target remains the Godot 4.7 line, subject to the compatibility
policy.

### Distribution model

Nucleus remains a project template.

It is copied/vendored into a consuming game and may then diverge. It is not
converted into a Godot addon or hidden behind a package manager.

## Added contracts

```text
README.md
LICENSE
CHANGELOG.md
VERSION

docs/policies/versioning.md
docs/policies/godot_compatibility.md
docs/policies/api_stability.md
docs/policies/deprecation.md

docs/guides/installation.md
docs/guides/releasing.md
```

## Release packaging

`scripts/release/package_release.py` creates a source-template archive from
Git-tracked files only.

It emits:

```text
Nucleus-<version>.zip
Nucleus-<version>.zip.sha256
```

The archive receives a generated `RELEASE_MANIFEST.json` containing source
commit and per-file hashes.

`.github/workflows/nucleus-package.yml` exposes the same packaging process as a
manual workflow without automatically publishing a GitHub Release.

## CI integration

`scripts/ci/productization_audit.py` verifies that release-level contracts remain
present and internally coherent.

The normal Nucleus CI executes this audit before downloading Godot.

## First real project rule

After this iteration, the next evidence should come from using Nucleus in an
actual game rather than adding another speculative baseline subsystem.

When the game exposes friction, classify it as:

```text
Nucleus defect
Nucleus reusable API gap
optional module candidate
game-specific requirement
```

Only the first two categories should change the baseline automatically.

## 1.0 is deliberately deferred

Feature count is not the 1.0 gate.

A stable 1.0 should follow real-project evidence that:

- public APIs are durable;
- common extension points are sufficient;
- migrations/deprecations are practical;
- Godot compatibility upgrades are understood;
- release packaging has been exercised.
