# UI and Accessibility Contract

## Scope

```text
components/ui/accessibility
components/ui/data
components/ui/effects
components/ui/feedback
components/ui/focus
components/ui/gameplay
components/ui/interaction
components/ui/layout
components/ui/localization
components/ui/modal
components/ui/motion
components/ui/navigation
components/ui/presentation
components/ui/toast
components/ui/tooltip
components/ui/virtualization
core/accessibility
```

Nucleus UI is composition around Godot `Control` nodes. It is not a replacement
UI framework.

## Presentation and navigation

Presenters/bindings project runtime state into Controls. Focus scopes and
navigation helpers improve keyboard/gamepad traversal without replacing Godot's
focus system.

Modal, toast, and tooltip hosts own transient presentation inside the scene/UI
layer.

## Layout and virtualization

Safe-area/breakpoint helpers adapt layouts around viewport constraints.
Virtualization is for large/repeated data views and should not be used when a
normal Godot container is sufficient.

## Data and gameplay bindings

UI data components observe stable gameplay/runtime APIs such as ValuePool,
settings, localization, or action state.

UI should not mutate private dictionaries or reach into another subsystem's
implementation details.

## Motion and feedback

`NucleusUIMotion` and motion profiles build on Godot Tweens.

Motion must respect the shared `NucleusMotionPolicy`. The policy combines the
operating-system reduced-animation preference with the Nucleus accessibility
setting.

Gameplay camera feedback uses the same policy so reduced motion is consistent
across UI and world presentation.

## Screen effects

Screen effects are visual presentation. They should not become the authority for
gameplay state such as damage, pause, or status effects.

## Localization

Localized controls observe `TranslationServer`/Nucleus locale changes. Store
translation keys and source data, not permanently translated output.

## Accessibility

Accessibility helpers should improve default usability while preserving native
Godot semantics. A game can layer project-specific accessibility on top without
forking the UI framework.

## Time/process assumptions

UI motion commonly needs to continue while gameplay is paused or time-scaled.
Use the existing profile/policy behavior rather than adding per-widget ad hoc
Tween configuration.

## Extension rule

First ask whether a native Control/container/focus/Tween behavior already solves
the problem. Add a Nucleus component only when it removes repeated production
wiring across projects.
