# Targeting + Sensing — Godot Editor Quickstart

Technical reference:

```text
docs/components/targeting_sensing.md
```

---

## 1. Make an enemy targetable

Enemy scene:

```text
Enemy : CharacterBody3D
├── CollisionShape3D
├── TargetPoint : Marker3D
└── Targetable : Node
```

Attach to `Targetable`:

```text
components/gameplay/targeting/targetable.gd
```

Assign:

```text
target = Enemy
target_point = TargetPoint
tags = [enemy]
priority = 0
```

Place TargetPoint around the chest/head area rather than necessarily using the
physics-body origin.

---

## 2. Add a player TargetingAgent

Player:

```text
Player : CharacterBody3D
├── MotionInput
├── Targeting : NucleusTargetingAgent
└── ...
```

Attach:

```text
components/gameplay/targeting/targeting_agent.gd
```

Typical third-person configuration:

```text
source = Player
origin = Player
orientation_source = CameraRig
```

For first person:

```text
orientation_source = Camera3D or ViewYaw
```

---

## 3. Add broad-phase sensing

Under Player:

```text
TargetDetection : NucleusTargetAreaSensor3D
└── CollisionShape3D
```

Attach:

```text
components/gameplay/targeting/sensors/target_area_sensor_3d.gd
```

Configure its normal Godot:

```text
collision_layer
collision_mask
CollisionShape3D
monitoring
```

Assign Player/Targeting as `agent`.

A sphere/capsule around the player is a good broad-phase for lock-on.

The Area finds physics objects; Nucleus resolves them to nearby Targetable
components.

---

## 4. Filter to enemies in front

Create child Nodes below Targeting:

```text
Targeting
├── EnemyTags
├── Range
├── Angle
└── LineOfSight
```

Attach:

```text
EnemyTags
    target_tag_filter.gd

Range
    target_distance_filter_3d.gd

Angle
    target_angle_filter_3d.gd

LineOfSight
    target_line_of_sight_filter_3d.gd
```

Example:

```text
EnemyTags.required_tags = [enemy]

Range.maximum_distance = 20

Angle.maximum_angle_degrees = 70

LineOfSight.collision_mask = world geometry + target layers
```

`rules_root` defaults to the TargetingAgent itself, so these descendants are
discovered automatically.

---

## 5. Rank by camera direction and distance

Add:

```text
Targeting
├── FacingScore
├── DistanceScore
└── ScreenCenterScore
```

Attach:

```text
target_facing_scorer_3d.gd
target_distance_scorer_3d.gd
target_screen_center_scorer_3d.gd
```

Assign Camera3D to ScreenCenterScore.

Example starting weights:

```text
FacingScore.weight = 4
DistanceScore.weight = 0.25
ScreenCenterScore.weight = 2
```

These numbers are intentionally project tuning.

There is no universal lock-on scoring formula.

---

## 6. Limit to visible camera targets

Add:

```text
NucleusTargetCameraFrustumFilter3D
```

Assign Camera3D.

Then only TargetPoints inside the camera frustum remain valid.

This pairs well with ScreenCenterScore.

---

## 7. Add lock-on controls

Create project InputMap actions if your game needs them:

```text
target_lock
target_next
target_previous
target_cancel
```

Nucleus does not add these globally.

Under Player add:

```text
TargetingInput
```

Attach:

```text
components/gameplay/targeting/integration/targeting_input.gd
```

Assign:

```text
agent = Targeting
motion_input = MotionInput

toggle_lock_action = target_lock
cycle_next_action = target_next
cycle_previous_action = target_previous
unlock_action = target_cancel
```

Because it consumes MotionInput, couch multiplayer already routes each player's
controller correctly.

---

## 8. Crosshair targeting instead of lock-on area

Add a normal Godot `RayCast3D`:

```text
Camera3D
└── AimRay : RayCast3D
    └── TargetRaySensor : Node
```

Attach:

```text
components/gameplay/targeting/sensors/target_ray_sensor_3d.gd
```

Configure AimRay's:

```text
target_position
collision_mask
collide_with_bodies
collide_with_areas
exceptions
```

The sensor contributes only the RayCast's current Targetable to TargetingAgent.

This is useful for:

```text
FPS interact/attack target
scanner
precision selection
turret
aimed abilities
```

Area and Ray sensors can feed the same agent simultaneously.

Source ownership prevents one sensor from unregistering the other's candidate.

---

## 9. Feed the target into GameplayAction automatically

Example:

```text
PoisonStrike : GameplayAction
├── TargetRequirement
├── ApplyPoison
└── ActionInput
    └── TargetContext
```

Attach:

```text
TargetRequirement
    components/gameplay/targeting/integration/target_requirement.gd

TargetContext
    components/gameplay/targeting/integration/target_action_context.gd
```

`TargetRequirement` can enforce:

```text
require_target = true
required_tags = [enemy]
```

`TargetContext` adds:

```text
context["target"]
context["targetable"]
```

before the Action executes.

If `ApplyPoison` is the existing dynamic-target Status Effect:

```text
resolve_from_context = true
context_target_key = target
```

it now receives the selected enemy automatically.

---

## 10. Fire a pooled homing projectile at the target

Action:

```text
HomingShot : GameplayAction
├── TargetRequirement
├── SpawnProjectile : NucleusSpawnActionEffect
└── ActionInput
    └── TargetContext
```

The existing pooled spawn effect forwards the same context.

Projectile:

```gdscript
func _on_poolable_acquired(context: Dictionary) -> void:
    target = context.get("target")
```

No targeting/pooling-specific projectile manager is required.

---

## 11. Target-driven interaction

Player:

```text
Player
├── Targeting
├── Interactor
└── TargetInteractionBridge
```

Attach:

```text
components/gameplay/targeting/integration/
targeting_interaction_bridge.gd
```

The bridge reuses the existing Interaction candidate tracker.

For a lock-on-only interaction system:

```text
only_when_locked = true
```

The normal `NucleusInteractionInput` continues to perform the interaction.

Targeting never calls `interact()` directly.

---

## 12. AI vision

Enemy AI:

```text
Enemy
├── TargetingAgent
├── VisionArea : TargetAreaSensor3D
├── TargetTagFilter
├── TargetAngleFilter3D
├── TargetLineOfSightFilter3D
└── TargetDistanceScorer3D
```

Configure TargetTagFilter to find the project's player/hostile tag.

Then:

```gdscript
func _on_target_changed(
    current: NucleusTargetable,
    _previous: NucleusTargetable,
) -> void:
    if current:
        state_machine.change_state(&"chase")
    else:
        state_machine.change_state(&"idle")
```

Actions can use:

```gdscript
actions.execute(
    &"attack",
    {
        "source": self,
        "target": targeting.current.get_target_node(),
    },
)
```

The AI has no separate target representation.

---

## 13. 2D setup

Use the exact same architecture with:

```text
NucleusTargetAreaSensor2D
NucleusTargetRaySensor2D
NucleusTargetDistanceFilter2D
NucleusTargetAngleFilter2D
NucleusTargetLineOfSightFilter2D
NucleusTargetDistanceScorer2D
NucleusTargetFacingScorer2D
```

2D forward is local `+X`.

If the actor art faces another direction, use a rotated Node2D as
`orientation_source`.

---

## 14. Manual scripted candidates

Sensors are optional.

A quest/scripted encounter may call:

```gdscript
targeting.register_candidate(
    boss_targetable,
    self,
)
```

and later:

```gdscript
targeting.unregister_candidate(
    boss_targetable,
    self,
)
```

Always pass the same source object.

This preserves candidate ownership alongside physical sensors.

---

## 15. Performance tuning

Good general configuration:

```text
Area sensor
    cheap broad phase

TargetingAgent.refresh_interval
    0.05–0.20 seconds

LOS
    only over broad-phase candidates
```

Do not line-of-sight raycast every entity in the level.

For twitch/precision targeting:

```text
refresh_interval = 0
```

refreshes every physics frame.

Cycling/locking from input uses the cached physics ranking, so it does not issue
LOS queries from the input callback.
