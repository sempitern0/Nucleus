# Releasing and Packaging Nucleus

## Release artifact

Nucleus releases are **source-template packages**, not exported games.

Game exports in CI are smoke tests that prove project exportability. They are
separate from the Nucleus release archive.

The packaging script intentionally lives directly under `scripts/`; generic
`Release/` ignore patterns from IDE templates must not hide source tooling.

Generate a package with:

```bash
python3 scripts/package_release.py
```

Default outputs:

```text
dist/releases/Nucleus-<version>.zip
dist/releases/Nucleus-<version>.zip.sha256
```

The package version comes from the root `VERSION` file.

## Package contents

The package is built from Git-tracked files only.

This prevents local caches, untracked experiments, credentials, game prototypes,
or editor state from accidentally entering a Nucleus release.

The archive excludes generated/cache/output directories such as:

```text
.git/
.godot/
.ci/
build/
dist/
__pycache__/
```

The archive contains a generated:

```text
RELEASE_MANIFEST.json
```

with:

- Nucleus version;
- source commit;
- dirty-state marker;
- Godot compatibility reference;
- file count;
- SHA-256 and size for every packaged source file.

ZIP member ordering and timestamps are normalized to make packages reproducible
for the same tracked content and file modes.

## Clean-tree requirement

Official packages require a clean Git working tree.

For local packaging experiments only:

```bash
python3 scripts/package_release.py --allow-dirty
```

Do not publish a dirty package.

## Validation

By default, packaging runs:

```text
scripts/ci/static_checks.py
scripts/ci/documentation_audit.py
scripts/ci/productization_audit.py
```

It does not duplicate the expensive Godot runtime/export CI.

An official release requires the corresponding commit to have a green
`Nucleus CI` run before packaging/publishing.

Use `--skip-validation` only when validation has already run in the same trusted
automation job.

## Manual GitHub package workflow

The repository includes:

```text
.github/workflows/nucleus-package.yml
```

It is `workflow_dispatch` only. It creates a versioned package artifact but does
not automatically publish a GitHub Release.

This separation prevents a tag typo or consuming game repository from
unexpectedly publishing releases.

## Stable release checklist

1. Confirm Nucleus CI is green on the target commit.
2. Update `VERSION` to the release version.
3. Move changelog entries from `Unreleased` into a dated version section.
4. Review Godot compatibility.
5. Review deprecations and migration notes.
6. Commit the release metadata.
7. Run CI again.
8. Run the package workflow or local package script.
9. Verify the generated `.sha256`.
10. Tag the exact commit as `v<VERSION>`.
11. Create the GitHub Release and attach the ZIP plus checksum.
12. Start the next `Unreleased` changelog section.

## Prereleases

Prerelease versions are valid:

```text
0.1.0-dev.1
0.1.0-alpha.1
0.1.0-rc.1
```

Use them when a game project needs a reproducible Nucleus snapshot before the
public API is ready for a stable release.

## Consuming-game releases

A game built on Nucleus owns its own versioning, export presets, store metadata,
signing, and release process.

Do not use the Nucleus template `VERSION` as the game's version.
