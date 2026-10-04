# Optional Probability / Loot Module

## Status

`modules/loot` is optional and is not loaded by default.

It adds reusable loot semantics on top of Godot's native
`RandomNumberGenerator`.

Nucleus deliberately does **not** wrap general PRNG functionality that Godot
already provides.

## Barebone reuse audit

Barebone contained several useful concepts:

```text
weighted selection
percentage/chance rolls
always-drop entries
unique entries
multiple rolls
result limits
deterministic seeds
```

Those concepts are retained.

The following design does not carry forward:

```text
global LootManager
mutating a shared loot-table Resource when unique loot drops
built-in rarity enum/ranges
seven combined probability modes
global table discovery
duplicated random utility functions
```

Shared Resources are treated as immutable configuration.

Runtime ownership lives elsewhere.

## Architecture

```text
NucleusLootCondition
        ↓
NucleusLootEntry
        ↓
NucleusLootTable
        ↓
RandomNumberGenerator

NucleusLootState
        ↑
NucleusLootRoller
```

Output is:

```text
NucleusLootResult
```

No Autoload is introduced.

## Why there is no NucleusProbability wrapper

Godot already provides:

```text
RandomNumberGenerator.randf()
RandomNumberGenerator.randi_range()
RandomNumberGenerator.rand_weighted()
RandomNumberGenerator.seed
RandomNumberGenerator.state
```

`rand_weighted()` directly implements weighted index selection.

Nucleus therefore owns table semantics, not PRNG algorithms.

This keeps engine behavior visible and avoids a parallel probability library.

## Loot entries

`NucleusLootEntry` contains:

```text
entry_id
payload
enabled
guaranteed
chance
weight
unique
minimum_amount
maximum_amount
tags
conditions
```

`entry_id` must be unique inside one table.

`payload` accepts any `Resource`.

Examples:

```text
NucleusItemDefinition
PackedScene
game-specific reward Resource
quest reward Resource
cosmetic definition
```

The Loot module does not import Inventory types.

## Roll modes

### WEIGHTED

Each selection cycle chooses one eligible candidate using native
`RandomNumberGenerator.rand_weighted()`.

Entries with zero weight are excluded.

### INDEPENDENT_CHANCE

Each eligible entry gets its own chance test on every selection cycle.

Boundary behavior is explicit:

```text
chance <= 0.0 → never
chance >= 1.0 → always
```

This avoids the edge case where an inclusive random value of `1.0` could make a
nominal 100% chance fail.

## Guaranteed entries

`guaranteed = true` bypasses random selection.

Guaranteed entries are emitted before random results.

By default they do not consume `maximum_random_results`.

Enable:

```text
guaranteed_count_toward_limit
```

when one total result budget is desired.

## Duplicate semantics

`allow_duplicate_entries = false` means one entry may appear at most once during
one `roll()` call.

It does not make an entry permanently unique.

For cross-roll uniqueness use:

```text
unique = true
+
NucleusLootState
```

## Runtime unique state

`NucleusLootState` tracks consumed unique entry IDs.

It exists separately from `NucleusLootTable` so a shared table can safely serve:

```text
many enemies
many chests
multiple players
server-side reward instances
parallel simulations
```

without one owner mutating the asset for every other owner.

State supports:

```text
capture_state()
restore_state()
```

## LootRoller

`NucleusLootRoller` is the scene-owned convenience runtime.

It owns:

```text
RandomNumberGenerator
NucleusLootState
```

and references a shared `NucleusLootTable`.

Seed modes:

```text
RANDOMIZED
FIXED
```

It also captures/restores both:

```text
rng.seed
rng.state
unique loot state
```

This permits an exact deterministic continuation after save/load.

## Determinism contract

A fixed seed produces a repeatable sequence within the supported Godot runtime.

Do not design saved/network protocols around the exact numerical sequence of
Godot's current PRNG algorithm.

For save continuation, persist the RNG state produced by the same engine line.

For network-authoritative loot, prefer rolling on the authority and replicating
the results rather than requiring clients to independently reproduce them.

## Conditions

`NucleusLootCondition` is a side-effect-free Resource extension point:

```gdscript
func check(context: Dictionary) -> bool:
	return true
```

Projects can implement conditions for:

```text
biome
difficulty
player level
quest state
enemy type
luck
world phase
game mode
```

without teaching Loot about those systems.

## Inventory integration

Loot does not depend on `modules/inventory`.

When both are enabled:

```gdscript
var results := loot_roller.generate()

for result: NucleusLootResult in results:
	if result.payload is NucleusItemDefinition:
		inventory.add_item(
			result.payload as NucleusItemDefinition,
			result.amount,
		)
```

The receiving game decides what happens to overflow:

```text
leave in world
spawn a pickup
send to mailbox
discard
queue reward
```

Nucleus does not silently make that policy decision.

## Networking boundary

For authoritative online play:

```text
client/server event
→ authority rolls loot
→ authority records state
→ authority applies reward
→ replication sends resolved result
```

Do not trust a client-provided loot result.

`NucleusLootRoller` itself contains no RPCs.

## Not included

```text
rarity taxonomy
magic-find/luck formula
pity systems
loot UI
world pickup spawning
inventory overflow policy
crafting
economy
drop ownership
party loot distribution
backend rewards
replication
```

Those can build on the result/condition/state contracts without expanding the
base module.
