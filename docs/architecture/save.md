# Nucleus Save Architecture

Target engine: Godot 4.7.x.

## Goal

The save system separates:

```text
game-state capture
      │
      ▼
NucleusSaveSession           scene-owned
      │
      ▼
NucleusSaveService           application-wide facade
      │
      ├── Migration Pipeline
      ├── Integrity
      └── Repository
             │
             ├── Codec Strategy
             └── Encryption Strategy
                     │
                     ▼
          platform user data directory
```

Gameplay never imports a storage codec and the storage layer never imports
gameplay types.

## Why `NucleusSave` is an Autoload

Storage configuration, credentials and slot operations are application-wide and
must survive scene changes.

Snapshot ownership is different: the current game's state belongs to a game
session, so `NucleusSaveSession` is scene-owned rather than another global
manager.

## Save contract

Payloads are Dictionaries whose keys are String or StringName.

Supported values are Godot Variant data except:

```text
Object
Callable
Signal
RID
```

Nucleus intentionally does not serialize live Nodes, Resources or arbitrary
Objects. Save data should describe state, not capture runtime object graphs.

This also avoids object-deserialization code execution risks.

## Formats

### Binary Variant — default

Extension:

```text
.nsav
```

Implementation:

```gdscript
var_to_bytes()
bytes_to_var()
```

Advantages:

- Compact.
- Fast.
- Preserves Godot built-in Variant types.
- Best general-purpose production format.

Objects are not serialized.

### Text Variant

Extension:

```text
.nsv
```

Implementation:

```gdscript
var_to_str()
str_to_var()
```

Advantages:

- Human-readable.
- Preserves Godot-specific Variant syntax such as Vector3 and Color.
- Useful during development and debugging.

### JSON

Extension:

```text
.json
```

Advantages:

- Interoperable with external tools and services.
- Easy to inspect.

Tradeoff:

JSON cannot faithfully represent Godot-specific Variant types. The codec
therefore rejects unsupported payloads instead of silently coercing them.

Use JSON only when the game's save schema is intentionally JSON-compatible.

## Encryption

Encryption is orthogonal to the codec.

Modes:

```text
NONE
PASSWORD
RAW_KEY
```

Encrypted filenames make their required credential type explicit:

```text
manual.nsav.pwd
manual.nsav.key
```

Password mode uses Godot's `FileAccess.open_encrypted_with_pass()`.

Raw-key mode uses `FileAccess.open_encrypted()` and requires exactly 32 bytes.

Credentials exist only in `NucleusSaveSecurity` at runtime. They are never
stored in Resources, ProjectSettings or save files.

Example:

```gdscript
NucleusSave.configure_password(user_password)
```

or:

```gdscript
NucleusSave.configure_raw_key(key_32_bytes)
```

### Security boundary

A secret embedded in a shipped game executable can eventually be extracted.
Raw-key encryption is therefore useful mainly against casual save inspection or
editing unless the key comes from an external secure source.

Password mode can provide a genuine user-held secret.

Save data must never be treated as a safe place for credentials, API keys or
other high-value secrets.

## Integrity

Every save contains a SHA-256 digest over a canonicalized copy of its contents.

When encryption credentials exist, the document also includes HMAC-SHA256 using
a derived integrity key.

This provides:

```text
SHA-256     accidental corruption detection
HMAC-SHA256 keyed authenticity/integrity
```

Integrity is checked before migrations or gameplay restore callbacks run.

## Transactional writes and backups

Manual and quick saves use:

```text
new document
     │
     ▼
manual.nsav.tmp
     │
     ├── manual.nsav      → manual.nsav.bak1
     ├── manual.nsav.bak1 → manual.nsav.bak2
     ▼
manual.nsav
```

The default profile retains two backups, and replaceable saves require at least one backup.

If the primary save is corrupt or unreadable, backups are tried in order and
`NucleusSaveResult.recovered_from_backup` reports recovery.

Autosaves are immutable rotating snapshots, so they do not create per-file
backup chains.

## Directory layout

Example:

```text
<OS.get_user_data_dir()>/saves/
└── slot_1/
    ├── manual.nsav
    ├── manual.nsav.bak1
    ├── manual.nsav.bak2
    ├── quick.nsav
    └── autosaves/
        ├── auto_1791033421000.nsav
        ├── auto_1791033541000.nsav
        └── auto_1791033661000.nsav
```

Each slot is isolated in its own directory.

## Schema migrations

`NucleusSaveProfile.schema_version` is the current game-save schema.

A breaking change is represented by a game-defined Resource subclass:

```gdscript
extends NucleusSaveMigration

func migrate(
    payload: Dictionary,
    metadata: Dictionary,
) -> Error:
    payload["player"]["health"] = payload["player"].get(
        "hp",
        100,
    )
    payload["player"].erase("hp")

    return OK
```

Configure:

```text
1 → 2
2 → 3
3 → 4
```

The pipeline requires a complete deterministic path to the current schema.

Saves from a newer schema than the running game are rejected rather than
guessed at.

Successfully migrated manual/quick saves can be rewritten automatically using
the current schema while preserving backups.

## Scene-owned save session

A game scene can contain:

```text
GameSession
└── SaveSession : NucleusSaveSession
```

Participants register explicitly:

```gdscript
save_session.register_participant(
    &"player",
    _capture_player,
    _restore_player,
)
```

Capture:

```gdscript
func _capture_player() -> Dictionary:
    return {
        "position": player.global_position,
        "health": player.health,
    }
```

Restore:

```gdscript
func _restore_player(data: Dictionary) -> void:
    player.global_position = data["position"]
    player.health = data["health"]
```

This replaces Vault's global SceneTree group convention.

There is no hidden:

```text
call_group("save_nodes", "on_save")
```

dependency.

## Late participant registration

Loaded payload is retained by the session.

If a participant registers after loading a scene, its restore callback receives
the pending data immediately. This supports scene instantiation order without
global event buses.

## Autosave

`NucleusAutosavePolicy` defaults to:

```text
enabled                    true
interval                   120 seconds
rotation                   3 saves
on application pause       true
on graceful quit           true
on focus loss              false
minimum interval           5 seconds
```

The timer ignores game time scale, so pausing gameplay does not stall the
autosave schedule.

Lifecycle autosaves are synchronous and bypass the normal autosave cooldown because mobile pause/termination callbacks have a limited execution window.

Focus-loss autosave is disabled by default because alt-tabbing can happen often
and should not create unnecessary disk writes.

## Manual, quick and auto saves

```gdscript
save_session.save_manual()
save_session.save_quick()
save_session.autosave()

save_session.load_manual()
save_session.load_quick()
save_session.load_latest_autosave()
```

The same snapshot model is used for every kind.

## Metadata

Game-specific slot presentation belongs in `metadata`, for example:

```gdscript
save_session.set_metadata_provider(
    func() -> Dictionary:
        return {
            "display_name": "Chapter 4",
            "playtime_seconds": playtime,
            "scene_id": current_scene_id,
        }
)
```

Core metadata such as engine version, game version, schema, timestamps and save
kind are written automatically.

Hardware details are deliberately not collected.

## Barebone/Vault concepts salvaged

Retained:

- Strategy-based file formats.
- Slot-oriented saves.
- Autosave concept.
- Version information.
- Encryption as an optional storage concern.

Rebuilt:

- Autosave is implemented rather than TODO.
- `file_path` arguments are respected.
- Loading does not load the same file twice.
- Format detection is extension-based, not enum-vs-extension comparison.
- Save writes are transactional with backup recovery.
- Schema migration is explicit.
- Game state registration is scoped to `NucleusSaveSession`.
- Encryption credentials are runtime-only.
- No hardware fingerprint metadata.
- JSON type loss is rejected rather than silently accepted.

## Recommended production defaults

```text
Format               Binary Variant
Encryption           None unless the project has a real requirement
Manual backups       2
Autosave rotation    3
Autosave interval    120 seconds
Pause autosave       Enabled
Quit autosave        Enabled
Focus-loss autosave  Disabled
Schema version       Start at 1
```

Enable encryption because a game needs it, not simply because the option exists.


## Platform-specific save root

The default save root is resolved at runtime with:

```gdscript
NucleusPaths.saves_directory()
```

which derives from `OS.get_user_data_dir()`.

This avoids hardcoding Windows/Linux paths while still using Godot's
project-specific writable storage location. On Web this resolves to the
browser-managed virtual filesystem.
