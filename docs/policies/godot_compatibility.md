# Godot Compatibility Policy

## Current support contract

Nucleus currently targets the Godot 4.7 line.

The initial release-gated reference is:

```text
Godot 4.7.2-stable
```

The project metadata declares Godot 4.7 features, while CI installs and executes
4.7.2-stable for import, test, smoke, and export validation.

## Support matrix

| Godot version | Nucleus policy |
| --- | --- |
| 4.7.2-stable | Supported and CI-gated |
| Later 4.7.x patches | Expected to be compatible; promote to supported after CI validation |
| 4.7.0 - 4.7.1 | Not guaranteed |
| 4.8.x and newer minors | Unsupported until explicitly adopted |
| 4.6.x and older | Unsupported |

"Unsupported" does not mean the project is known to fail. It means Nucleus does
not make a compatibility promise for that engine line.

## Why the exact CI version matters

Godot patch releases can change parser behavior, platform exporters, warnings,
and engine internals even when project metadata still says `4.7`.

For that reason, a Nucleus release has one exact reference engine version.
Developers may use newer compatible patches locally, but a release claim is
based on what CI actually executes.

## Engine upgrade process

A Godot reference-version change requires:

1. update the pinned CI version;
2. run headless import;
3. parse the full native test graph;
4. execute regression tests;
5. run the bootstrap smoke scene;
6. smoke-export Linux, Windows, and Web;
7. review new warnings and deprecated engine APIs;
8. update this policy and `CHANGELOG.md`.

Changing to a new Godot minor line also requires an API/compatibility review and
an appropriate Nucleus version bump.

## Rendering and exports

The default project currently declares Forward Plus.

Nucleus CI smoke-exports:

```text
Linux
Windows
Web
```

Those smoke exports prove that the reusable baseline packages successfully.
They do not promise that every game-specific renderer, shader, native extension,
or platform SDK will be compatible.

## Dependencies

Nucleus prefers Godot-native APIs and does not require a third-party runtime test
framework.

Optional game plugins must maintain their own Godot compatibility contract.

## Barebone

Barebone compatibility is outside this policy. Nucleus only supports the engine
and Nucleus API contracts documented in this repository.
