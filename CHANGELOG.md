# Changelog

All notable Nucleus changes should be recorded in this file.

Nucleus follows Semantic Versioning as defined in
`docs/policies/versioning.md`.

There are no tagged Nucleus releases yet. Existing development history is
summarized under **Unreleased** until the first release is cut.

## [Unreleased]

### Added

- Reusable Core services for application lifecycle, settings, input, audio,
  save, scene flow, localization, diagnostics, platform integration, and
  utilities.
- Production-oriented UI composition and accessibility helpers.
- Cross-genre gameplay components for actions, attributes, status effects,
  movement, camera, combat, interaction, state, timing, pooling, targeting,
  AnimationTree integration, and game-feel feedback.
- Optional EventBus and networking modules.
- Editor configuration warnings and removable validation scenes.
- Dependency-free native GDScript regression tests.
- Static, documentation, headless, smoke-export, and GitHub Actions validation.
- Productization contracts for versioning, Godot compatibility, API stability,
  deprecation, installation, and release packaging.
- Reproducible source-template packaging with a release manifest and SHA-256
  checksum.
- `NucleusSmartDecal3D` for surface-normal-aligned native Godot decals with
  planar variation, fade, and optional `NucleusPoolable` release.
- `NucleusWindow` viewport screenshot capture and PNG/JPEG/WebP saving for
  marketing/development stills.
- `NucleusPaths.screenshots_directory()` as the default writable capture path.
- Optional scene-owned Inventory / Equipment module with immutable item
  definitions, UUID-backed runtime stacks, capacity/weight limits, save
  state, Attribute modifier integration, and GameplayAction adapters.
- Optional Probability / Loot module with weighted and independent chance
  rolls, guaranteed/unique entries, injectable deterministic RNG, runtime
  unique state, conditions, result amounts, and saveable LootRollers.

### Changed

- Nucleus is formally documented as a successor/rework of Barebone rather than
  a backward-compatible continuation.
- Godot 4.7.2-stable is the initial release-gated engine reference.
- The template version is independent from the consuming game's application
  version.
- Development version advances to `0.2.0-dev.1` for the new public world
  presentation APIs.
- Development version advances to `0.3.0-dev.1` for the optional Inventory /
  Equipment public APIs.
- Development version advances to `0.4.0-dev.1` for the optional Probability /
  Loot public APIs.

### Notes

- The first real game built on Nucleus is expected to provide evidence for API
  stabilization before a 1.0 release.
- Breaking changes before 1.0 must still be explicit in this changelog and the
  relevant migration notes.
