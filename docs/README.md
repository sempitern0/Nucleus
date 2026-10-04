# Nucleus Documentation

Nucleus documentation is intentionally split by audience. This prevents public
setup instructions from becoming architecture essays, while keeping internal
contracts explicit enough to maintain the framework safely.

## I want to use Nucleus in a game

Start in:

```text
docs/guides/
```

Guides are editor-first and task-oriented.

They answer questions such as:

```text
How do I create a rebinding menu?
How do I add a pooled projectile?
How do I configure lock-on?
How do I connect AnimationTree?
How do I add recoil or camera shake?
```

A guide should prefer:

```text
SceneTree examples
Inspector fields
small GDScript snippets
expected behavior
common mistakes
```

over implementation detail.

## I want to understand or extend Nucleus

Read:

```text
docs/components/
docs/architecture/
```

`components/` documents technical API contracts:

```text
ownership
signals
public methods
data flow
extension points
failure behavior
persistence boundaries
```

`architecture/` explains why the system is shaped that way:

```text
reuse audits
dependency direction
rejected alternatives
cross-system integration
Godot-native features being reused
```

## Optional modules

Read:

```text
docs/modules/
```

These systems are useful but intentionally not part of the mandatory baseline.

Examples include optional EventBus/networking infrastructure.

## Roadmap and handoff

Read:

```text
docs/roadmap/well_rounded_template.md
docs/roadmap/next_chat_context.md
docs/roadmap/plugin_horizon.md
```

`next_chat_context.md` is deliberately self-contained. It can be copied into a
new ChatGPT conversation to continue Nucleus work without rebuilding the project
context manually.

## Documentation rule for new systems

A production-facing Nucleus feature should normally ship with:

```text
docs/components/<feature>.md
    technical contract

docs/guides/<feature>_quickstart.md
    public/editor workflow

docs/architecture/<feature>_reuse_audit.md
    architectural rationale when the feature is substantial
```

If a feature changes the project direction, update:

```text
docs/roadmap/well_rounded_template.md
docs/roadmap/next_chat_context.md
```

The user guide must not require understanding the internal architecture before
the feature can be used.
