# Documentation Model

Nucleus documentation is part of the product surface. Repository docs should
help someone use, integrate, validate, release, or maintain the current template.
Historical planning and iteration journals live in project-management/Git
history rather than in the source template.

## User-facing documentation

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

A guide should answer:

1. What Nodes/Resources do I add?
2. Where do I add them in Godot?
3. Which Inspector fields matter?
4. How does this connect to existing Nucleus systems?
5. What does a minimal working setup look like?
6. What mistakes are likely?

Avoid implementation details unless they directly affect correct usage.

## Technical documentation

Locations:

```text
docs/components/
docs/modules/
docs/architecture/
docs/policies/
```

Component/module documents define ownership, lifetime, public API, data flow,
extension points, Godot-native dependencies, and known limitations.

Architecture documents explain dependency direction and maintainership rules.
Policies define compatibility, stability, deprecation, and versioning promises.

## One source of truth

Prefer:

```text
technical contract
    → docs/components/ or docs/modules/

editor workflow
    → docs/guides/

design/maintenance rationale
    → docs/architecture/

compatibility/stability promise
    → docs/policies/

historical planning/status
    → Git history, issues, pull requests, release notes
```

Guides may link to technical docs rather than duplicating full contracts.

## Documentation acceptance criteria

A substantial reusable component is not production-ready until:

- its API contract is documented;
- its Godot editor setup is documented;
- its relationship to adjacent Nucleus systems is clear;
- any new architectural boundary is recorded;
- affected guides/examples are updated.
