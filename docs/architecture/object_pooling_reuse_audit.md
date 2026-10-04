# Object Pooling — Reuse Audit

Iteration 15 was designed against Nucleus main after Status Effects + Attributes.

## Existing Nucleus systems reused

### Node traversal

`NucleusPoolable`, spawners, and adapters use:

```text
NucleusNodeUtils.descendants()
```

No new recursive SceneTree traversal helper exists.

### Diagnostics

Misconfiguration goes through:

```text
NucleusLog
```

### Lifetime

Pooling does not create another timed-despawn component.

`NucleusPooledLifetimeBinding` adapts the existing `NucleusLifetime`.

Iteration 15 only adds `auto_free_on_expire` to Lifetime so its expiry signal can
be consumed without immediately freeing the target.

### Gameplay Actions

Spawning from abilities uses:

```text
NucleusActionEffect
```

through `NucleusSpawnActionEffect`.

There is no projectile-specific ability path.

### Physics interpolation

Spawners use Godot's existing interpolation reset when reusing Node2D/Node3D
instances.

No interpolation cache is added.

### PackedScene

The pool owns a `PackedScene` and calls native `instantiate()` only when it needs
new capacity.

Nucleus does not wrap ResourceLoader or create a scene factory service.

## Barebone audit

No coherent general-purpose object pool/spawner implementation was found worth
porting from Barebone.

The new implementation therefore follows current Nucleus ownership rules rather
than carrying legacy manager patterns forward.

## Why no global pool registry

A global registry seems convenient until scenes need:

```text
different bullet configurations
different capacity budgets
different worlds/SubViewports
local multiplayer ownership
temporary encounter pools
scene teardown
```

Scene ownership solves these naturally.

If a project genuinely needs a shared application-lifetime pool, it may place a
normal `NucleusObjectPool` below its own persistent scene owner.

Core does not need a Pool Autoload.

## Why objects are not silently recycled

An exhaustion policy such as "reuse oldest active object" can mean:

```text
despawn a projectile before impact
delete a visible VFX
replace an enemy still alive
```

That is gameplay policy.

Nucleus returns `null`/`ERR_CANT_CREATE` and lets the game choose what
exhaustion means.

## Why Poolable has automatic engine-state reset

Process, visibility, collision, velocity, audio, and particle state are common
sources of pooling bugs and are engine-level concepts.

They are reasonable generic defaults.

Game-specific state is not automatically reflected/reset because that would
turn pooling into a serializer or object-cloning framework.

## Why reserve + activate exists

Calling lifecycle callbacks before a reused projectile has its new transform is
a subtle source of bugs.

Two-phase acquisition guarantees:

```text
reserve
→ configure transform
→ activate
→ acquired signal
```

`acquire()` remains available for simpler non-spatial cases.
