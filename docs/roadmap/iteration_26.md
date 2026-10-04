# Iteration 26 — First consuming-game feedback and project identity

## Context

Nautica is the first real game exercising Nucleus as a production consumer.

Its first controller pass exposed two useful classes of feedback:

1. infrastructure that should disappear behind the template, such as seamless
   gamepad connection, hot-swap, prompts, and connection feedback;
2. game-specific policy that must remain outside Core, such as what B/Circle
   does during active gameplay.

This iteration records the boundary and improves Nucleus as an open-source
project without expanding the runtime surface speculatively.

## Input decision

`ui_accept`, `ui_cancel`, and the remaining `ui_*` actions are UI-navigation
semantics.

They are not gameplay commands.

A physical B/Circle input may simultaneously be:

```text
ui_cancel in menus
dodge / melee / interact in gameplay
ui_cancel again in a pause dialog
```

The active consumer defines context.

World/session scripts should use semantic gameplay actions such as `pause`,
`interact`, `primary_action`, `secondary_action`, or project-defined actions.

Nucleus does not add a separate mapping-context framework in this iteration.
Consumer-side context already solves the observed production case.

## Existing reusable gamepad behavior

The previous production-feedback increment established:

- default gamepad UI accept/cancel bindings;
- single-player keyboard/gamepad hot-swap on a stable local-player seat;
- runtime gamepad rebinding through the existing Nucleus codec/service;
- scene-owned controller connection/disconnection toasts.

This iteration documents those contracts and makes the UI/gameplay boundary
explicit for future games and coding agents.

## Open-source productization

The project presentation is upgraded with:

- a Nucleus-specific vector icon representing stable core + composable systems;
- a professional README header and live CI workflow badge;
- clearer status, feature, documentation, input, validation, and contribution
  sections;
- a stronger `AGENTS.md` decision contract;
- a real-game pattern guide that maps every baseline component group and
  optional module to recognizable game-shaped use cases.

## Real-game examples policy

Examples such as Hades, Diablo, Celeste, Rocket League, Vampire Survivors,
Valheim, or Zelda are used only as product/design analogies.

Nucleus documentation must not imply knowledge of those games' proprietary
internal source code or architecture.

## Non-goals

This iteration does not:

- replace Godot InputMap;
- add a full input-context framework;
- make all `ui_*` actions freely remappable by default;
- add genre-specific survival, ARPG, shooter, or RPG mechanics;
- move optional modules into the baseline;
- change the template's release-gated Godot version.

## Validation

The replacement set should pass:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py

godot --headless --path . --import
godot --headless --path . --check-only --script res://tests/headless/test_runner.gd
godot --headless --path . --script res://tests/headless/test_runner.gd
```

The branded icon should also be opened in the Godot editor once to confirm
import/rendering at project-icon scale.
