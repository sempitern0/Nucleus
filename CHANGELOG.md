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
- Optional Persistent World State module with stable region/entity IDs,
  explicit state adapters, persistent removal, cross-scene reconciliation,
  runtime scene rematerialization, and SaveSession integration.
- Optional AI / Navigation module with Utility AI, context providers,
  considerations, TargetingAgent/FSM integration, efficient native
  NavigationAgent followers, avoidance handoff, and reusable patrol/wander.
- Optional online gameplay replication helpers for server-authoritative
  intents, sequence/rate admission, and interpolated 2D/3D transform
  snapshots while preserving native MultiplayerSpawner/Synchronizer.
- Optional provider-neutral Platform Services boundary with standalone
  fallback, local identity, capability discovery, and no storefront SDK
  dependency.
- Productization packaging moved to `scripts/package_release.py` so the
  source tool is not hidden by Visual Studio's generic `Release/` ignore.
- Root `AGENTS.md` guidance and static ownership checks that keep coding agents
  on existing Nucleus cursor and display-settings APIs instead of duplicating
  their lower-level Godot calls.

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
- Development version advances to `0.5.0-dev.1` for Persistent World State /
  Identity public APIs.
- Development version advances to `0.6.0-dev.1` for optional AI / Navigation
  public APIs.
- Development version advances to `0.7.0-dev.1` for the final pre-game
  online replication and Platform Services public APIs.
- Display settings now detect Godot editor game embedding before requesting an
  unsupported window-mode/window-flag transition and emit a useful diagnostic.

### Notes

- The first real game built on Nucleus is expected to provide evidence for API
  stabilization before a 1.0 release.
- Breaking changes before 1.0 must still be explicit in this changelog and the
  relevant migration notes.
- Godot 4.7 game embedding does not support fullscreen/window-mode changes;
  disable embedding or validate an exported/separate game window.
