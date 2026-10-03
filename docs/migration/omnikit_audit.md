# OmniKit Audit for Nucleus

This document records the disposition of reusable OmniKit functionality.

The objective is not compatibility. OmniKit is source material.

## Migrate into Core utilities

| OmniKit area | Nucleus disposition | Reason |
| --- | --- | --- |
| `structures/uuid.gd` | `NucleusUuid` | Persistent IDs are broadly useful; implementation rebuilt with CSPRNG. |
| `structures/semantic_version.gd` | `NucleusSemanticVersion` | Useful for schemas/protocols/modules; parser and SemVer precedence rebuilt. |
| `structures/shuffle_bag.gd` | `NucleusShuffleBag` | Common game-randomization primitive; deterministic RNG support added. |
| `structures/array_helper.gd` | `NucleusArrayUtils` subset | Keep flatten/chunk/unique/intersection/circular helpers; use native APIs for the rest. |
| `structures/dictionary_helper.gd` | `NucleusDictionaryUtils` subset | Deep merge/path operations are useful; unsafe object-key transforms are dropped. |
| `structures/enum_helper.gd` | `NucleusEnumUtils` | Useful concept; fixes value-vs-index bug. |
| `time/time_helper.gd` | `NucleusTimeUtils` subset | Keep duration formatting and monotonic seconds; Timer construction is trivial native API. |
| `files/file_helper.gd` | `NucleusFileUtils` subset | Keep robust recursive host-filesystem operations; platform paths remain in `NucleusPaths`. |
| `nodes/node_traversal.gd` | `NucleusNodeUtils` subset | Keep traversal/ownership only; native Node search APIs replace custom type searches. |
| `geometry/geometry_helper.gd` + `vector_helper.gd` | `NucleusRandomGeometry` subset | Keep common random sampling after fixing distribution/position bugs. |

## Already absorbed elsewhere

| OmniKit area | Nucleus home |
| --- | --- |
| `logger/logger.gd` | `core/diagnostics/` |
| WindowManager viewport/window helpers | `core/window/` + `NucleusApp` + Settings |
| InputHelper / MotionInput | `core/input/` |
| GamepadControllerManager | `core/input/` |
| NetworkHandler | optional `modules/networking/` |
| EventBus | optional `modules/event_bus/` |
| HardwareDetector platform checks | `core/platform/NucleusPlatform` |
| executable/user/system paths | `NucleusPaths` + native `OS` APIs |

## Defer to Components/UI phase

These concepts can be useful, but their natural home is not a universal utility
namespace:

| OmniKit area | Future direction |
| --- | --- |
| `collisions/collision_helper.gd` | physics/components |
| `motion/velocity_helper.gd` | movement components |
| `viewport/camera_2d_helper.gd` | camera components |
| `viewport/camera_3d_helper.gd` | camera components |
| `viewport/raycast_result.gd` | raycast/query component or value object if needed |
| `viewport/texture_helper.gd` | rendering/UI only if a real use case survives |
| `nodes/node_positioner.gd` | scene/component utilities |
| `nodes/node_remover.gd` | lifecycle/component utilities |
| `text/label_helper.gd` | UI components |
| color palette/gradient Resources | UI/art tooling if projects need them |

## Keep optional, not Core

| OmniKit area | Reason |
| --- | --- |
| name generator / name repository | content-generation feature, not infrastructure |
| Markov text generator | procedural-content module |
| censorer | moderation/content policy is project-specific |
| hardware requirements | diagnostics/benchmark tooling, not runtime foundation |
| bit stream | specialized protocol/serialization primitive; belongs near networking if required |
| Jobs | old class is coroutine aggregation, not a real job system; use explicit async flow or `WorkerThreadPool` |
| color generation | art/procedural-content concern; native `Color` API covers primitives |

## Do not migrate

### Giant MathHelper

The old `MathHelper` mixed:

```text
math constants
probability
formatting
Roman numerals
hex conversion
angles
quaternions
random seeds
game smoothing
unit conversion
```

This makes discoverability worse and encourages unrelated dependencies.

Most operations are either:

- already native (`clamp`, `remap`, `snapped`, vector operations);
- one-line domain code;
- formatting/localization concerns;
- too specialized without an actual Nucleus consumer.

Functions should only re-enter Nucleus later under a narrow domain-specific
utility when multiple real consumers justify them.

### StringHelper as a class

Godot already provides:

```text
to_snake_case
to_camel_case
to_pascal_case
repeat
replace
case-insensitive search/compare variants
```

English ordinals and compact suffixes such as `K/M/B` are localization/UI
policy, not a universal string utility.

### JSON helper

Opening a file and calling `JSON.parse()` is already direct Godot API.

Encryption belongs to a storage/security layer, as demonstrated by Nucleus Save.

### CSV reader

`FileAccess.get_csv_line()` already implements CSV parsing and custom
single-character delimiters.

A future data-import system may provide typed schema conversion, but a global
CSV helper adds little value today.

### Localization language database

Godot's `TranslationServer` and locale APIs should be the source of truth.

Maintaining a hand-written global language table duplicates engine data and
creates correctness problems as locale standards evolve.

### Hardware heuristics

The following ideas are intentionally rejected:

```text
CPU cores * 2 == usable threads
Steam Deck detection by GPU/CPU name substrings
browser user-agent sniffing as primary platform detection
```

Nucleus prefers engine feature/capability queries.
