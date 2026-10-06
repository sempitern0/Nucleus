# Nucleus agent contract

Nucleus is a reusable Godot project foundation. Coding agents working in this
repository act as maintainers of a template that will be copied into many games,
not as authors of one specific game.

Detailed contracts live under `docs/`. This file is the fast decision map.

## Core principles

1. **Godot-native first.** Use native Godot APIs when Nucleus does not already
   own the concern.
2. **Do not bypass a Nucleus owner.** When a concern has a stable Nucleus
   boundary, game-facing code uses that boundary instead of duplicating the
   lower-level engine call.
3. **Composition over inheritance.** Prefer scene-owned nodes, resources, and
   small adapters that compose with normal Godot nodes.
4. **Scene ownership by default.** Autoloads are reserved for genuinely
   cross-scene services.
5. **Production evidence before abstraction.** Add reusable behavior because a
   consuming game exposed repeatable friction, not because a generic feature
   could be imagined.
6. **Optional means optional.** Modules must not become hidden dependencies of
   the baseline.
7. **Public names are deliberate.** Public `class_name` identifiers use the
   `Nucleus` prefix and public-contract changes follow the versioning policy.
8. **Trust boundaries are code boundaries.** Never weaken a content-security
   boundary for convenience without an explicit public policy change and tests.

## Before editing

1. Inspect the current branch, affected files, and the latest implementation.
2. Search for an existing Nucleus public API before reaching for a lower-level
   Godot API.
3. Read the relevant contract in `docs/components/`, `docs/modules/`,
   `docs/guides/`, or `docs/policies/`.
4. Identify whether the behavior belongs to Core, an optional module, a reusable
   component, or the consuming game.
5. Make the smallest coherent change that fixes the observed problem.
6. Add or update tests for behavior and current-use documentation for public
   contracts when the change is notable.

Historical iteration notes and roadmap journals do not belong in the source
template. Use Git history, issues, pull requests, and release notes for history.

## Ownership map

| Concern | Preferred owner | Do not duplicate in game code |
| --- | --- | --- |
| Cursor mode | `NucleusCursor` | `Input.mouse_mode = ...` |
| Runtime settings | `NucleusSettings` + appliers | direct engine writes from UI |
| Scene transitions | `NucleusSceneFlow` | ad-hoc loading for app flow |
| Application quit/back | `NucleusApp` | platform-specific exit wiring |
| Input device state/rebinding | `NucleusInput` | physical-key logic in gameplay |
| Local player devices | `NucleusLocalInputSession` | global active-device ownership |
| Cross-device haptics | `NucleusHaptics` | scattered vibration policy |
| Audio routing already modeled | `NucleusAudio` | parallel bus policy |
| Save-game persistence | `NucleusSave` | unrelated `user://` save formats |
| Transient UI messages | scene-owned toast host | global notification singleton |
| Trusted DLC/PCK loading | Content Packs module | arbitrary `load_resource_pack()` |
| Community mods | data-only Content Packs API | ResourceLoader/untrusted PCK mount |
| Optional networking/game systems | matching `modules/*` contract | hidden baseline dependency |

The rule is not "wrap every Godot API". The rule is "do not bypass an existing
Nucleus owner".

## Input rules

Input code must distinguish **physical bindings**, **UI navigation actions**, and
**gameplay semantics**.

- Gameplay code consumes semantic actions such as `move_*`, `interact`,
  `primary_action`, `secondary_action`, or `pause`.
- `ui_accept`, `ui_cancel`, and other `ui_*` actions belong to active Godot UI
  navigation, dialogs, and menus.
- World/session scripts must not treat `ui_cancel` as a universal "leave game"
  action. A physical B/Circle button may also be bound to dodge, melee, interact,
  or another gameplay action.
- Gameplay pause/menu behavior uses a gameplay action such as
  `NucleusInputActions.PAUSE`, then lets the opened UI consume `ui_cancel`.
- A one-player `NucleusLocalInputSession` should hot-swap keyboard/mouse,
  gamepad, and touch ownership without replacing the stable local-player object.
- Runtime rebinding goes through `NucleusInput`; gameplay does not cache physical
  keys, button indices, or prompt strings.
- Touch controls feed the same semantic InputMap actions as other devices. Do not
  create a parallel mobile-only gameplay API when the existing action fits.
- UI actions are protected from rebinding by default. A project may explicitly
  enable `NucleusInput.allow_ui_action_rebinding`, but it must preserve a usable
  accept/cancel path.

The same physical button may legally participate in multiple actions. Context is
defined by the active consumer, not by assigning one global meaning to the
button.

## Content-pack and mod security rules

Treat external content as a trust boundary.

- **Never mount an untrusted community PCK/ZIP with
  `ProjectSettings.load_resource_pack()`.** A Godot resource pack can contain
  executable scripts, scenes, resources, native extensions, and overrides.
- Official PCKs must pass the Content Packs verification pipeline before mount:
  bounded manifest read, manifest validation, detached public-key signature,
  archive SHA-256, compatibility, entitlement when declared, and dependencies.
- Only public verification keys belong in the game. Private signing keys must
  remain outside the repository, exports, Resources, CI artifacts, and logs.
- Community mods use `NucleusDataModValidator` / `NucleusDataModPack`. Keep the
  extension whitelist minimal and consume untrusted data as bytes/text/JSON.
- Do not feed community-mod paths to `load()`, `preload()`, `ResourceLoader`,
  `GDExtensionManager`, `OS.execute()`, or another code-loading boundary.
- Validate game-specific data schemas and ranges after Nucleus package
  validation. Package safety does not make arbitrary economy/gameplay data sane.
- Resource-pack mounts have process lifetime. Do not pretend registry removal is
  an unload operation.
- Patches that replace base resources must mount during an explicit early boot
  phase before affected resources are preloaded.

Any proposal to support executable community mods must be a separate explicit
trust mode, disabled by default, with user consent and platform/distribution
policy review.

## Mobile rules

Mobile support composes native Godot APIs; there is no global MobileManager.

- Reuse `NucleusApp` lifecycle, `NucleusUISafeArea`, and
  `NucleusUIBreakpoints` before adding new platform abstractions.
- Use `NucleusPlatform` capability checks instead of scattering OS-name checks.
- Orientation policy is scene-owned. Responsive layout remains native Godot UI
  plus Nucleus safe-area/breakpoint helpers.
- Request dangerous permissions only at the user-visible feature boundary.
  Android permissions still need export-preset declarations.
- Provider SDKs, billing, notifications, analytics, and ads stay behind explicit
  project/provider adapters; they are not baseline Core dependencies.

## Settings rules

`NucleusSettings` stores user preferences. Settings appliers translate them into
runtime Godot state.

Do not make settings UI write `ProjectSettings`, `DisplayServer`, audio buses, or
viewport properties when an existing applier owns that behavior.

Godot editor game embedding does not support window-mode changes such as
fullscreen. Validate those settings with **Embed Game on Next Play** disabled or
in an exported/separate game window.

## UI rules

Nucleus UI is composition around native `Control` nodes.

- Use native focus/navigation behavior first.
- Keep modal, toast, and tooltip lifecycle scene-owned.
- Bridge Core signals into presentation through small bindings rather than
  making Core depend on UI.
- Respect `NucleusMotionPolicy` for reusable motion and feedback.
- Keep localization keys/data separate from permanently translated output.

## Animation rules

Keep Godot's animation and skeleton stack authoritative. Nucleus may adapt
existing gameplay state to `AnimationTree` or coordinate repeated lifecycle
glue, but it should not mirror `Skeleton3D`, retargeting, IK, constraints,
attachments, or physical-bone authoring in a parallel abstraction.

For 3D characters, keep the gameplay `CharacterBody3D` stable and treat imported
rigs/animations as presentation. Use native `SkeletonModifier3D`/IK and
`PhysicalBoneSimulator3D`; game rules still own movement, death, combat, and
network authority.

## Optional modules

Modules under `modules/` are opt-in. Before adding one to a consuming game:

1. confirm the game actually needs the capability;
2. read the module contract;
3. keep the dependency explicit in the scene/service that owns it;
4. do not move module behavior into a baseline Autoload merely for convenience.

## Production-friction rule

When a consuming game exposes a problem, ask:

1. Is this caused by incorrect use of an existing Nucleus contract?
2. Is the missing behavior broadly reusable across genres?
3. Would another game reasonably need the same fix?
4. Can Nucleus solve it without forcing project-specific policy on all games?

If the answer is mostly "no", fix the game. If the answer is mostly "yes", fix
Nucleus first and let the game consume the corrected contract.

## Public API and versioning

Before renaming/removing a public class, method, signal, export, Autoload, save
shape, settings contract, or required project wiring, read:

- `docs/policies/api_stability.md`
- `docs/policies/versioning.md`
- `docs/policies/deprecation.md`

Pre-1.0 allows contract changes, but they must still be intentional and
documented.

## Required validation

Run the checks relevant to the change. A normal Nucleus change should pass:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py

godot --headless --path . --import
godot --headless --path . --check-only --script res://tests/headless/test_runner.gd
godot --headless --path . --script res://tests/headless/test_runner.gd
godot --headless --path . res://tests/smoke/smoke_main.tscn
```

Release-facing changes also require the export/package workflows.

If the environment cannot run Godot, say so explicitly and still run every
available static/documentation check. Do not present static validation as runtime
validation.
