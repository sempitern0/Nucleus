# Optional Inventory and Equipment Module

## Status

`modules/inventory` is optional and is not loaded by default.

It provides reusable item identity, runtime stacks, scene-owned inventory,
equipment slots, Attribute integration, GameplayAction adapters, and
capture/restore state.

It does not define a game's RPG taxonomy, crafting rules, loot rules, UI, world
pickups, weapon logic, or economy.

## Design lineage

Barebone contained useful inventory concepts:

```text
stable item IDs
stack limits
stack overflow
unit weight
slot limits
```

Those concepts are retained.

Barebone also used a global InventoryManager Autoload and stored mutable amount
inside the same Resource that described the item. Nucleus deliberately does not
retain those boundaries.

The Nucleus data flow is:

```text
NucleusItemDefinition
        ↓
NucleusItemStack
        ↓
NucleusInventory
```

Definitions are design-time data. Stack quantity/state is runtime data.

## Item definitions

`NucleusItemDefinition` contains only broadly reusable metadata:

```text
item_id
display_name
description
icon
max_stack_size
unit_weight
tags
```

There are intentionally no built-in enums for:

```text
weapon type
material type
rarity
quest category
consumable type
crafting family
```

Those taxonomies differ substantially between games. Use tags or game-specific
Resource subclasses.

## Catalog

`NucleusItemCatalog` is an explicit Resource containing known definitions.

It provides:

```text
item ID lookup
tag lookup
duplicate/invalid ID validation
persistence resolution
```

It is not an Autoload and does not perform runtime discovery.

A game may share one catalog Resource between Inventory, Equipment, Loot, UI,
and persistence without creating a global manager.

## Runtime stacks

`NucleusItemStack` owns:

```text
stack_id
definition reference
amount
state Dictionary
```

`stack_id` is generated with `NucleusUuid.v4()`.

`state` is intentionally game-owned. Examples:

```text
durability
generated affixes
quality seed
paint/customization
ammo subtype
instance metadata
```

Stacks merge only when:

```text
item_id matches
AND
state matches
AND
definition is stackable
```

A non-stackable item therefore naturally becomes an individually addressable
runtime instance.

## Inventory ownership

`NucleusInventory` is a scene-owned Node.

It supports optional:

```text
max_slots
max_weight
```

Zero means unlimited.

There is no Inventory Autoload. A player, chest, vendor, vehicle, corpse, or
crafting station may each own a normal Inventory node.

This also avoids multiplayer authority ambiguity: network ownership remains with
the actor/container that owns the Inventory.

## Addition/removal semantics

`add_item()` returns how many requested units were accepted.

It:

1. applies remaining weight capacity;
2. fills compatible existing stacks;
3. creates new stacks while slot capacity permits.

`remove_item()` removes by item ID.

`remove_from_stack()` targets one exact runtime stack.

This keeps generic Inventory independent from drag/drop, equipment transfer, and
world-pickup rules.

## Equipment definitions

`NucleusEquipmentItemDefinition` extends `NucleusItemDefinition` with:

```text
valid_slots
attribute_modifiers
```

`NucleusEquipmentSlotDefinition` filters equipment with:

```text
slot_id
accepted_tags
blocked_tags
```

There are no hard-coded Head/Chest/Weapon enums.

Examples may use:

```text
main_hand
off_hand
head
body
tool
trinket_1
```

but games define their own slot IDs.

## Equipment ownership

`NucleusEquipment` is scene-owned.

When an Inventory is assigned, Equipment may reference an exact `stack_id` using:

```gdscript
equipment.equip_inventory_stack(
	&"main_hand",
	stack_id,
)
```

The stack remains in Inventory.

This is intentional because games disagree on whether equipped items occupy
inventory space. Nucleus avoids imposing transfer semantics.

A game that wants "remove from bag while equipped" should add a small project
adapter around these APIs.

If the referenced stack is removed from Inventory, Equipment automatically
unequips it.

## Attribute integration

Equipment reuses `NucleusAttributeSet` source-owned modifiers.

Each occupied slot owns one source:

```text
equipment:<slot_id>
```

Equipping applies the item's modifiers.

Unequipping removes only that slot's source.

Therefore Equipment composes with existing sources such as:

```text
status effects
difficulty
perks
temporary buffs
future systems
```

without rewriting base values or removing another producer's contribution.

## GameplayAction integration

The module includes:

```text
NucleusInventoryItemRequirement
NucleusInventoryItemCost
```

Requirement checks quantity without side effects.

Cost participates in the existing transactional action pipeline and supports
refund.

The generic cost consumes by `item_id` and is intended for fungible items such
as:

```text
ammo
keys
currency tokens
crafting resources
consumables
```

A unique/stateful item that must select one exact instance should use a
game-specific `NucleusActionCost` targeting a stack ID.

## Persistence

Both runtime owners expose:

```text
capture_state()
restore_state()
```

Inventory state stores:

```text
stack_id
item_id
amount
state
```

Equipment state stores:

```text
slot_id
item_id
stack_id
```

Definitions themselves are not serialized into save data.

Register explicitly with `NucleusSaveSession`:

```gdscript
save_session.register_participant(
	&"player_inventory",
	inventory.capture_state,
	inventory.restore_state,
)

save_session.register_participant(
	&"player_equipment",
	equipment.capture_state,
	equipment.restore_state,
)
```

Restore Inventory before Equipment when applying data manually.

`NucleusSaveSession` already holds pending payload for participants that register
later, so scene-owned actors can still register after a save has been loaded.

## Restore and capacity changes

Inventory restore does not enforce current slot/weight limits.

That is deliberate.

A balance patch reducing bag capacity must not silently delete items from an
existing save. Runtime add operations respect capacity; loaded ownership is
preserved.

If an item ID no longer exists in the catalog, restore skips it and returns the
missing IDs so the game/migration layer can diagnose or migrate them.

## Networking boundary

This module is network-agnostic.

Do not replicate `NucleusInventory` nodes automatically.

For multiplayer:

```text
server/authority validates mutation
→ authoritative Inventory changes
→ game replication layer transmits state/delta
```

Client UI may predict presentation, but inventory/equipment ownership and
anti-cheat rules belong to the game's networking layer.

## What this module does not own

Not included:

```text
inventory UI
drag/drop
grid/Tetris inventories
crafting recipes
shops/economy
loot generation
world pickups
drop spawning
durability rules
weapon behavior
rarity
item use effects
quest item policy
replication/RPCs
```

Those systems can integrate through item IDs, tags, stack IDs, and signals
without changing Inventory's storage contract.
