# AI / Navigation Quickstart

## Recommended composition

A production-oriented 3D enemy can start as:

```text
Enemy : CharacterBody3D
├── NavigationAgent3D
├── NavigationFollower : NucleusNavigationFollower3D
├── TargetingAgent : NucleusTargetingAgent
│   └── sensors / filters / scorers
├── UtilityBrain : NucleusAIUtilityBrain
│   └── TargetContext : NucleusAITargetContextProvider
├── StateMachine : NucleusStateMachine
│   ├── Idle
│   ├── Patrol
│   ├── Chase
│   ├── Attack
│   └── Flee
└── AIBridge : NucleusAIStateMachineBridge
```

A simple patrol NPC may need only NavigationAgent, NavigationFollower and
NavigationWander.

## 1. Build Godot navigation first

Create/bake a native `NavigationRegion2D/3D`.

Configure the NavigationAgent for the actor:

```text
radius / height
path_desired_distance
target_desired_distance
navigation_layers
```

Nucleus does not replace navigation mesh authoring.

## 2. Configure NavigationFollower

Example 3D values:

```text
agent = NavigationAgent3D
origin = Enemy
movement_speed = 4.0
target_repath_distance = 0.75
minimum_repath_interval = 0.20
```

Static goal:

```gdscript
follower.set_target_position(destination)
```

Moving goal:

```gdscript
follower.follow_node(player)
```

The follower handles the required NavigationAgent physics update.

## 3. Move the actor

Follower does not move the body.

A simple ground state can consume:

```gdscript
var nav_velocity: Vector3 = follower.output_velocity

body.velocity.x = nav_velocity.x
body.velocity.z = nav_velocity.z

_apply_gravity()
body.move_and_slide()
```

When avoidance is enabled, `output_velocity` is the most recently computed safe
velocity. You may also cache `velocity_ready`.

This separation keeps gravity, acceleration, root motion and special movement in
the gameplay locomotion layer.

## 4. Manage goals

Stop:

```gdscript
follower.clear_target()
```

Force a new path next update:

```gdscript
follower.request_repath()
```

Following a moving Node does not reset `target_position` each frame. The
distance and interval policies throttle repathing.

## 5. Add wander/patrol

Add `NucleusNavigationWander3D` and assign the follower.

Example:

```text
radius = 15
minimum_wait = 1.5
maximum_wait = 4.0
```

For a StateMachine-driven NPC, stop Wander when leaving Patrol and restart it
when Patrol enters.

For explicit patrol routes, do not use Wander; advance authored waypoints from
the Patrol state.

## 6. Reuse targeting as perception

The existing targeting pipeline stays responsible for candidate discovery:

```text
sensors
→ filters
→ scorers
→ TargetingAgent.current
```

Add `NucleusAITargetContextProvider` under the brain and assign that
TargetingAgent.

The Utility context receives:

```text
has_target
targetable
target
target_point
target_position
target_distance
```

Changing the selected target requests immediate reevaluation.

## 7. Create utility options

Create `NucleusAIUtilityOption` Resources.

Example Chase:

```text
option_id = chase
base_score = 0.8
```

Add `NucleusAIContextBoolConsideration`:

```text
context_key = has_target
expected_value = true
```

No target now means zero Chase utility.

## 8. Attack by range

Attack option:

```text
option_id = attack
base_score = 1.0
```

Considerations:

```text
Boolean:
    context_key = has_target
    expected_value = true

Float:
    context_key = target_distance
    minimum_value = 0
    maximum_value = 10
    invert = true
```

A native Godot `Curve` can make the distance response non-linear.

## 9. Add game-specific context

For low-health fleeing:

```gdscript
class_name GameHealthAIContext
extends NucleusAIContextProvider

@export var attributes: NucleusAttributeSet
@export var maximum_health: float = 100.0


func contribute(context: Dictionary) -> void:
	var health: float = attributes.get_value(&"health")
	context[&"health_ratio"] = clampf(
		health / maxf(maximum_health, 0.001),
		0.0,
		1.0,
	)
```

When health changes, the provider may call:

```gdscript
notify_context_changed()
```

so the brain reevaluates at the next physics opportunity rather than waiting for
the normal interval.

Nucleus deliberately does not hard-code a `health` attribute ID.

## 10. Bridge Utility AI into FSM

Create `NucleusAIStateBinding` Resources:

```text
patrol → Patrol
chase  → Chase
attack → Attack
flee   → Flee
```

Assign them to `NucleusAIStateMachineBridge`.

The runtime flow becomes:

```text
context
→ UtilityBrain
→ winning option
→ bridge
→ StateMachine.change_state()
```

FSM transition rejection remains authoritative.

## 11. Chase state

A Chase state can remain small:

```gdscript
func enter(
	_previous: NucleusState,
	context: Dictionary,
) -> void:
	var target_point: Node = context.get(&"target_point")

	if target_point is Node3D:
		follower.follow_node(target_point as Node3D)


func exit(_next: NucleusState) -> void:
	follower.clear_target()


func physics_update(_delta: float) -> void:
	var velocity: Vector3 = follower.output_velocity

	body.velocity.x = velocity.x
	body.velocity.z = velocity.z
	_apply_gravity()
	body.move_and_slide()
```

Perception, decisions, path following and movement remain separate.

## 12. Native avoidance

Enable `NavigationAgent.avoidance_enabled` only for actors that need it.

Follower sends desired velocity into the agent and exposes
`velocity_computed` through `output_velocity` / `velocity_ready`.

For large crowds, profile before enabling RVO for every NPC.

## 13. Navigation links

Listen to:

```text
follower.navigation_link_reached
```

for custom traversal such as:

```text
jump gap
ladder
vault
door interaction
teleport
special animation
```

Do not call `get_next_path_position()` from the link signal handler. Follower
already advances native navigation during physics processing.

## 14. Evaluation cadence

Default:

```text
evaluation_interval = 0.25
```

is appropriate for many NPC decisions.

Use smaller intervals only where responsiveness demands it.

Important gameplay events can call:

```gdscript
brain.request_evaluation()
```

or a ContextProvider can emit `context_changed`.

## 15. Persistent AI

Persist durable state through the world-state module:

```text
WorldEntity
├── TransformState
├── StateMachineState
├── AttributesState
└── InventoryState
```

Do not save the NavigationAgent path.

After load:

```text
durable state restored
→ UtilityBrain evaluates
→ navigation intent rebuilt
```

## 16. Multiplayer

Normally run authoritative AI on the server.

Replicate the actor state/results appropriate to the game instead of asking each
client to independently make authoritative Utility AI decisions.
