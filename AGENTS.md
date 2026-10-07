# Nucleus agent contract

Nucleus is a reusable Godot project foundation, not one game's codebase.
Contributors act as maintainers of a production-oriented template that must
remain useful across unrelated games.

This file is the fast operating contract for human and AI agents. Detailed
behavior lives in current source/tests; public intent and integration contracts
live under `docs/`.

## 1. First minute: establish the real baseline

Before proposing or changing anything:

1. inspect the current branch/HEAD and `VERSION`;
2. inspect the exact affected source files;
3. locate the current tests and technical contract;
4. check `project.godot` and
   `docs/policies/godot_compatibility.md` before assuming engine/runtime state;
5. search for an existing Nucleus owner before designing a new abstraction.

Never use stale conversation context, an old handoff, or this file's examples as
a substitute for current source.

For focused work, do not scan the whole repository. Search exact `class_name`,
method, signal, export, scene path, error text, or subsystem first.

Use `docs/documentation_coverage.json` to map subsystem directories to their
technical documentation.

## 2. Core philosophy

1. **Godot-native first.** Use native Godot APIs when no Nucleus ownership
   boundary exists.
2. **Do not bypass an existing owner.** Stable Nucleus boundaries are
   deliberate.
3. **Composition over inheritance.** Prefer small Nodes, Resources, adapters,
   signals, and explicit references.
4. **Scene ownership by default.** Autoloads require genuine cross-scene
   lifetime.
5. **Optional means optional.** `modules/` must not become hidden baseline
   dependencies.
6. **Production evidence before abstraction.** Real repeated friction earns
   reusable API; imagined flexibility does not.
7. **Godot remains authoritative.** Do not mirror strong engine systems with a
   parallel framework.
8. **Public API is deliberate.** Public `class_name` identifiers use the
   `Nucleus` prefix.
9. **Trust boundaries are code boundaries.** Never weaken content, networking,
   save, or platform security for convenience.
10. **Small ownership surfaces beat manager proliferation.**

The default cross-scene services remain:

```text
NucleusApp
NucleusSettings
NucleusInput
NucleusAudio
NucleusSave
NucleusSceneFlow
```

Do not add another Autoload merely to avoid explicit scene wiring.

## 3. Ownership decision

Use this decision order:

```text
Existing Nucleus owner?
	→ use or extend that owner

Godot already owns the problem well?
	→ use Godot directly

Repeated reusable friction across games?
	→ consider component/module/API refinement

Genre/content/balance/art/product/provider policy?
	→ keep it in the consuming game
```

A helper being reusable does not automatically make it Core.

Examples of game-owned policy include:

- survival rules and progression;
- procedural-world layout policy;
- exact mission/objective design;
- art direction and water/terrain palettes;
- encounter pacing and balance;
- provider/store-specific product policy;
- whether a game is solo, LAN, peer-hosted, or dedicated.

Nucleus may provide primitives that those systems compose.

## 4. Consumer-driven development loop

Nucleus should evolve through a real consuming game:

```text
generic Nucleus primitive
		↓
real game integration
		↓
measured friction / repeated wiring / failure
		↓
small contract refinement
		↓
back to the game
```

Do not reverse this loop by building a generalized framework before a consuming
game proves the need.

When Nautica or another game exposes a problem, classify it first:

- incorrect use of an existing Nucleus contract → fix the game/integration;
- reusable bug in Nucleus → fix Nucleus;
- repeated cross-game wiring → consider a small adapter/component;
- game-specific world/content/product policy → keep it game-owned.

One game's architecture is evidence, not universal policy.

## 5. Current architectural boundaries

### UI

Nucleus UI composes native `Control`, `Container`, focus, Theme, Tween,
AnimationPlayer, and shader materials.

Do not introduce a global UI manager, custom layout engine, design-token
replacement, transform mixer, generic dialogue framework, or UI EventBus without
strong production evidence.

Preferred transform ownership remains:

```text
LayoutSlot
    → PresentationRoot
        → FeedbackRoot
            → Content
```

Reusable UI work should primarily harden existing contracts and fix observed
consumer friction rather than expand horizontally.

### World runtime and streaming

World streaming must not become a monolithic `WorldManager`.

Prefer small scene-owned composition:

```text
game-owned spatial heuristic
        ↓
NucleusWorldStreamLifecycle
        ↓
bounded load/unload admission
        ↓
game-owned loading/materialization/persistence
```

The game decides which regions are wanted and why. Nucleus owns reusable
lifecycle mechanics only when justified.

Use request tokens/operation identity for asynchronous work. A stale completion
must never acknowledge a newer retry for the same logical region.

### Terrain

Nucleus owns reusable procedural heightfield generation, materials, samplers,
debugging, preview, and bounded streaming primitives.

It does not own a game's island distribution, biome layout, shoreline art
direction, erosion style, objective placement, or world progression.

### Persistence

Persist stable plain data, not live Nodes, Callables, RIDs, temporary node paths,
or presentation state.

`NucleusSave` owns storage/versioned documents. Scene/game code owns capture and
restore meaning through explicit save participants.

### Networking

Keep transport, discovery, authentication, authority, replication, and
deployment separate.

Transport connectivity does not imply gameplay authority. First decide who owns
a mutation; then replicate the minimum required state.

## 6. Strict GDScript rules

The repository is maintained as if warnings can be treated as errors.

### Never rely on Variant inference

Do not use `:=` when the right-hand side can return `Variant`, including common
cases such as:

```text
Object.get(...)
Dictionary.get(...)
Array/Dictionary dynamic indexing
Callable.call(...)
Node.call(...)
metadata lookups
dynamic resources
```

Use an explicit type plus cast/conversion instead.

Prefer:

```gdscript
var raw_value: Variant = source.get("value")
var count: int = int(raw_value)
var target: Node3D = source.get("target") as Node3D
```

over inferred Variant locals.

### Do not shadow Godot/base-class members

Avoid local variables and parameters that shadow properties/methods inherited
from Godot base classes. Common high-risk names include:

```text
basis
transform
position
rotation
scale
name
owner
process_mode
visible
material
```

Use semantic names such as `body_basis`, `target_position`,
`spawn_transform`, or `surface_material`.

Do not suppress `SHADOWED_VARIABLE_BASE_CLASS`; rename the identifier.

### Constant expressions

Do not assume constructed packed arrays/resources are valid constant
expressions. Prefer literal `Array` constants when needed, or initialize packed
containers at runtime.

### General style

- explicit types at public and dynamic boundaries;
- tabs for GDScript indentation;
- no trailing whitespace;
- keep GDScript lines within repository limits;
- no invented APIs;
- no warning suppression as a substitute for clean code.

## 7. Input and UI invariants

Gameplay consumes semantic actions, not physical keys.

```text
ui_* actions
	→ active UI navigation

move_* / interact / primary_action / secondary_action / pause
	→ gameplay semantics
```

Do not interpret `ui_cancel` as a universal "leave gameplay" action.

Use `NucleusInput`, `NucleusLocalInputSession`, and the matching public input
helpers instead of caching device IDs, physical keys, or prompt strings in
gameplay.

## 8. Save, content, and security invariants

- untrusted community content remains data-only;
- never mount an untrusted PCK/ZIP with
  `ProjectSettings.load_resource_pack()`;
- official trusted packs must pass Content Packs verification;
- private signing keys never enter repository/export/log output;
- save payloads must remain deterministic, bounded, and save-safe;
- authentication secrets/passwords are never announced through LAN discovery;
- do not weaken validation because a feature is "development only" if the same
  boundary can ship.

## 9. Public API changes

Before changing public classes, methods, signals, exports, Autoloads, required
scene wiring, save formats, settings schemas, or stable resource contracts,
read:

```text
docs/policies/api_stability.md
docs/policies/versioning.md
docs/policies/deprecation.md
```

Pre-1.0 permits intentional change, not accidental breakage.

When a public contract changes, update:

- implementation;
- tests;
- technical documentation;
- migration/deprecation guidance when applicable.

Do not add historical iteration journals to technical docs. Git history,
releases, issues, and changelogs own history.

## 10. Repository change protocol

For implementation work:

1. inspect current HEAD and affected files;
2. identify the existing owner;
3. read its contract and relevant tests;
4. inspect a real example/consumer when integration matters;
5. make the smallest coherent change;
6. add or update executable coverage;
7. update current-use documentation if public behavior changed;
8. run available validation;
9. state exactly what was and was not executed.

When the user explicitly requests non-mutating delivery, do not push or edit the
remote repository. Produce root-relative replacement files or an overlay ZIP
that can be applied at repository root.

Never claim repository mutation, Godot runtime validation, CI success, or export
success unless it actually occurred.

## 11. Validation contract

Normal static validation:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py
```

Authoritative runtime validation uses the project so Autoloads are registered:

```bash
godot --headless --path . --import
godot --headless --path . res://tests/headless/test_runner.tscn
godot --headless --path . res://tests/smoke/smoke_main.tscn
```

Do not replace the native project runner with an isolated script invocation when
the test graph depends on project Autoloads.

If Godot is unavailable, say so explicitly. Static checks are not runtime
validation.

For performance work, separate CPU, GPU, physics, memory, and I/O evidence.
Profile the consuming game and real target hardware; architecture alone is not a
performance result.

## 12. Answer/implementation quality bar

For "How should I implement X?", give one preferred architecture first.

When relevant include:

- ownership: Nucleus vs Godot vs consuming game;
- scene/object/data flow;
- verified current APIs;
- lifetime and authority;
- persistence implications;
- performance/trust constraints;
- failure/recovery behavior;
- tests and validation;
- what evidence would justify further abstraction.

Prefer a small working vertical slice over a broad speculative subsystem.

## 13. Avoid

Do not:

- invent or assume stale APIs;
- bypass existing Nucleus owners;
- create service locators;
- proliferate global managers;
- make optional modules mandatory;
- replace native Theme/layout/AnimationTree/navigation/physics abstractions;
- add networking replication before defining authority;
- generalize one game's balance/content/world rules into Nucleus;
- hide warnings instead of fixing them;
- call static validation "runtime-green";
- expand a subsystem horizontally when the current production bottleneck is
  elsewhere.
