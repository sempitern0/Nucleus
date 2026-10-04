# Settings and Input Quickstart

## Settings

Use `NucleusSettings` as the stable settings service.

For a new setting:

1. define/register it using the existing Settings definition/catalog pattern;
2. provide a default;
3. add an applier when it changes engine/runtime state;
4. bind UI through the existing settings binding components;
5. let Settings persistence own the stored preference.

Do not make the UI write engine settings directly when an applier already
exists.

## Input

Keep gameplay code semantic:

```gdscript
if Input.is_action_just_pressed("interact"):
	# Game-specific interaction request.
	pass
```

Use the Nucleus input service for device tracking/rebinding/prompt concerns, not
as a replacement for `Input`/`InputMap`.

## Rebinding

Use the existing binding codec/service path so rebinding remains serializable and
device-aware.

After a binding changes, UI prompts should derive their label from the input
label/prompt helpers instead of storing strings such as `E`, `A`, or `LMB`.

## Local multiplayer

Create/use the local input session and per-player readers for explicit device
ownership.

Do not route all players through "the last active gamepad".

## Common mistakes

- storing settings in the save-game document;
- hard-coding physical keys in gameplay code;
- keeping stale prompt text after rebinding;
- using a global input source as local-player ownership.
