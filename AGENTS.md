# Nucleus agent contract

Nucleus is a reusable Godot project foundation, not one game's codebase. Work as
a template maintainer: preserve clear ownership, normal Godot workflows, and
reuse across unrelated games.

This file is the fast routing layer. Detailed contracts live in `docs/`; exact
behavior lives in current source/tests.

## 1. Fast operating model

Before answering or editing, classify the task:

- **Implement X in a game:** start at `docs/guides/real_game_patterns.md`, then
  the matching quickstart/tutorial. Inspect source only for exact API details.
- **Explain Nucleus X:** read its technical contract, then source/tests.
- **Debug X:** follow error/warning → owner → relevant test → caller.
- **Extend Nucleus:** read owner + contract + tests + API policies if public.
- **Game-specific mechanic:** compose existing primitives before proposing new
  reusable Nucleus API.

Do not scan the whole repository for a focused task.

Use `docs/documentation_coverage.json` to map subsystem directories to technical
documentation.

## 2. Minimal context ladder

Read only as deep as needed:

```text
README/docs index → orientation
quickstart        → ownership + setup
tutorial          → concrete scene wiring
technical contract→ behavior + limits
source            → exact current API
tests             → executable edge cases
examples          → known-good integration
```

Search exact `class_name`, method, signal, export, scene path, or error text
before browsing adjacent folders.

Never invent a Nucleus class, method, signal, export, Autoload, or file path.

If evidence conflicts: source/tests describe current behavior; technical docs
describe intended public behavior. Report/fix the mismatch.

## 3. Architecture rules

1. **Godot-native first.** Use native APIs when no Nucleus owner exists.
2. **Do not bypass a Nucleus owner.** Existing public boundaries are deliberate.
3. **Composition over inheritance.** Prefer small Nodes, Resources, adapters,
   signals, and explicit references.
4. **Scene ownership by default.** Autoloads require genuine cross-scene life.
5. **Optional means optional.** Modules cannot become hidden baseline deps.
6. **Production evidence before abstraction.** Repeated friction justifies API.
7. **Public API is deliberate.** Public `class_name` uses the `Nucleus` prefix.
8. **Trust boundaries are code boundaries.** Never weaken them for convenience.
9. **Godot remains authoritative.** Do not mirror strong engine systems.

Ownership decision:

```text
Existing Nucleus owner? → use/extend it
Godot already owns it?  → use Godot directly
Reusable across games?  → consider component/module
Genre/content/balance/backend/art policy? → keep game-owned
```

A reusable helper is not automatically a Core service.

## 4. Baseline ownership

Check `VERSION`, `project.godot`, and
`docs/policies/godot_compatibility.md` before assuming state.

Default cross-scene services:

```text
NucleusApp
NucleusSettings
NucleusInput
NucleusAudio
NucleusSave
NucleusSceneFlow
```

Everything under `modules/` is opt-in unless its contract says otherwise.

| Concern | Preferred owner |
| --- | --- |
| lifecycle / quit / back | `NucleusApp` |
| settings | `NucleusSettings` |
| input/rebinding/device state | `NucleusInput` |
| audio routing | `NucleusAudio` |
| save sessions | `NucleusSave` |
| app scene transitions | `NucleusSceneFlow` |
| cursor/local devices/haptics | matching `Nucleus*` helper |
| common mechanics/UI | `components/gameplay/*`, `components/ui/*` |
| optional production systems | matching `modules/*` |
| engine primitives | native Godot unless adapted |
| rules/content/balance | consuming game |

The rule is not "wrap every Godot API"; it is "do not bypass an owner".

## 5. Feature router

Start from the closest entry, then use `docs/documentation_coverage.json` for the
technical contract.

| Area | Start here |
| --- | --- |
| project/component choice | `foundation_quickstart.md`, `real_game_patterns.md` |
| input/settings/local devices | `settings_input_quickstart.md` |
| audio/save/localization/scene flow | `runtime_services_quickstart.md` |
| gameplay foundation/actions/status | matching gameplay/action quickstart |
| movement/camera/animation | `gameplay_movement_camera.md`, `animation_integration_quickstart.md` |
| pooling/targeting/game feel | matching pooling/camera quickstart |
| terrain | `terrain_generation_quickstart.md` |
| inventory/loot/world state/AI | matching quickstart in `docs/guides/` |
| performance/dev tools | `performance_quickstart.md`, `development_tools_quickstart.md` |
| networking/replication/deployment | matching networking quickstart |
| platform/content packs/mobile | matching quickstart in `docs/guides/` |
| troubleshooting/CI | `troubleshooting.md`, `validation_ci_quickstart.md` |

## 6. Answer contract: "How do I implement X?"

Give one preferred architecture, not a catalogue. Include when relevant:

1. ownership: Nucleus vs Godot vs game-owned;
2. composition: scene/object graph + data/control flow;
3. verified current public APIs;
4. implementation order: editor → Resources → glue → runtime;
5. lifetime/authority/persistence/performance/security constraints;
6. likely failure modes and recovery;
7. matching tests/examples and profiling/assertions;
8. exact follow-up docs.

Prefer alternatives only when they materially change architecture/tradeoffs.

Useful composition shapes:

```text
3D player: semantic input → movement → CharacterBody3D → camera → animation
combat: hit/action → value pool/state/status → animation/feedback
persistence: stable identity → state adapter → NucleusSave → reconcile
online: input → intent → server validation → mutation → replication
terrain: profile + layout + material → generator/streamer → native Godot data
```

Keep project rules around those primitives game-owned.

## 7. Critical invariants

- **Input:** gameplay uses semantic actions, not physical keys. `ui_*` is UI
  navigation. Rebinding goes through `NucleusInput`; touch feeds same semantics.
- **Animation:** Godot owns `AnimationTree`, `Skeleton3D`, retargeting, IK,
  constraints, attachments, and physical bones. Nucleus adapts glue only.
- **Networking:** separate transport, authority, authentication, replication,
  and deployment. Peer-hosted transport does not imply client authority.
- **Terrain:** Nucleus owns procedural heightfield generation/preview/streaming,
  not a replacement terrain editor. Keep native mesh/collision/material visible.
- **UI/mobile:** use native `Control`, focus, responsive layout, platform APIs.
  Do not add global UI/Mobile managers for convenience.
- **Persistence:** persist stable plain data, not live Nodes/Callables/transient
  state. Do not use arbitrary node paths as durable world identity.
- **External content:** never mount untrusted community PCK/ZIP with
  `ProjectSettings.load_resource_pack()` or pass it to executable loaders.
  Official packs use Content Packs verification; community mods stay data-only.

## 8. Repository change protocol

1. inspect current HEAD/files;
2. locate the existing owner;
3. read its technical contract;
4. inspect relevant tests;
5. inspect an example/tutorial when integration matters;
6. make the smallest coherent change;
7. update tests;
8. update current-use docs for public behavior;
9. run relevant validation;
10. state what could not be validated.

Do not use old conversation context instead of current source.

Before changing public classes, methods, signals, exports, Autoloads, save
formats, settings schemas, or required wiring, read:

```text
docs/policies/api_stability.md
docs/policies/versioning.md
docs/policies/deprecation.md
```

Pre-1.0 allows intentional change, not accidental change.

Optional modules stay explicit and must not be promoted to Autoloads merely for
convenience.

## 9. Performance and validation

Separate CPU, GPU, physics, memory, and I/O. Profile the consuming game and real
low-end target; do not infer performance from architecture alone.

Use `tests/headless/` for executable contracts and `examples/` for known-good
integration. A small example can be more useful than more prose.

Normal validation:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py

godot --headless --path . --import
godot --headless --path . --check-only --script res://tests/headless/test_runner.gd
godot --headless --path . --script res://tests/headless/test_runner.gd
godot --headless --path . res://tests/smoke/smoke_main.tscn
```

If Godot is unavailable, say so. Static checks are not runtime validation.
Release-facing changes also require export/package workflows.

## 10. Avoid

- invented/stale APIs or unnecessary full-repo scans;
- bypassed owners, hidden module dependencies, or manager proliferation;
- parallel replacements for strong Godot abstractions;
- generic APIs containing game balance/content/product policy;
- multiplayer sync before authority;
- hidden Godot warnings or weakened trust boundaries.

Repository docs should help users integrate, operate, extend, debug, validate,
or maintain Nucleus. History belongs in Git history, issues, pull requests, and
release notes; do not add roadmap/iteration/changelog journals to the template.
