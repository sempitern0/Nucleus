# UI and Accessibility Quickstart

## Start with native Controls

Build the UI hierarchy with Godot `Control`/Container nodes first. Add Nucleus
components only for reusable production concerns such as:

```text
settings bindings
focus/navigation
presentation/data bindings
motion
feedback
modal/toast/tooltip hosts
safe-area/breakpoint layout
virtualization
screen effects
localization
accessibility behavior
```

## Focus and navigation

Use the existing focus scopes/navigation helpers for controller/keyboard
workflows. Keep Godot focus neighbors/modes authoritative.

## Motion

Use `NucleusUIMotion` and profiles instead of creating unrelated Tween policy in
each widget.

The shared `NucleusMotionPolicy` applies reduced-motion preferences consistently
to UI and gameplay presentation.

## Bind data, do not copy it

A HUD should observe ValuePool/attributes/actions through bindings/signals. It
should not become the owner of gameplay state.

## Transient UI

Use modal/toast/tooltip hosts to centralize presentation lifecycle inside the UI
scene.

Do not promote transient UI to a global EventBus workflow unless producer and
consumer genuinely lack a natural reference/signal path.

## Localization

Keep translation keys in source data. Refresh display text through the
localization components when locale changes.
