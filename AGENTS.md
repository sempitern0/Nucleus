# Nucleus agent contract

This file is a short map for coding agents. The detailed source of truth remains
under `docs/`.

## Before editing

1. Inspect the current repository state and the relevant Nucleus implementation.
2. Search for an existing Nucleus public API before calling the underlying Godot
   API directly.
3. Read the relevant contract under `docs/components/`, `docs/modules/`,
   `docs/guides/`, or `docs/policies/`.
4. Keep changes driven by observed production friction. Do not expand the
   template only because a generic feature could be imagined.

## Nucleus-first ownership rule

Godot-native APIs remain the default when Nucleus does not own the behavior.
When Nucleus already centralizes a concern, game-facing code must use the
Nucleus boundary instead of duplicating the lower-level call.

Important examples:

- Cursor mode: use `NucleusCursor.show()`, `hide()`, `capture()`, `confine()`,
  or `set_mode()`. Do not assign `Input.mouse_mode` in game code.
- Persisted display settings: use `NucleusSettings` and the settings bindings.
  Do not call `DisplayServer.window_set_mode()` or set VSync from game UI.
- Scene transitions: use `NucleusSceneFlow` when the transition belongs to the
  application flow.
- Application quit/back behavior: use `NucleusApp`.
- Save-game persistence: use `NucleusSave` and explicit save participants.
- Audio behavior already modeled by Nucleus should go through `NucleusAudio`.

The rule is not "wrap every Godot API". It is "do not bypass an existing
Nucleus owner".

If a direct lower-level call is genuinely required, document why and update the
central ownership rule or implementation deliberately. Do not add a local
workaround just to silence validation.

## Settings validation

`NucleusSettings` stores user preferences. Settings appliers translate those
values into runtime Godot state. Project settings are not the runtime source of
truth after startup.

Godot game embedding does not support window mode changes such as fullscreen.
When validating window mode, disable **Embed Game on Next Play** or run an
export/separate game window.

## Required validation

Run the repository checks relevant to the change. For a normal Nucleus delta:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py

godot --headless --path . --import
godot --headless --path . --check-only --script res://tests/headless/test_runner.gd
godot --headless --path . --script res://tests/headless/test_runner.gd
```

Use the normal smoke/export CI for release-facing changes.
