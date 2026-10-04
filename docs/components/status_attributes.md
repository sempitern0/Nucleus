# Status Effects and Attributes

Target engine: Godot 4.7.x.

This layer adds reusable numeric modifiers and temporary gameplay state without
moving combat, movement, actions, or resources into a new monolithic system.

For editor-first setup, see:

```text
docs/guides/status_attributes_quickstart.md
```

## Architecture

```text
AttributeDefinition
        │
        ▼
NucleusAttributeSet
        ▲
        │ modifier sources
        │
StatusEffectContainer
        ▲
        │
GameplayAction ── ApplyStatusEffect

AttributeSet
    │
    ├── AttributePropertyBinding ──→ any numeric property
    │
    └── ValuePoolAttributeBinding ─→ NucleusValuePool limits

StatusEffectContainer
    │
    ├── StatusDamageTicker ────────→ NucleusDamageReceiver
    ├── StatusValuePoolTicker ─────→ NucleusValuePool
    ├── StatusActionGate ──────────→ NucleusActionSet
    └── StatusRequirement ─────────→ one GameplayAction
```

Everything is scene-owned.

## Attributes are not resources such as health

`NucleusAttributeSet` stores calculated numeric characteristics such as:

```text
move_speed
damage_multiplier
armor
critical_chance
max_health
stamina_regeneration
interaction_range
```

`NucleusValuePool` still owns mutable quantities such as:

```text
current health
current mana
current stamina
fuel
oxygen
```

A maximum health attribute may drive a Health ValuePool maximum through
`NucleusValuePoolAttributeBinding`.

This distinction prevents one "Stats" object from becoming responsible for both
character rules and runtime resource state.

## Attribute definitions

`NucleusAttributeDefinition` is immutable design metadata:

```text
id
base value
optional minimum
optional maximum
```

Runtime base values live in `NucleusAttributeSet`.

This mirrors the existing Nucleus pattern of separating definition metadata from
mutable state.

## Modifier sources

Modifiers are not individually appended/removed from a global list.

They are owned by a stable `source_id`:

```text
status:poison
equipment:iron_boots
perk:runner
difficulty:hard
```

A source atomically supplies:

```text
Array[NucleusAttributeModifier]
stack count
```

Removing that source removes exactly its contribution.

This avoids the common failure mode where two systems create numerically equal
modifiers and one system accidentally removes the other's modifier.

## Modifier operations

Evaluation order is fixed and documented:

```text
1. base value
2. ADD
3. ADD_PERCENT
4. MULTIPLY
5. OVERRIDE
6. attribute clamp
```

Formula before override/clamp:

```text
(base + flat_add)
    * (1 + sum(add_percent))
    * product(multiply)
```

Example:

```text
base = 100
ADD +10
ADD_PERCENT +0.20
MULTIPLY 1.5

result = 198
```

`MULTIPLY` uses multiplication rather than "percentage multiplier" semantics.

Examples:

```text
0.75 → reduce to 75%
1.20 → increase to 120%
```

## Stack scaling

Each modifier chooses whether it scales with status/source stacks.

For `ADD` and `ADD_PERCENT`:

```text
effective = value * stacks
```

For `MULTIPLY`:

```text
effective = value ^ stacks
```

Example:

```text
0.9 slow × 3 stacks
→ 0.9³
→ 0.729
```

`OVERRIDE` does not scale with stacks.

## Overrides

Multiple overrides are resolved by:

```text
higher priority
then deterministic source/index ordering
```

This keeps calculation independent of Dictionary traversal order.

Overrides should be uncommon. Prefer arithmetic modifiers whenever possible.

## Generic property binding

`NucleusAttributePropertyBinding` uses Godot's native:

```gdscript
Object.set_indexed()
```

to push one effective attribute into an existing property.

Examples:

```text
move_speed
→ NucleusCharacterMotor3D.speed

damage_taken_multiplier
→ NucleusDamageReceiver.damage_multiplier

camera_response
→ project-specific camera property
```

The Attribute system therefore does not import or depend on movement/combat
classes.

If a target needs domain-specific invariants, use a specialized adapter instead
of a generic property write.

`NucleusValuePoolAttributeBinding` is such an adapter: it calls
`ValuePool.set_limits()` so clamping/signals remain correct.

## Attribute persistence

`NucleusAttributeSet.capture_state()` stores only base values.

Runtime modifier sources are intentionally not stored there.

Their owner restores them:

```text
StatusEffectContainer
Equipment system
Perk system
Difficulty system
```

This avoids restoring a calculated modifier twice.

## Status definitions

`NucleusStatusEffectDefinition` is a Resource containing:

```text
effect id
tags
duration
time-scale policy
persistence policy
reapply/stack policy
tick interval
attribute modifiers
```

Visuals, particles, sounds, animation, and AI reactions are not embedded in the
definition. Consumers observe the container signals.

## Duration

```text
duration > 0
    timed effect

duration <= 0
    permanent until explicitly removed
```

Normal effects use gameplay time.

`ignore_time_scale` uses `Time.get_ticks_usec()` so an effect can continue in
real time even if gameplay time scale changes or the SceneTree is paused.

Use this deliberately. Most gameplay buffs/debuffs should respect gameplay
pause.

## Reapply policies

### REFRESH

One stack.

Reapplying resets its remaining duration.

### ADD_STACK_REFRESH

Adds a stack up to `maximum_stacks`, then refreshes every stack.

Useful when all stacks conceptually share one expiry.

### ADD_STACK_INDEPENDENT

Every application receives its own lifetime.

When maximum stacks are reached, reapplication refreshes the stack with the
shortest remaining duration.

Useful for independent poison/burn applications.

### EXTEND_DURATION

Keeps one stack and extends the existing duration.

Useful for effects where duration accumulates but intensity does not.

## Ticks

A definition may emit:

```text
effect_ticked(active_effect)
```

at a fixed interval.

The container itself does not decide what a tick means.

Adapters provide reusable meanings:

```text
StatusDamageTicker
    → builds NucleusHitPayload
    → NucleusDamageReceiver.receive_hit()

StatusValuePoolTicker
    → changes NucleusValuePool directly
```

This distinction matters.

A damage-over-time effect should normally use `StatusDamageTicker`, because it
then respects the existing:

```text
damage multiplier
immunity tags
invulnerability
DamageReceiver signals
```

A mana regeneration status can use `StatusValuePoolTicker`.

## Status tags

Status definitions expose project-owned `StringName` tags.

Examples:

```text
negative
positive
poison
burning
silenced
rooted
crowd_control
```

Nucleus reserves none of them.

Tags support:

```text
immunity
cleanse/dispel
UI queries
Action requirements
Action blocking
damage tick filtering
```

## Action integration

### Apply

`NucleusApplyStatusEffect` derives from `NucleusActionEffect`.

An action may apply a status to:

```text
a fixed StatusEffectContainer
or
a target Node supplied in action context
```

### Requirements

`NucleusStatusRequirement` can require/block:

```text
effect ids
status tags
```

### Global actor gates

`NucleusStatusActionGate` blocks existing Actions by Action tags.

Example:

```text
status tag: silenced
blocked action tags: spell
```

No GameplayAction knows what "silenced" means.

GameplayAction now provides source-based blockers:

```text
add_blocker(id)
remove_blocker(id)
```

so multiple independent systems can block one Action safely.

### Attribute requirements

`NucleusAttributeRequirement` gates an Action by the effective value of one
Attribute.

This means a status/equipment/perk modifier can automatically change Action
availability without a bespoke bridge.

## Damage-over-time source attribution

`NucleusStatusDamageTicker` keeps the original runtime `source` from the status
application context when available.

That source is forwarded into `NucleusHitPayload`.

Runtime Node references are intentionally not serialized. After loading, a
persistent status keeps its timing/stacks but not a stale object reference.

Games that require persistent combat attribution should save a project-specific
stable entity id in their own participant data.

## Save integration

The container stores:

```text
effect id
per-stack remaining times
next tick remaining time
```

only for definitions with:

```text
persist = true
```

Definitions must be present in `known_effects` when loading so ids can resolve
back to Resources.

Recommended registration:

```gdscript
save_session.register_participant(
    &"player_attributes",
    attributes.capture_state,
    attributes.restore_state,
)

save_session.register_participant(
    &"player_statuses",
    statuses.capture_state,
    statuses.restore_state,
)
```

Restore order is safe:

- restoring Attributes recalculates current modifier sources;
- restoring Status Effects recreates their modifier sources.

## Future equipment/perk integration

The Attribute API is deliberately not status-specific.

A future equipment system can do:

```gdscript
attributes.set_modifier_source(
    &"equipment:boots",
    modifiers,
)
```

and remove that exact source on unequip.

Status Effects are therefore the first consumer of the modifier system, not its
only intended consumer.
