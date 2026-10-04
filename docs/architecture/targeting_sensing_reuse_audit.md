# Targeting + Sensing — Reuse Audit

Iteration 16 was designed after Pooling + Input Rebinding passed Godot runtime
validation.

## Existing systems reused

### Interaction

Nucleus already had the correct conceptual split:

```text
detection adapters
→ Interactor candidates
→ current Interactable
```

Targeting follows the same ownership model rather than creating a global manager.

The targeting-to-interaction adapter directly reuses:

```text
NucleusInteractionCandidateTracker
```

instead of implementing another Interactable resolver.

### Node utilities

Collider/endpoint and automatic component resolution use:

```text
NucleusNodeUtils.descendants()
NucleusNodeUtils.ancestors()
```

No new tree traversal helper exists.

### Array utilities

Target cycling uses:

```text
NucleusArrayUtils.circular_next()
NucleusArrayUtils.circular_previous()
```

Tag filters use:

```text
NucleusArrayUtils.intersects()
```

### Gameplay Actions

Targeting does not create a second ability executor.

A generic `NucleusActionContextProvider` extends Action execution adapters.

`NucleusTargetActionContext` contributes the selected target.

`NucleusTargetRequirement` uses the existing requirement contract.

This immediately composes with:

```text
Status Effects
ValuePool effects
FSM effects
Audio effects
pooled spawning
project-specific Action callbacks
```

### Input/local multiplayer

Target lock/cycle controls consume the existing:

```text
NucleusMotionInput
```

event stream.

No controller ids or joypad assignment logic appears in Targeting.

### Pooling

Targeting does not own projectile creation.

Target context flows through GameplayAction into the existing
`NucleusSpawnActionEffect`, then to the pooled object's acquire context.

### Godot physics

Broad-phase sensing uses native:

```text
Area2D
Area3D
RayCast2D
RayCast3D
```

LOS uses native direct-space ray queries.

Collision masks, layers, exceptions, and physics worlds remain Godot-owned.

### Godot camera

On-screen filtering and ranking use:

```text
Camera3D.is_position_in_frustum()
Camera3D.unproject_position()
```

No custom frustum/projection math exists.

## Candidate ownership improvement over Interaction

Targeting can combine several concurrent sensors:

```text
awareness area
weapon ray
camera cone
scripted detection
```

For that reason candidate registration is source-owned inside TargetingAgent.

A sensor removing its registration cannot remove another sensor's ownership.

This is intentionally stronger than a simple candidate Array.

## Filters versus sensors

A sensor answers:

```text
What objects did the world query discover?
```

A filter answers:

```text
Which discovered targets are valid under current game rules?
```

Keeping them separate avoids duplicating distance/angle/tag rules inside every
sensor type.

## Filters versus scorers

Filters are boolean.

Scorers are ranking.

This prevents score thresholds from becoming hidden validity rules and makes
selection configuration inspectable in the SceneTree.

## Why no TargetManager Autoload

Targeting belongs to an actor or subsystem:

```text
player
enemy AI
turret
camera system
vehicle
```

A global manager would have to reconstruct ownership, local-player identity,
world/subviewport membership, and lifetime.

Scene ownership already expresses those relationships.

## Why no faction/team system here

A faction model is useful but not universal.

Targetable tags can express lightweight project rules today:

```text
enemy
ally
neutral
```

A future faction module may implement a custom TargetFilter without changing
Targeting Core.

## Barebone audit

No coherent game-agnostic targeting/sensing layer was found in Barebone worth
porting.

Legacy target-like behavior was generally embedded inside specialized gameplay
controllers.

Iteration 16 keeps Nucleus's current direction: reusable discovery/selection
contracts with project-specific meaning layered above them.
