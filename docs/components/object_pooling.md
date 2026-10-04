# Object Pooling and Spawning

Target engine: Godot 4.7.x.

Iteration 15 adds scene-owned pooling for frequently created/destroyed objects.

For editor setup:

```text
docs/guides/object_pooling_quickstart.md
```

## When to use pooling

Pooling is appropriate for high-churn objects such as:

```text
projectiles
impact VFX
damage numbers
pickups
short-lived props
repeated enemies
```

Do not pool every scene by default.

`PackedScene.instantiate()` and `queue_free()` remain the correct simple solution
for objects created infrequently.

Pooling adds lifecycle/reset complexity and should earn that complexity through
reuse frequency.

## Ownership

There is no global PoolManager.

Each `NucleusObjectPool` owns:

```text
one PackedScene type
its instances
capacity policy
inactive/active bookkeeping
```

Typical scene:

```text
CombatScene
├── BulletPool : NucleusObjectPool
├── ImpactPool : NucleusObjectPool
└── Player
```

When a pool leaves the tree, it queues every instance it created for deletion,
including active instances that were reparented elsewhere.

## Capacity

Configuration:

```text
prewarm_count
maximum_size
allow_growth
auto_prewarm
```

`maximum_size = 0` means unbounded.

Example fixed pool:

```text
prewarm_count = 64
maximum_size = 64
allow_growth = false
```

Example elastic pool:

```text
prewarm_count = 16
maximum_size = 128
allow_growth = true
```

When exhausted, acquire/reserve returns `null` and emits `exhausted`.

Nucleus does not silently recycle the oldest live object because that changes
gameplay semantics.

## NucleusPoolable

A pooled scene may contain:

```text
Projectile
├── ...
└── Poolable : NucleusPoolable
```

If none exists and `auto_add_poolable` is enabled, the pool creates one at
runtime.

Adding it explicitly is recommended when project scripts need lifecycle hooks.

Signals:

```text
acquired(context)
released
release_requested
```

Use `acquired` instead of `_ready()` for behavior that must restart every time an
instance is reused.

## Automatic inactive state

`NucleusPoolable` can snapshot and restore:

```text
Node process modes
CanvasItem/Node3D visibility
CollisionShape/CollisionPolygon disabled states
RigidBody sleeping state
```

On release it can also:

```text
zero CharacterBody/RigidBody velocities
sleep RigidBodies
stop AudioStreamPlayers
stop CPU/GPU particles
```

Project-specific state is intentionally not guessed.

Examples that should be reset by project code:

```text
projectile damage
homing target
trail history
animation state
custom timers
AI blackboard
```

Connect to `acquired`/`released`.

Collision-shape changes use Godot's deferred property update because physics
callbacks may request release while the physics server is processing contacts.

## Two-phase acquire

The pool exposes:

```text
reserve()
activate()
```

in addition to convenience:

```text
acquire()
```

Two-phase acquisition exists so a spawner can:

```text
1. reserve inactive object
2. set transform
3. reset physics interpolation
4. activate object
5. emit acquired callbacks
```

Therefore gameplay setup callbacks never observe the previous spawn transform.

## 2D and 3D spawners

`NucleusSpawner2D` and `NucleusSpawner3D` share the same pool contract.

A spawner has:

```text
pool
spawn_parent
origin
local_offset
```

It sets the transform before activation and forwards a context Dictionary to the
Poolable lifecycle.

The context automatically includes:

```text
spawner
```

Project code may add:

```text
source
target
damage
team
direction
```

without the pool understanding those concepts.

## Physics interpolation

Reparented/spawned Node2D/Node3D instances reset physics interpolation.

This avoids a reused object visually interpolating from its previous transform
to the new spawn transform.

## GameplayAction integration

`NucleusSpawnActionEffect` derives from the existing `NucleusActionEffect`.

Example:

```text
FireProjectile : NucleusGameplayAction
├── AmmoCost
├── Cooldown
└── SpawnProjectile : NucleusSpawnActionEffect
```

The effect prevalidates pool capacity before the action commit.

The Action context is forwarded to the spawned object's `acquired(context)`
signal.

Therefore player and AI execution use the same spawn pipeline.

## Lifetime integration

Existing `NucleusLifetime` now has:

```text
auto_free_on_expire
```

defaulting to `true`, preserving previous behavior.

For a pooled object add:

```text
NucleusPooledLifetimeBinding
```

It:

```text
sets auto_free_on_expire = false
starts Lifetime on acquire
cancels Lifetime on release
returns Poolable to its pool on expiry
```

The original Lifetime component therefore remains the timing authority.

There is no duplicated pooled timer implementation.

## Release discipline

For instances owned by a pool, prefer:

```gdscript
poolable.request_release()
```

or:

```gdscript
pool.release(instance)
```

rather than:

```gdscript
instance.queue_free()
```

The pool defensively prunes externally freed objects, but external deletion
defeats the purpose of reuse.

## No save integration by default

A pool is runtime allocation infrastructure.

Pool availability/instance caches should generally not be persisted.

Persist the actual game state that determines what should exist, then recreate
or acquire instances when restoring the scene.

This keeps Save independent from memory-management strategy.
