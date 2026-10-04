# Iteration 21 — Optional Inventory / Equipment

## Objective

Begin the post-Core optional-module phase with a cross-genre item ownership and
equipment layer that composes with existing Nucleus contracts.

The module must remain removable and must not add an Autoload.

## Audited base

Prepared read-only against:

```text
sempitern0/Nucleus
main
f113c12fb6b6e2b8944d0c2d9ff5d8986fc44404
```

## Barebone reuse audit

Barebone inventory provided useful concepts:

```text
item ID
stack limit
stack overflow
unit weight
slot capacity
```

These survive.

The following do not:

```text
global InventoryManager Autoload
mutable amount stored in item-definition Resource
large built-in material/category enums
usable/single_use/drop policy
inventory-grid item size
game-specific pickup semantics
```

Those decisions are either architecturally incompatible with Nucleus or too
game-specific for a general module.

## Architecture

```text
NucleusItemDefinition
        ↓
NucleusItemStack
        ↓
NucleusInventory

NucleusEquipmentItemDefinition
        ↓
NucleusEquipmentSlotDefinition
        ↓
NucleusEquipment
        ↓
NucleusAttributeSet modifier sources
```

`NucleusItemCatalog` provides explicit ID resolution for all of these.

No service locator and no runtime global registry are introduced.

## Runtime identity

Every stack/instance receives:

```text
NucleusUuid.v4()
```

This allows non-stackable/stateful items to be referenced by Equipment and
future systems without using Node paths or Resource object identity.

## Persistence

Inventory and Equipment expose capture/restore APIs compatible with
`NucleusSaveSession.register_participant()`.

Definitions stay in Resources; save data stores IDs and runtime state.

## GameplayAction integration

The module adds:

```text
NucleusInventoryItemRequirement
NucleusInventoryItemCost
```

These reuse the established action pipeline rather than adding an item-use
execution framework.

The generic cost is intentionally limited to fungible item-by-ID consumption.
Unique-instance behavior remains an extension point.

## Equipment / Attributes

Equipment never changes Attribute base values.

Each occupied slot becomes a source-owned overlay:

```text
equipment:<slot_id>
```

This preserves composition with status effects, perks, difficulty, and any other
modifier producer.

## Networking boundary

The module is replication-neutral.

In multiplayer, Inventory/Equipment should normally be authoritative on the
server/owning peer and replicated by game-specific RPC/state logic.

No inventory networking protocol is added to `modules/networking`.

## Version

The development version advances:

```text
0.2.0-dev.1
→
0.3.0-dev.1
```

This is an additive pre-1.0 public module.

## Validation

Headless tests cover:

```text
catalog duplicate IDs
stack/slot capacity
weight limits
per-stack state separation
stack identity persistence
GameplayAction requirement/cost
equipment slot filters
Attribute modifiers
automatic unequip on stack removal
equipment capture/restore
```

CI remains the authoritative Godot parser/runtime/export gate.

## Recommended optional-module sequence

After Inventory / Equipment:

1. Probability / Loot
2. Persistent World Identity
3. AI / Navigation helpers
4. Save-slot presentation UI
5. online gameplay replication
6. platform services
7. dialogue / quests
8. world streaming

This sequence is dependency-driven rather than feature-driven.

Loot can emit item IDs/definitions.

Persistent identity then gives world containers/drops stable save identities.

AI/navigation is largely independent and should remain a thin Godot-native
composition layer.

The later modules are more game/service-specific and need stronger evidence.
