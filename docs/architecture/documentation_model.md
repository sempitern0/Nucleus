# Documentation Model

Nucleus documentation is part of the product surface. Repository docs should
help someone use, integrate, validate, release, or maintain the current template.
Historical planning and iteration journals live in project-management/Git
history rather than in the source template.

## Problem-first discovery

When a human or AI describes a *game mechanic* instead of a class name, start
with the [use-case catalog](../guides/use_case_catalog.md). It maps concrete
player/designer needs to canonical ownership documentation and clearly says
what remains game-owned. The identical routes are maintained in
`docs/use_case_registry.json`, validated by `scripts/ci/use_case_audit.py`.

Read the [AI/human composition workflow](../guides/ai_composition_workflow.md)
for the behavior-to-code method, then the
[composition recipes](../guides/composition_recipes.md) for cross-system examples.
These provide **navigation**, not an alternate implementation or API.

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
coding agents operating within an actual game project
```

A guide should answer:

1. What Nodes/Resources do I add?
2. Where do I add them in Godot?
3. Which Inspector fields matter?
4. How does this connect to existing Nucleus systems?
5. What does a minimal working setup look like?
6. What mistakes are likely?
7. **Which two concrete gameplay/editor use cases justify this mechanism?**
8. **What rules and visuals must the consuming game still own?**

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
extension points, Godot-native dependencies, and known limitations. Add a short
`Use cases / Casos de uso` section when the relationship between a low-level API
and real gameplay/editor tasks is not already obvious. Give contrasting examples
of a good fit, a bad fit, and the consuming game's responsibility.

Architecture documents explain dependency direction and maintainership rules.
Policies define compatibility, stability, deprecation, and versioning promises.

## One source of truth

Prefer:

```text
technical contract
    → docs/components/ or docs/modules/

editor workflow
    → docs/guides/

behavior-to-owner routes
    → docs/use_case_registry.json + generated/use-case guide

design/maintenance rationale
    → docs/architecture/

compatibility/stability promise
    → docs/policies/

historical planning/status
    → Git history, issues, pull requests, release notes
```

Guides may link to technical docs rather than duplicating full contracts.
Use-case registry entries route to existing technical docs and must not carry
executable scripts or unverified claims of engine support.

## Documentation acceptance criteria

A substantial reusable component is not production-ready until:

- its API contract is documented;
- its Godot editor setup is documented;
- its relationship to adjacent Nucleus systems is clear;
- its *real-game use cases* and intentional non-goals are stated;
- any new architectural boundary is recorded;
- affected guides/examples and the discovery registry are updated;
- both documentation and executable tests are registered and verified.
