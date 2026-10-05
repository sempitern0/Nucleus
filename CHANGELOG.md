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
- Seamless single-player keyboard/gamepad device hot-swap on a stable local
  input seat, plus reusable scene-owned controller connection/disconnection
  toast composition.
- `docs/guides/real_game_patterns.md` as a practical map from recognizable
  game-shaped problems to every baseline component group and optional module.
- A Nucleus-specific SVG project icon representing a stable core surrounded by
  composable systems.
- Optional Content Packs module for signed official patch/DLC PCKs with
  pre-mount signature/hash verification, SemVer compatibility, dependencies,
  entitlements, deterministic ordering, and process-lifetime registry.
- Data-only community mod validation/read APIs that never mount untrusted
  resource packs and default to a strict inert-file whitelist, bounded package
  sizes, traversal/symlink rejection, and store-only ZIP entries.
- Release-side `scripts/content_packs/sign_pack.gd` for binding an official PCK
  SHA-256 to its detached JSON manifest and RSA signature without shipping the
  private key.
- First-class TOUCH local-player seats, semantic virtual sticks/action buttons,
  touch-look composition, and keyboard/gamepad/touch hot-swap through the
  existing input contracts.
- `NucleusHaptics` for the existing vibration preference across gamepad rumble
  and handheld vibration.
- Optional mobile orientation and permission helpers while reusing
  existing application lifecycle, safe-area, and breakpoint components.
- Content-pack and mobile quickstarts/tutorials with explicit trust boundaries
  and device-agnostic InputMap examples.
- Static ownership guards for verified resource-pack mounting, handheld haptics,
  mobile orientation/permissions, and the untrusted data-mod code-loading
  boundary.
- Expanded root-viewport graphics settings for 3D render scale/scaling mode,
  screen-space AA, TAA, 2D MSAA, 3D MSAA, and debanding through the existing
  declarative settings catalog and display applier.
- `NucleusEnvironmentSettingsApplier` plus optional Environment setting
  definitions for SSAO, SSIL, glow, volumetric fog, SDFGI, and tonemapping while
  preserving scene ownership.
- Practical guides for extending settings, choosing project/rendering defaults,
  configuring graphics, and troubleshooting common integration problems.

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
- Development version advances to `0.8.0-dev.1` for secure Content Packs and
  the first mobile/touch public APIs.
- Development version advances to `0.9.0-dev.1` for expanded graphics settings
  and the public scene-owned Environment settings applier.
- Display settings now detect Godot editor game embedding before requesting an
  unsupported window-mode/window-flag transition and emit a useful diagnostic.
- Input documentation now treats `ui_*` actions as active UI-navigation
  semantics rather than universal gameplay commands; world/session behavior
  should use semantic gameplay actions such as `pause`.
- README and `AGENTS.md` now present the ownership model, CI state, open-source
  status, and evidence-driven extension rules more explicitly.
- Local-player input now treats touch as a first-class source and one-player
  hot-swap can move a stable seat between keyboard/mouse, gamepad, and touch.
- Platform capability helpers now expose Android/iOS, touchscreen, orientation,
  and handheld-haptics queries.
- The default settings catalog schema advances to 2 so existing persisted values
  are reconciled with the expanded reusable graphics surface.

### Security

- Untrusted community PCKs are explicitly outside the supported mod path.
  Community mods remain data-only and never reach `load_resource_pack()` or
  ResourceLoader through Nucleus APIs.
- Official resource packs are verified before mount using a detached public-key
  signature over the exact manifest plus the manifest-declared archive SHA-256.
- Trusted executable mod packs are disabled by default and require an explicit
  project policy opt-in.
- Private content-signing keys are release secrets and must never be committed or
  embedded in reusable project Resources/exports.

### Notes

- The first real game built on Nucleus is expected to provide evidence for API
  stabilization before a 1.0 release.
- Breaking changes before 1.0 must still be explicit in this changelog and the
  relevant migration notes.
- Godot 4.7 game embedding does not support fullscreen/window-mode changes;
  disable embedding or validate an exported/separate game window.
- Godot resource packs have no public runtime unmount counterpart; disabling or
  reordering mounted official packs takes effect on the next process start.
- Environment quality settings remain opt-in and scene-owned; the framework does
  not impose universal Low/Medium/High/Ultra quality bundles.
