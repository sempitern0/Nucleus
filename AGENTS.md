# Nucleus — agent operating contract

## CRISP — 60-second agent brief

**CRISP = Context · Role · Inspection · Standards · Proof.** This five-step
entry point is for fast, evidence-based contributions. Read the detailed
existing operating contract below only as far as the affected subsystem
requires; those constraints remain authoritative.

| CRISP | Mandatory agent behavior |
| --- | --- |
| **C — Context** | **Nucleus** is a reusable Godot **4.7.2-stable project foundation**, not one game's feature backlog and not a replacement game engine. Six baseline Autoloads, reusable components and optional modules are its product. Always check the actual **\`main\` HEAD** and engine pin. |
| **R — Role** | **Act as a principal Godot engine/gameplay systems engineer and game technical director**, versed in releasing high-quality **indie and AAA-scale titles**: engine-native rendering/shaders, frame-time and memory budgets, animation/physics, networking/replication/authority, gameplay architecture, accessibility, cross-platform export and tooling. Apply AAA-level reliability **without dragging AAA-level organizational overhead into a lightweight template**. |
| **I — Inspection** | Find the existing owner, public contract, immediate callers, consumer use case, headless test and documentation coverage entry **before** adding a new class or service. Read only the relevant files, not the entire \`core/\`, \`components/\`, \`modules/\` and docs trees. |
| **S — Standards** | Native Godot first; scene ownership and composition by default; exactly one writer per state; six deliberate Autoloads; optional modules remain optional; stable, documented APIs; no untrusted client authority or uncontrolled async/lifetime behavior. Distinguish a **reusable mechanism** from a **consuming game's art or balance policy**. |
| **P — Proof** | Run static, docs and productization audits; use the registered headless manifest and actual Godot project scene. For graphics, networking and performance require a relevant device/render/multiplayer measurement—not simply a passing parser. Include export smoke evidence for release-facing changes. |

### Owner locator (start small)

| Request | Inspect first | Avoid |
| --- | --- | --- |
| Character movement, camera or animation | \`components/gameplay/movement/\`, \`camera/\`, \`animation/\` | Replacing native \`CharacterBody\`, \`AnimationTree\` or skeleton systems |
| Graphics, lighting, shaders, performance | \`components/world/rendering/\`, \`modules/performance/\` | A competing renderer, global per-frame writes or unmeasured quality cuts |
| Multiplayer and server trust | \`modules/networking/\`, \`modules/networking/replication/\` | Treating a valid RPC, transport session or NodePath as authorization |
| Save, scene flow, input and accessible UI | \`core/save/\`, \`core/scene_flow/\`, \`core/input/\`, \`components/ui/\` | Bypassing Nucleus-owned service policy with direct engine calls |
| Public API, packaging and compatibility | \`docs/policies/\`, \`docs/documentation_coverage.json\`, \`scripts/ci/\` | Invisible test suites, undocumented changes, unsupported export claims |

**First commands (repository root):**

\`\`\`bash
git status --short
git branch --show-current
git rev-parse HEAD
cat VERSION
rg -n 'SpecificNucleusSymbol|relevant_method|error_text' core components modules
python3 scripts/ci/static_checks.py
\`\`\`

Replace the illustrative search expression with the actual task symbol;
read the matched implementation, caller and test before widening the search.
The project test runner requires baseline Autoloads—use its **scene**, not
standalone \`godot --script\`.

**Architecture decision gate:** Does native Godot already provide the
mechanism? Is the need shared by more than one real game? Who owns state,
failure, authority and lifecycle? Could an opt-in adapter, profile or focused
bug fix solve it without another global manager? If the behavior belongs to
Nautica or another consuming game, **leave it there**.

**Definition of done:** one narrow, maintainable, game-agnostic change;
registered relevant regression tests; supported API and migration implications
documented; appropriate static/Godot/export evidence; exact unresolved limits.
Never claim multiplatform readiness, rendering quality, stable frame budgets or
multiplayer security from text-only inspection.

---


Nucleus is a reusable **Godot 4.7 project foundation**, not the codebase of one
particular game. The objective is to ship different games quickly **without**
sacrificing correctness, maintainability, security, accessibility, or low-end
performance. More code is not automatically more capability.

This file is the **fast path for AI and human contributors**. Keep it actionable.
The current source and executable tests define what works; `docs/` defines
intended public behavior. If this file conflicts with either, verify the
current `main`/checkout and fix the inconsistency rather than guessing.

## 0. Sixty-second start

Before making a plan or editing files:

```bash
git status --short
git branch --show-current
git rev-parse HEAD
cat VERSION
rg -n 'class_name Nucleus.*|func target_method|specific_error' core components modules
```

Replace the illustrative search expression with **the specific API, owner,
error, or behavior** in the task. If `rg` is unavailable, use `grep -R` or
file search. Do not crawl every file or read the whole documentation tree for a
small change. Then:

1. Read the affected implementation, its immediate callers, and its tests.
2. Find the corresponding contract via `docs/documentation_coverage.json` and
   targeted links in `docs/README.md`.
3. Check the engine pin in `docs/policies/godot_compatibility.md` and
   `.github/workflows/nucleus-ci.yml` before relying on an API.
4. State **who owns the behavior** (Godot, Nucleus, or consuming game).
5. Make the smallest vertical change, validate it, report evidence and limits.

**Source freshness rule:** Never trust old agent notes, prior chat snippets,
previous overlays, or examples over the current checkout. Never change the
repository/branch/remote unless the user's current authorization permits it.
When a user requests a ZIP-only workflow, deliver root-relative replacement
files and **do not create branches, commits, PRs, or remote changes**.

## 1. Non-negotiable design rules

1. **Godot-native first.** Reuse `SceneTree`, `Resource`, `Signal`, `AnimationTree`,
   `Skeleton3D`, physics, navigation, `Viewport`, native lights, rendering, and
   multiplayer before adding a parallel system.
2. **One owner per writable responsibility.** Do not have two systems writing
   the same transform, property, lifecycle, network state, or resource.
3. **Composition over inheritance.** Prefer small Nodes, Resources, explicit
   references, signals, and thin adapters to an inheritance hierarchy or service
   locator.
4. **Scene ownership by default.** Add an Autoload only for demonstrable
   cross-scene lifetime, never just to avoid explicit wiring.
5. **Optional modules remain optional.** No invisible dependency on `modules/`
   from baseline Core.
6. **The game owns art, mechanics, content, balance, and product policy.** Nucleus
   owns reusable mechanisms only; a real consuming game must demonstrate value.
7. **Stable identity and recoverable transitions beat convenience.** Async
   operations, persistence, networking, and editor generation need explicit
   lifetime/failure rules.
8. **Measure before optimizing.** CPU time, GPU time, physics, memory, I/O, and
   stutters are separate evidence. An audit warning is not a measured regression.
9. **Lower visual cost before gameplay correctness.** Design meaningful
   `MINIMAL/REDUCED/FULL` modes where relevant, and verify low-end readability.
10. **Public API is intentional.** Public `class_name` symbols start with
    `Nucleus`. Keep non-public details private/underscore-prefixed.

Only these six services are baseline Autoloads (`project.godot` is authoritative):

```text
NucleusApp | NucleusSettings | NucleusInput
NucleusAudio | NucleusSave | NucleusSceneFlow
```

### Decide whether a feature belongs in Nucleus

```text
Existing owner solves it?              → integrate/repair that owner
Godot already provides the mechanism?  → call the native API
Repeated cross-game integration pain?  → small adapter/profile/tool
Game-specific rules/art/content?       → keep in the consuming game
One-off speculation?                   → don't build a new framework
```

A production-grade result can be a **small deletion, improved default, diagnostic,
or focused test**, not a new manager. Do not generalize one game's solution
without separating evidence from game-specific policy.

## 2. Find the owner, not a new abstraction

| Concern | Inspect first | Contract / test starting point |
| --- | --- | --- |
| Lifecycle, paths, diagnostics | `core/application`, `core/diagnostics`, `core/utils` | `docs/components/core_runtime.md`; `tests/headless/diagnostics_logging_test.gd` |
| Settings, input, accessibility | `core/settings`, `core/input`, `core/accessibility`, `components/ui` | `docs/components/accessibility_preferences.md`; `tests/headless/accessibility_input_test.gd` |
| Audio, save, scene transitions | `core/audio`, `core/save`, `core/scene_flow` | `docs/components/audio_save_scene_localization.md`; `tests/headless/save_resume_test.gd` |
| Character movement / camera | `components/gameplay/movement`, `components/gameplay/camera` | `docs/components/gameplay_movement_camera.md`; relevant smoke/example scenes |
| Animation / ragdoll | `components/gameplay/animation` | `docs/components/animation_integration.md`, `docs/components/ragdoll_authoring_3d.md`; `tests/headless/animation_integration_test.gd` |
| AI / navigation | `modules/ai`, `components/gameplay/timing` | `docs/modules/ai_navigation.md`; `tests/headless/ai_navigation_test.gd` |
| World clock / day-night | `components/world/time`, `components/world/environment` | `docs/components/celestial_environment.md`; `tests/headless/celestial_environment_test.gd` |
| Material, geometry, lights, shadows | `components/world/rendering`, `modules/performance` | `docs/components/rendering_quality.md`, `docs/components/lighting_shadows_3d.md`; `tests/headless/lighting_quality_test.gd` |
| Terrain / materialization / streaming | `modules/terrain`, `components/world/streaming` | `docs/modules/terrain_materialization.md`, `docs/components/world_streaming.md`; terrain/stream tests |
| Networking / replication | `modules/networking`, `modules/networking/replication` | `docs/modules/networking.md`, `docs/modules/online_replication.md`; `tests/headless/network_replication_test.gd` |
| Optional content / providers | `modules/content_packs`, `modules/platform_services` | `docs/modules/content_packs.md`, `docs/modules/platform_services.md`; matching headless suites |
| Performance / development tools | `modules/performance`, `modules/development_tools` | `docs/components/runtime_optimization.md`; performance/development test suites |

Use the table to **locate** the source; do not infer signatures from it. For a
new subsystem directory, inspect and update `docs/documentation_coverage.json`.
Do not add a new umbrella manager just because an owner spans several files.

## 3. Godot 4.7 correctness traps (check before you code)

Reference engine: **Godot 4.7.2-stable**, currently **Forward Plus** and **Jolt
Physics** in `project.godot`. The version in this sentence is context, not a
substitute for checking the current CI pin. **Do not mix Godot 3.x, 4.6, latest
`master`, or GDExtension API assumptions with this project.** When unsure,
inspect the API in the exact supported version, use the editor/class reference,
and run an import/parser check. Never invent property names or enum values.

### GDScript parser, static types, and warnings

- Treat editor warnings as release blockers in changed code. Prefer explicit
  types at dynamic/API boundaries. `Object.get`, `Dictionary.get`, dynamic
  indexing, `call`, and metadata commonly produce `Variant`.
- **Do not infer an `Error`/`Variant` from a dynamic-looking expression.** A
  prior terrain fix involved `worker.decompress()` and an inferred local; use
  explicit `Error` when the method returns it:

  ```gdscript
  var decompress_error: Error = worker.decompress()
  if decompress_error != OK:
  	return decompress_error
  ```

- Prefer `var raw: Variant = data.get("key")` followed by a checked
  conversion, or `var node: Node3D = value as Node3D`. `as` is for compatible
  object types; do **not** use `as Vector3` or other built-in value casts.
- Avoid `:=` whenever inference can be `Variant` or the return type is uncertain.
  Do not hide errors with warning suppressions.
- Do not shadow properties inherited from Godot (`name`, `owner`, `position`,
  `basis`, `transform`, `rotation`, `scale`, `visible`, `process_mode`, etc.).
  Rename to `node_owner`, `body_basis`, `target_position`, etc.
- Constructed packed arrays/Resources may not be constant expressions. Use
  valid literal constants or runtime initialization.
- Repository style: UTF-8, LF, final newline, no trailing whitespace; tabs for
  `.gd`; **maximum 100 columns in `.gd`**. See `.editorconfig` and
  `scripts/ci/static_checks.py`.

### Node and Resource lifetimes

- `_init()` is **not** `_ready()`: do not assume a live `SceneTree`, parent,
  `get_viewport()`, Autoload, imported asset, or physics space during init.
- Scene-owned nodes must be wired after they exist; validate null/invalid
  references and disconnect signals on rewire/teardown. Prefer explicit
  `is_instance_valid()` checks for references that can be freed.
- Editor `@tool` code can run repeatedly while authoring. Prevent destructive
  regeneration, duplicate nodes, accidental runtime execution, or changes to
  imported scenes that reimport can overwrite. Generated children need a valid
  `owner` to serialize into the intended scene; use editor undo integration
  when appropriate, or document that a generation button is non-undoable.
- Shared `Resource`s (profiles, shapes, materials) have shared identity. Do not
  mutate a shared profile per actor/quality tier inadvertently; duplicate it
  when independent runtime state is necessary. Material caches can return the
  **same material instance** to multiple actors.
- Keep `res://` authored/read-only assets separate from writable `user://`
  settings, saves, logs and cache. Do not persist Node references, RIDs,
  Callables, or temporary NodePaths as long-lived state.
- Avoid arbitrary class names in scripts/UID clashes; when changing script or
  resource paths, check `.tscn`, `.tres`, `.gd.uid`, project settings and imports.
  Never fabricate a UID: let Godot generate it and check uniqueness.

### Frames, threads, and async work

- Mutate `SceneTree`/Node hierarchies, render-facing nodes and physics state on
  the appropriate engine thread/phase. Do not assume any API is thread-safe
  merely because a task uses `WorkerThreadPool` or `Thread`.
- A `call_deferred()` or `await process_frame` changes **when** work runs; it
  does not make a heavy synchronous mesh/collision build cheap. Bound each
  expensive step, measure worst-frame cost, and use existing
  `NucleusUpdateScheduler` / materialization primitives when appropriate.
- Validate request tokens/generations before applying async completions.
  Cancellation, scene exit and retries must not let a stale result override the
  current region/scene/resource state. A queued job count is not automatically
  a CPU-ms or VRAM budget.
- Use physics update phases for authoritative motion/physics and visual phases
  for presentation. Keep AI decisions lower-frequency only where motion
  continuity/collision correctness stays smooth.

### Rendering and animation

- Godot owns Forward+/Mobile/Compatibility renderers, light clustering, shadow
  atlases, mesh/material LOD, and shader compilation. Nucleus owns **quality
  policy, reversible bindings and diagnostics**, not a replacement renderer.
- Mobile/Compatibility have different feature limits. An API existing in
  Forward Plus is **not** proof it works in every renderer/export. Inspect
  shader built-ins/`render_mode` for the target engine and visually test normal
  maps, shadows, transparency, triplanar joins and distance fading.
- Separate geometry shadow casters (`GeometryInstance3D`), light quality
  (`Light3D`), and Viewport positional-shadow atlas budgets. Use native local
  light distance fade and cut shadows before illumination where art permits.
- Do not let `NucleusLightQualityController3D` compete with
  `NucleusDaylightDriver3D` for `shadow_enabled`. Likewise, separate
  `WorldClock` authority, derived celestial state, and sky/ocean presentation.
- Keep Godot `AnimationTree`, `Skeleton3D`, `BoneMap`, `PhysicalBoneSimulator3D`
  as owners. The ragdoll builder is an **authoring starter**, not a universal
  runtime human physics solver. Native joints/collision shapes require visual
  tuning and physics-backend testing.

### Networking, authority, and trust

- Godot owns transport/RPC/`MultiplayerSpawner`/`MultiplayerSynchronizer`.
  Nucleus adds narrowly scoped admission, sequence/rate validation and
  interpolation. **Connectivity or a matching NodePath is not authorization.**
- Default to server-authoritative state mutation. Validate the sender, allowed
  actor, sequence/rate, payload bounds, cooldown/range/resources and intent on
  the authority **before** changing health, inventory, positions, loot, saves,
  or match state. Choose reliable vs unreliable-ordered by semantics; avoid
  assuming packet arrival/order or identical render frame rates.
- Persist/replicate **small stable semantic state**, not rendered light
  transforms, transient ragdoll bodies, or every procedural-world vertex.
  Clock/time authority and client presentation should remain separable.
- Community content is **data-only and untrusted**. Do not mount an unverified
  PCK/ZIP through `ProjectSettings.load_resource_pack()`. Verified official
  packs use the Content Packs boundary. Never export/log private keys,
  credentials, LAN passwords, access tokens, or personal data.
- Use `NucleusLog` and bounded diagnostics for actionable debugging; do not
  log high-volume per-frame payloads or assume pretty formatting redacts data.

## 4. Explicit Nucleus-owned engine calls

`static_checks.py` deliberately rejects bypassing existing service policy.
Do **not** call these APIs from arbitrary components:

| Direct operation | Owner to use instead |
| --- | --- |
| `Input.mouse_mode =` | `NucleusCursor` (`core/input/cursor.gd`) |
| `DisplayServer.window_set_mode` / `window_set_vsync_mode` | `NucleusSettings` display applier |
| `Engine.max_fps =` | `NucleusSettings` display applier |
| `Input.vibrate_handheld` | `NucleusHaptics` |
| `DisplayServer.screen_set_orientation` | `NucleusMobileOrientationPolicy` |
| `OS.request_permission(s)` | `NucleusMobilePermissions` |
| `ProjectSettings.load_resource_pack` | verified `NucleusContentPackLoader` |

The authoritative allowlist is in `scripts/ci/static_checks.py`. Fix owner
bypasses at the call site; do not broaden the allowlist merely to pass CI.

## 5. High-leverage integration invariants

**Input / UI:** Gameplay consumes semantic actions (`move_*`, `interact`,
`primary_action`, `secondary_action`, `pause`), not raw device IDs/keys or `ui_*`
navigation. `ui_cancel` is not the universal gameplay exit. Let Godot `Control`,
`Container`, focus and Theme own UI layout. Isolate presentation/feedback
transforms instead of multiple writers on one Control:

```text
LayoutSlot → PresentationRoot → FeedbackRoot → Content
```

**Terrain / world streaming:** The game chooses region relevance and biome/island
content; `NucleusWorldStreamLifecycle` admits/cancels bounded operations; the
game wires materialization/persistence. Do not add a monolithic `WorldManager`.
Generation paced across frames is not equivalent to region unload-by-distance;
materialization steps must be bounded and stale jobs cancelled safely.

**Gameplay motion / AI:** A `CharacterBody3D` owns its collision/motor; player
and AI should feed the same movement/animation semantics where possible.
"Slow brain, smooth legs": throttle decisions, not essential physical movement.

**Persistence:** `NucleusSave` owns storage/integrity/format; game participants
own capture/restore meaning. Deterministic, bounded, schema-aware data only.
Save/resume must handle absent/corrupt/legacy data and avoid overwriting valid
state with partial failures.

**Public APIs and data:** Keep transport, authentication, authorization,
replication, and provider integration separate. Avoid hidden cross-module
coupling, global EventBus dependencies or new baseline Autoloads.

## 6. Change procedure: smallest safe vertical slice

**For any code change:**

1. Identify affected owner, native Godot counterpart and consuming use case.
2. Read real signatures, serialized exports, callers, test suite, contract.
3. Write down expected behavior, failure cases, ownership, and which API remains
   unchanged; inspect backwards compatibility before changing public wiring.
4. Implement one coherent feature/fix, preserving `FULL`/authored state where a
   presentation quality controller is involved. Refuse destructive editor
   rebuilds without explicit opt-in.
5. Add a regression test for the reported failure **and** boundary behavior:
   missing nodes, invalid inputs, cleanup, repeated activation, retry/cancel,
   save/load or authority as relevant.
6. Register every new `tests/headless/*_test.gd` in
   `tests/headless/test_manifest.gd`. Suites must extend
   `res://tests/headless/test_case.gd`, implement `run() -> Dictionary`, use
   existing `expect_*` helpers and `return finish()`.
7. Update current-use docs and `docs/documentation_coverage.json` when a new
   top-level subsystem appears. If public contracts change, consult
   `docs/policies/api_stability.md`, `versioning.md`, `deprecation.md`;
   provide migration guidance. **Documentation-only changes do not by
   themselves require a `VERSION` bump.**
8. Run applicable validation. Report **exactly** what passed, what failed and
   what could not run. Do not declare runtime, export, or low-end performance
   success from a static syntax/ZIP check.

### Three regressions agents must actively prevent

1. **GDScript type inference:** An `Error` return (e.g., `decompress()`) or
   `Variant` API became a bad `:=` inference. Explicitly type method results
   and test with the pinned Godot parser.
2. **Productization audit:** `README.md` must retain the **exact** required
   product contract link `docs/guides/tutorials/README.md` alongside other
   `README_TOKENS` in `scripts/ci/productization_audit.py`. Do not "clean up"
   links without running the audit.
3. **Test/serialization drift:** A new headless suite omitted from the manifest
   is invisible to the runner and rejected by static CI; editor-generated
   children without proper `owner` may appear in the editor but not survive
   saving/reopening the scene.

## 7. Validation: prove the relevant layer

Run from the repository root. Use the **reference** Godot version, not an
unverified system default.

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py

godot --headless --path . --import
godot --headless --path . res://tests/headless/test_runner.tscn
godot --headless --path . res://tests/smoke/smoke_main.tscn
godot --headless --path . res://tests/smoke/resource_loading_smoke.tscn
```

- The **project-scene** test runner is required because Nucleus Autoloads must
  exist; `godot --script tests/headless/test_runner.gd` is **not equivalent**.
- The loading smoke is especially important for `core/loading`/warmup changes.
- For editor tools, verify generated nodes actually save and reopen, the
  original imported resource survives reimport, and repeated actions are safe.
- For animation/physics/rendering/network work, run a representative scene,
  including transitions and failure cases, **not** only headless unit tests.
- For release-facing changes, follow `.github/workflows/nucleus-ci.yml`:
  smoke-export Linux/Windows/Web with official templates via
  `scripts/ci/smoke_exports.sh`. Those exports validate **baseline packaging**,
  not the capabilities of every consuming game.
- For performance work, compare the **same workload on target hardware** across
  relevant quality tiers, with frame-time tail latency, memory and visual
  correctness. "AAA-ready" is an aspiration, **not** a benchmark result.
- If Godot or export templates are unavailable, run honest static/structural
  checks and explicitly mark runtime/export validation **not run**.

## 8. Completion and delivery contract

Deliver only what the request authorizes. For a ZIP-only request:

- Read the current baseline, then create a **root-relative overlay** whose
  contents can be extracted at the Nucleus repository root. No leading wrapper
  directory, generated `.godot/`, cached imports, or invented `.uid` files.
- Do not rewrite unrelated source, silently bump `VERSION`, or create branches.
- Verify the archive can be opened, list changed/new files, and optionally
  provide SHA-256. Explain any conflict if the remote baseline moved.
- Summarize purpose, ownership, compatibility, behavior, tests and known
  limits. Differentiate inspected/read-only Git from actual repository writes.
- Do not claim a CI check passed unless it was run on an appropriate complete
  checkout; do not claim a Godot test passed unless its exit/status was seen.

**Default response for implementation tasks:** recommended design → exact
changed files → evidence/tests → limitations. Prefer one grounded recommendation
and the smallest practical patch over speculative roadmaps, wrappers or hype.

## 9. Stop signs

Do **not** introduce a custom renderer/physics/navigation/AnimationTree
replacement, a global `WorldManager`/`LightManager`, a universal gameplay UI
EventBus, generalized cloud/astronomy/active-ragdoll systems, game-specific
biomes/quests, or a networking authority shortcut **without explicit evidence
and a revised ownership contract**. Do not weaken security validation, fake
engine compatibility, or turn optional modules into Core dependencies to make a
demo run. Correctness, boundaries and a measurable working slice come first.
