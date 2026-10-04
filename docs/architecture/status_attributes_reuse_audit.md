# Status Effects + Attributes — Reuse Audit

Iteration 14 was designed against the current Nucleus main after Gameplay
Actions passed Godot runtime validation.

## Existing Nucleus systems reused

### Gameplay Actions

Status application/removal are `NucleusActionEffect` implementations.

Status restrictions derive from `NucleusActionRequirement`.

`NucleusStatusActionGate` uses Action tags and the new source-based blocker API
rather than mutating `action.enabled`.

This distinction allows:

```text
stun system blocker
cutscene blocker
status blocker
game rule blocker
```

to coexist without one system accidentally re-enabling an Action still blocked
by another.

### ValuePool

Attributes do not replace `NucleusValuePool`.

A specialized binding drives ValuePool limits through:

```gdscript
set_limits()
```

Periodic resource status effects use the existing increase/decrease API.

### DamageReceiver

Damage-over-time is routed through:

```text
NucleusHitPayload
NucleusDamageReceiver
```

rather than subtracting Health directly.

Existing damage multipliers, immunity tags, invulnerability, and signals still
apply.

### Movement

Attributes can drive motor properties through
`NucleusAttributePropertyBinding`.

No speed/status fields are added to movement motors.

Example:

```text
move_speed Attribute
    ↓
PropertyBinding
    ↓
CharacterMotor3D.speed
```

### Save

AttributeSet and StatusEffectContainer expose explicit snapshot APIs compatible
with `NucleusSaveSession`.

Neither discovers the Save Autoload.

### Utilities

Tag overlap uses:

```text
NucleusArrayUtils.intersects()
```

Tag merging uses:

```text
NucleusArrayUtils.unique()
```

Scene discovery uses:

```text
NucleusNodeUtils
```

Diagnostics use:

```text
NucleusLog
```

### Godot native APIs

Generic property adaptation uses:

```text
Object.set_indexed()
NodePath
```

Real-time status timing uses:

```text
Time.get_ticks_usec()
```

Nucleus does not create reflection or clock abstractions for APIs Godot already
provides correctly.

## Barebone audit

Barebone did not contain a reusable modifier/status runtime.

Its stats area contained game-specific concepts such as elemental resistances,
critical damage ranges, and negative-status resistances.

Those concepts belong to a game's combat model, not a universal template.

Iteration 14 therefore keeps only the broad idea that status resistance/stat
composition is useful, and rebuilds the mechanism around generic ids,
modifiers, tags, and adapters.

## Why Attributes are source-based

A naive modifier system often exposes:

```text
add_modifier(modifier)
remove_modifier(modifier)
```

This becomes ambiguous when equivalent modifiers come from multiple systems.

Nucleus instead exposes:

```text
set_modifier_source(source_id, modifiers, stacks)
remove_modifier_source(source_id)
```

Ownership is explicit.

This also fits future:

```text
equipment
perks
difficulty
auras
status effects
temporary world zones
```

without another modifier runtime.

## Why StatusEffectDefinition is a Resource

Status metadata is authored once and reused by many actors.

Runtime state is not stored in the Resource.

Each actor owns a `NucleusActiveStatusEffect` containing:

```text
stack timers
tick timer
runtime context
```

This avoids shared mutable Resource state.

## Why there is no global StatusEffectManager

Statuses belong to an actor.

A global manager would need to rediscover:

```text
actor ownership
lifetime
save ownership
multiplayer identity
scene cleanup
```

that the SceneTree already expresses.

Each actor owns its own container.

## Why no built-in "poison", "stun", or "silence"

These are game rules.

Nucleus provides the mechanisms to express them:

```text
poison
    status tag + tick → DamageReceiver

slow
    status modifier → move_speed Attribute

silence
    status tag → Action tag gate

stun
    status requirement/gate or project FSM transition
```

The template does not reserve their ids or balancing semantics.
