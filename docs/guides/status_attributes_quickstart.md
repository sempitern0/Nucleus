# Status Effects + Attributes — Godot Editor Quickstart

Technical reference:

```text
docs/components/status_attributes.md
```

---

## 1. Add actor Attributes

Recommended tree:

```text
Player
├── Attributes : NucleusAttributeSet
├── Health : NucleusValuePool
├── CharacterMotor3D
├── Actions
└── StatusEffects
```

Attach:

```text
components/gameplay/attributes/attribute_set.gd
```

Create `NucleusAttributeDefinition` Resources for the values the project needs.

Example:

```text
move_speed
base_value = 5.0
minimum = 0.0

max_health
base_value = 100.0
minimum = 1.0
```

Do not define a universal list just because Nucleus supports Attributes. Add
only attributes your game actually consumes.

---

## 2. Bind move speed to the existing motor

Add a Node with:

```text
attribute_property_binding.gd
```

Configure:

```text
attribute_set = Attributes
attribute_id = move_speed
target = CharacterMotor3D
property_path = speed
```

Now:

```text
move_speed Attribute
→ CharacterMotor3D.speed
```

Any status/equipment/perk modifier updates movement without modifying the motor
script.

---

## 3. Bind maximum health

Add:

```text
value_pool_attribute_binding.gd
```

Assign:

```text
attribute_set = Attributes
target_pool = Health
maximum_attribute = max_health
preserve_ratio = true
```

This uses `Health.set_limits()` rather than writing its fields directly.

If the actor owns several ValuePools, assign the pool explicitly. Nucleus will
not silently choose Health/Mana/Stamina.

---

## 4. Create a Slow status Resource

Create:

```text
New Resource
→ NucleusStatusEffectDefinition
```

Example:

```text
effect_id = slow
tags = [negative, crowd_control]
duration = 4.0
reapply_policy = REFRESH
```

Add a `NucleusAttributeModifier`:

```text
attribute_id = move_speed
operation = MULTIPLY
value = 0.70
```

Result while active:

```text
5.0 movement speed
× 0.70
= 3.5
```

No slow-specific code is needed in CharacterMotor.

---

## 5. Create stacking Poison

Definition:

```text
effect_id = poison
tags = [negative, poison]
duration = 6.0
reapply_policy = ADD_STACK_INDEPENDENT
maximum_stacks = 5
tick_interval = 1.0
```

Under the actor add:

```text
StatusDamageTicker
```

Configure:

```text
status_container = StatusEffects
receiver = DamageReceiver
required_tag = poison
damage_per_stack = 2
```

Three poison stacks therefore create a six-damage `NucleusHitPayload` each
tick.

The hit passes through the normal DamageReceiver pipeline.

---

## 6. Create Silence without changing Actions

Tag spell Actions:

```text
tags = [spell]
```

Create a status:

```text
effect_id = silence
tags = [negative, silenced]
```

Add:

```text
StatusActionGate
```

Configure:

```text
status_tag = silenced
blocked_action_tags = [spell]
```

While Silence exists:

```text
spell actions → blocked
movement actions → unchanged
```

UI buttons already bound through `NucleusActionButtonBinding` receive the
availability change automatically.

---

## 7. Apply a status from GameplayAction

Under an Action add:

```text
NucleusApplyStatusEffect
```

Assign the status Resource.

For a self-buff, assign `target_container`.

For an attack/debuff, enable:

```text
resolve_from_context = true
context_target_key = target
```

Then execute with:

```gdscript
action_set.execute(
    &"poison_strike",
    {
        "source": self,
        "target": enemy,
    },
)
```

The effect locates the target's StatusEffectContainer.

---

## 8. Cleanse / dispel

Add `NucleusRemoveStatusEffects` to an Action.

Examples:

```text
tags = [negative]
```

removes every negative status, or:

```text
effect_ids = [poison]
```

removes only Poison.

`clear_all` is available for project-specific full reset actions.

---

## 9. Gate an Action by a status

Add:

```text
NucleusStatusRequirement
```

Examples:

```text
blocked_tags = [silenced]
```

or:

```text
required_effect_ids = [berserk]
```

Use `StatusActionGate` for broad tag-based actor policy and
`StatusRequirement` when one Action has a specific condition.

---

## 10. Gate an Action by an Attribute

Add:

```text
NucleusAttributeRequirement
```

Example:

```text
attribute_id = strength
use_minimum = true
minimum_value = 20
```

A strength buff can now make the Action become available automatically.

---

## 11. Use Attribute modifiers outside Status Effects

The modifier runtime is intentionally reusable:

```gdscript
attributes.set_modifier_source(
    &"equipment:boots",
    boot_modifiers,
)

attributes.remove_modifier_source(
    &"equipment:boots",
)
```

A future Equipment system should use this API instead of inventing another stat
calculation layer.

---

## 12. Save Attributes and statuses

Ensure persistent definitions are present in:

```text
StatusEffects.known_effects
```

Then:

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

Base attributes and remaining status stack/tick times are persisted.

Runtime Node references from application context are not persisted.
