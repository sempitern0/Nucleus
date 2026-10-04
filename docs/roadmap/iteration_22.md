# Iteration 22 — Optional Probability / Loot

## Objective

Add a deterministic, scene-owned loot layer without duplicating Godot's native
random-number APIs or introducing a global Loot manager.

## Audited base

Prepared read-only against:

```text
sempitern0/Nucleus
main
48615c952e731cd95f7685aa47167078211340a0
```

The Inventory / Equipment compile fix is present in that tree.

## Barebone reuse audit

Barebone provided useful concepts:

```text
weighted selection
chance rolls
always-drop entries
unique rewards
multiple rolls
result limits
seeded randomness
```

These remain useful.

The following are intentionally discarded:

```text
global LootManager
shared Resource mutation for unique loot
hard-coded rarity enum/ranges
seven Cartesian combined probability modes
duplicated probability/random helpers
table discovery through global state
```

## Godot-native reuse

Godot 4.7 `RandomNumberGenerator` already provides:

```text
randf
randi_range
rand_weighted
seed
state
randomize
```

Nucleus therefore does not implement a parallel weighted picker or generic PRNG
wrapper.

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

Output:

```text
NucleusLootResult
```

The Resource graph is immutable-by-convention.

Runtime unique state and RNG state belong to the roller/owner.

## Modes

```text
WEIGHTED
INDEPENDENT_CHANCE
```

More complex game probability models should be composed from tables, conditions,
or game-specific Resources rather than expanding a combinatorial mode enum.

## Inventory boundary

Loot has no compile-time dependency on Inventory.

A loot entry accepts any `Resource` payload.

When both modules are active, an item definition can be used directly as a
payload and the game decides how to handle Inventory overflow.

## Persistence

`NucleusLootRoller.capture_state()` stores:

```text
rng seed
rng state
consumed unique entry IDs
```

Restore sets seed before RNG state, following Godot's RNG contract.

This supports exact continuation within the supported engine line.

## Networking

Loot generation is replication-neutral.

For authoritative online games, roll on the authority/server and replicate the
resolved outcome rather than trusting clients to self-report rewards.

## Version

Development version:

```text
0.3.0-dev.1
→
0.4.0-dev.1
```

## Validation

Headless tests cover:

```text
duplicate entry validation
seeded weighted determinism
zero-weight exclusion
0% / 100% chance boundaries
duplicate suppression
guaranteed result budgets
unique-state persistence
amount ranges
exact RNG continuation after restore
```

CI remains the authoritative parser/runtime/export gate.

## Next optional module

The natural next module is:

```text
Persistent World Identity
```

Inventory now provides runtime stack identity and Loot provides deterministic
reward state.

Persistent World Identity should solve the complementary world problem:

```text
which world object is this?
has it been consumed/destroyed/opened?
where does its persistent state belong?
```

It must remain scene-owned/explicitly registered with Save rather than becoming
a global object database.
