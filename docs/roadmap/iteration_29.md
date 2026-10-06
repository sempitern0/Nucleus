# Iteration 29 — Development Tools / Command Palette

## Goal

Turn recurring temporary debug actions into a reusable, explicit development
workflow without adding a global CheatManager or arbitrary runtime reflection.

Prepared as a cumulative delta on top of repository baseline:

```text
main
8165ef2ea416d959b25e9fbcad981ffdac8ecced
```

The package also contains Iteration 28 because that iteration is not yet present
on GitHub main.

## Delivered

```text
modules/development_tools
    NucleusDevelopmentCommandArgument
    NucleusDevelopmentCommand
    NucleusDevelopmentCommandResult
    NucleusDevelopmentCommandRegistry
    NucleusDevelopmentCommandPalette
    NucleusDevelopmentTools

    adapters
        NucleusDevelopmentDefaultCommands
        NucleusSceneFlowDevelopmentCommands
        NucleusPerformanceDevelopmentCommands
```

Ready scene:

```text
res://modules/development_tools/development_tools.tscn
```

## Architectural boundary

The registry is an explicit allowlist. It provides discovery, parsing, typed
arguments, search, execution normalization, and history. It does not provide
reflection-based arbitrary method/property access or source evaluation.

Commands stay owned by the system that knows how to perform the operation.

```text
Development Tools
    command discovery / invocation

Scene Flow
    scene transitions

Performance
    sampling / reports / regression comparison

Game
    boat, encounter, quest, weather, economy fixtures
```

Adapters call those existing owners instead of bypassing them.

## Productivity target

The intended production loop becomes:

```text
old
    need debug action
    → create temporary button/key script
    → wire references
    → add output
    → remove/rebuild later

new
    need debug action
    → register one typed command beside its owner
    → automatically searchable/executable in the shared palette
```

This gives later scenario-runner, validation, and bug-report tooling one common
entry point instead of multiple independent debug UIs.

## Built-ins

```text
dev.context
dev.help
dev.history.clear
scene.current
scene.reload
scene.goto
```

The optional Performance bridge adds report/trace/compare/clear commands.

## Input policy

Nucleus does not assign a physical debug key. A consuming game may provide a
dedicated semantic InputMap action through `toggle_action`, or open the palette
programmatically.

## Release policy

Both shell and registry are debug-only by default. This module is local
development tooling, not a remote admin console.

## Follow-up evidence

The next high-leverage candidate is **Scene / Resource Validation** because it can
reuse this command surface while also running headlessly in CI. After that, a
reproducible scenario runner can compose Scene Flow + registered fixture commands
+ Performance reports into deterministic-enough development exercises.
