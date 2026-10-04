# Object Pooling — Godot Editor Quickstart

Technical reference:

```text
docs/components/object_pooling.md
```

---

## 1. Prepare a pooled projectile scene

Example:

```text
Projectile : CharacterBody3D
├── CollisionShape3D
├── MeshInstance3D
├── Lifetime
├── Poolable
└── PooledLifetime
```

Attach:

```text
Lifetime
    components/gameplay/lifecycle/lifetime.gd

Poolable
    components/gameplay/pooling/poolable.gd

PooledLifetime
    components/gameplay/pooling/pooled_lifetime_binding.gd
```

`PooledLifetime` will disable Lifetime's normal `queue_free()` behavior and
return the projectile to the pool instead.

Project scripts should reset reusable state from:

```gdscript
%Poolable.acquired.connect(_on_acquired)
%Poolable.released.connect(_on_released)
```

Example:

```gdscript
func _on_acquired(context: Dictionary) -> void:
    target = context.get("target")
    damage = float(context.get("damage", 10.0))
```

---

## 2. Add a pool to the gameplay scene

Tree:

```text
Level
├── ProjectilePool
└── Player
```

Attach to `ProjectilePool`:

```text
components/gameplay/pooling/object_pool.gd
```

Assign:

```text
packed_scene = Projectile.tscn
prewarm_count = 32
maximum_size = 128
allow_growth = true
```

For a fixed-budget pool:

```text
prewarm_count = 64
maximum_size = 64
allow_growth = false
```

---

## 3. Add a 3D spawn point

Tree:

```text
Weapon
└── Muzzle : Marker3D
    └── ProjectileSpawner : Node
```

Attach:

```text
components/gameplay/pooling/spawner_3d.gd
```

Assign the ProjectilePool.

The parent Marker3D is automatically used as `origin`.

Spawn:

```gdscript
var projectile: Node = %ProjectileSpawner.spawn(
    {
        "source": self,
        "target": target,
        "damage": 25.0,
    },
)
```

The instance receives its new transform before `Poolable.acquired` is emitted.

---

## 4. 2D is identical

Use:

```text
Marker2D
└── Spawner
```

with:

```text
components/gameplay/pooling/spawner_2d.gd
```

The pool implementation itself is dimension-agnostic.

---

## 5. Spawn from GameplayAction

Action tree:

```text
FireProjectile : NucleusGameplayAction
├── AmmoCost
├── Cooldown
└── SpawnProjectile
```

Attach to `SpawnProjectile`:

```text
components/gameplay/pooling/spawn_action_effect.gd
```

Assign the spawner.

Now the same action pipeline validates:

```text
requirements
cost
cooldown
pool capacity
```

before committing.

AI can call the same ActionSet action as the player.

---

## 6. Return manually

From the pooled object's script:

```gdscript
func on_impact() -> void:
    %Poolable.request_release()
```

Do not call `queue_free()` for normal pooled lifecycle.

---

## 7. Poolable automatic reset

By default Poolable handles common engine state:

```text
processing
visibility
collision shapes
body velocity
AudioStreamPlayers
particle emission
RigidBody sleeping
```

If a particular scene must preserve one of those categories, disable the
corresponding Inspector option.

Custom state still belongs to the pooled scene script.

---

## 8. Runtime-created Poolable

For simple scenes you may omit a Poolable child and keep:

```text
auto_add_poolable = true
```

The pool adds one automatically.

Explicit Poolable nodes are preferable for projectiles/enemies where scripts
need lifecycle signals.

---

## 9. Multiple pools

When a scene contains more than one pool, assign the intended pool explicitly to
each Spawner.

Nucleus deliberately refuses ambiguous auto-discovery rather than selecting the
first matching pool.

---

## 10. Do not pool everything

Use normal instantiation for:

```text
rare bosses
menus
large one-off world scenes
objects created once per level
```

Use pooling where profiling or obvious churn justifies it.

The template should make the optimized path easy without making it mandatory.
