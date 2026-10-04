# Nucleus — New Chat Handoff Context

Copy this document into a new conversation when continuing Nucleus development.

---

## Project

Repository:

```text
sempitern0/Nucleus
```

Default branch:

```text
main
```

Legacy/reference repository:

```text
sempitern0/Barebone
```

Nucleus is the successor/rework of Barebone, but there is no Barebone backward
compatibility requirement.

Target engine line:

```text
Godot 4.7.x
```

Release-gated reference:

```text
Godot 4.7.2-stable
```

Nucleus is a clean reusable Godot foundation/template for new games.

## Working style

- Inspect current `main` before every iteration.
- Reuse existing Nucleus APIs instead of duplicating behavior.
- Prefer Godot-native features over wrappers.
- Composition over inheritance for game-facing systems.
- Scene-owned systems unless cross-scene lifetime truly requires an Autoload.
- No Service Locator.
- Local signals before global EventBus.
- EventBus and NetworkHandler remain optional/not loaded by default.
- No Barebone compatibility aliases.
- Public `class_name` names use `Nucleus` prefix.
- GDScript: tabs, <=100 columns, LF, final newline.
- Generate a delta ZIP; do not mutate GitHub unless explicitly requested.
- Use CI/runtime results as the acceptance source of truth.

## Current checkpoint

Iteration 20 was prepared read-only against:

```text
main
8b0f4baac882563a603b53ffd98361ef4eb3c8ef
```

Commit message:

```text
nucleus stable release
```

## Versioning

Nucleus development version after Iteration 21:

```text
0.3.0-dev.1
```

Source of truth:

```text
VERSION
```

Nucleus uses Semantic Versioning independently from the consuming game's
version.

## Runtime / CI status

Iteration 18 established the operational validation pipeline.

Iteration 21 must remain runtime-validation pending until the updated CI parses
and executes the Inventory / Equipment suites successfully.

Current CI covers:

```text
static source checks
documentation coverage
productization contract audit
Godot headless import
native test-graph parse
native regression tests
bootstrap smoke scene
Linux smoke export
Windows smoke export
Web smoke export
```

## Implemented foundation

### Core

```text
Application lifecycle
platform/path normalization
Logging/diagnostics
Settings
Input + rebinding
local multiplayer input ownership
Audio
Save/encryption/migrations/autosave
Scene flow
Localization
Window / screenshot helpers
utilities
```

### Optional modules

```text
EventBus
NetworkHandler / LAN helpers
Inventory / Equipment
```

Neither is loaded by default.

### UI

```text
production UI composition
settings bindings
focus/navigation
motion
feedback
screen effects
modal/toast/tooltip
layout/presentation/data helpers
accessibility-oriented helpers
```

### Gameplay

```text
ValuePool / regeneration
DamageReceiver / Hitbox / Hurtbox
Interaction
Cooldown / Lifetime
StateMachine
Movement 2D/3D
Camera 2D/3D
GameplayActions
Attributes / modifier sources
Status Effects
Object Pooling / Spawners
Targeting / Sensing
SmartDecal3D
AnimationTree integration
camera/game-feel feedback
```

## Iteration 20

### SmartDecal3D

```text
components/gameplay/decals/smart_decal_3d.gd
```

It uses native Godot Decal projection, aligns local +Y with the outward surface
normal, supports tangent hints, planar size/roll variation, fade, and optional
NucleusPoolable release.

It does not own raycasts, impact classification, or a global decal manager.

### Screenshot capture

`NucleusWindow` now supports:

```text
Viewport → Image
await frame_post_draw capture
PNG/JPEG/WebP save
collision-safe timestamped paths
```

`NucleusPaths.screenshots_directory()` owns the default writable location.

This is still-image tooling, not video recording.

## Documentation

One source of truth:

```text
technical behavior → docs/components/
optional module contract → docs/modules/
editor workflow → docs/guides/
cross-cutting product promises → docs/policies/
design rationale → docs/architecture/
future/status → docs/roadmap/
```

New guides:

```text
docs/guides/smart_decals_quickstart.md
docs/guides/screenshot_capture_quickstart.md
```

## Validation commands

Run:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py

godot --headless --path . --import

godot \
  --headless \
  --path . \
  --check-only \
  --script res://tests/headless/test_runner.gd

godot \
  --headless \
  --path . \
  --script res://tests/headless/test_runner.gd
```

Then:

```text
F6 examples/validation/smart_decal_3d.tscn
```

and run CI for smoke exports.

## Natural next step

After Iteration 20 validates, start the planned real game from the resulting
Nucleus snapshot.

Further baseline changes should come from concrete production evidence.

## Decision rule

When considering a feature:

1. Is it broadly reusable across genres?
2. Does Godot already solve it?
3. Does Nucleus already expose a helper/component that should be reused?
4. Is its correct home Core, scene-owned Components, optional module, plugin, or
   the game itself?
5. Does the abstraction remove repeated work without hiding useful Godot
   behavior?

The baseline should remain coherent even if that means saying no to useful but
project-specific features.

## Iteration 21 — Inventory / Equipment

The optional module lives under:

```text
modules/inventory/
```

It provides:

```text
NucleusItemDefinition
NucleusItemCatalog
NucleusItemStack
NucleusInventory
NucleusEquipmentItemDefinition
NucleusEquipmentSlotDefinition
NucleusEquipment
NucleusInventoryItemRequirement
NucleusInventoryItemCost
```

Inventory and Equipment are scene-owned.

Equipment reuses `NucleusAttributeSet` modifier sources instead of owning a
parallel stat model.

Save integration uses explicit `NucleusSaveSession` participant registration.

Recommended next optional module:

```text
Probability / Loot
```

Use Barebone only as a concept/source audit; do not carry forward its global Loot
manager automatically.
