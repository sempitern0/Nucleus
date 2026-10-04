# Documentation Model

Nucleus documentation has two primary surfaces.

## Public/user-facing documentation

Location:

```text
docs/guides/
```

Audience:

```text
game developers using Nucleus
future project collaborators
developers evaluating the template
```

The primary objective is low-friction adoption.

A guide should answer:

1. What Nodes/Resources do I add?
2. Where do I add them in the Godot editor?
3. What Inspector fields matter?
4. How do I connect this to existing Nucleus systems?
5. What does a minimal working configuration look like?
6. What mistakes are likely?

Public guides should avoid requiring knowledge of:

```text
internal dictionaries
private state
algorithm implementation
why another architecture was rejected
```

unless it directly affects correct usage.

## Technical documentation

Locations:

```text
docs/components/
docs/architecture/
```

Audience:

```text
Nucleus maintainers
advanced users
contributors
future architecture work
```

Component documents define stable behavioral contracts.

Architecture documents define design rationale and dependency direction.

Technical docs should explicitly record:

```text
ownership
lifetime
thread/process assumptions
data flow
signals
persistence behavior
extension contracts
Godot-native APIs being reused
known limitations
```

## One source of truth

Do not duplicate the same explanation across several guides.

Prefer:

```text
technical detail
→ components/

editor workflow
→ guides/

design decision
→ architecture/

future work
→ roadmap/
```

Guides may link to technical docs when deeper explanation is useful.

## Documentation acceptance criteria

A substantial new component is not considered production-ready until:

- its API contract is documented;
- its Godot editor setup is documented;
- its relationship to adjacent Nucleus systems is clear;
- any new architectural boundary is written down;
- roadmap/handoff documents are updated when direction changes.

This is a documentation requirement, not an optional cleanup phase.
