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

Godot remains authoritative for:

```text
Control / Container layout
Theme inheritance and type variations
StyleBox / fonts / icons
focus neighbors and native focus behavior
Tween / AnimationPlayer
RichTextLabel
accessibility tree integration
```

Nucleus adds small reusable policies around those primitives.

## Presentation and navigation

Presenters/bindings project runtime state into Controls. Focus scopes and
navigation helpers improve keyboard/gamepad traversal without replacing Godot's
focus system.

Modal, toast, and tooltip hosts own transient presentation inside the scene/UI
layer.

## UI polish ownership

Reusable polish is split into three layers:

```text
authored/native visual state
    Theme + layout + base Control transform

presentation transition
    NucleusUIPresenter + NucleusUITransitionProfile

local interaction/feedback
    NucleusUIInteractionFeedback + NucleusUIVisualStateProfile
```

When both presentation and feedback need to animate transforms, prefer separate
Controls:

```text
LayoutSlot
└── PresentationRoot
    └── FeedbackRoot
        └── Content
```

The Container owns `LayoutSlot`. `NucleusUIPresenter` owns transforms on
`PresentationRoot`. Interaction/progress pulses own `FeedbackRoot`.

This avoids two independent Tweens writing the same `scale`, `position`,
`rotation`, or `modulate` property.

Do not add a global UI transform mixer merely to avoid this composition.

## Motion

`NucleusUIMotionProfile` owns timing:

```text
duration
transition
easing
ignore_time_scale
respect_reduced_motion
reduced_motion_scale
```

`reduced_motion_scale` is the retained fraction of nonessential motion when the
shared `NucleusMotionPolicy` reports reduced motion.

The default remains `0`, preserving the historical UI behavior of completing
nonessential transitions immediately. Projects may use a small value such as
`0.25` when they want orientation/selection cues to remain visible.

`NucleusUIMotion.get_effect_amplitude_scale()` exposes the same policy for
effects whose displacement should be attenuated as well as shortened.

The normal user setting `accessibility/ui_motion_scale` remains a duration
multiplier independent of the reduced-motion decision.

## Declarative transitions

`NucleusUITransitionProfile` describes the hidden state relative to the
Control's authored base state:

```text
hidden alpha
scale multiplier
position offset
rotation offset
pivot
motion profile
```

Convenience builders:

```gdscript
NucleusUITransitionProfile.fade_only()
NucleusUITransitionProfile.pop()
NucleusUITransitionProfile.slide(Vector2(0.0, 24.0))
```

Assign a profile to:

```text
NucleusUIPresenter.transition
```

Existing `fade`, `scale`, `hidden_scale`, and `motion` exports remain as the
legacy fallback when no transition profile is assigned.

For authored timeline animation, cinematic menus, or elaborate art-direction
sequences, keep using native `AnimationPlayer`. Transition profiles are for
repeated microinteraction/panel behavior, not a replacement animation system.

## Interaction visual states

`NucleusUIVisualStateProfile` is additive transform/opacity feedback:

```text
scale multiplier
position offset
rotation offset
alpha multiplier
optional motion override
```

It intentionally does not contain:

```text
fonts
icons
StyleBoxes
Theme colors
textures
```

Those remain in Godot `Theme`.

`NucleusUIFeedbackProfile` may assign visual states for:

```text
idle
hover
focus
pressed
selected
```

`NucleusUIInteractionFeedback` resolves those states from native Control events.
Toggle buttons automatically drive `selected`; other widgets may call
`set_selected()` explicitly.

The old scale/opacity fields remain as a compact fallback when visual-state
Resources are not assigned.

## Progress feedback

`NucleusUIProgressFeedback` presents one gameplay/runtime number through:

```text
primary Range
optional delayed trailing Range
optional punch target
```

It is suitable for:

```text
health
shield
stamina
boss health
experience
resource meters
loading sub-progress
```

The component does not know what the number means.

Typical damage-bar composition:

```text
ProgressSlot
├── Trailing : ProgressBar
├── Primary  : ProgressBar
└── ProgressFeedback
```

For a decrease, `Primary` can move immediately while `Trailing` waits for
`decrease_trail_delay` before catching up.

When the two `Range` nodes use different numeric bounds, the trailing value is
mapped through normalized progress. `sync_trailing_bounds` can instead keep both
ranges identical.

## Theme boundary

Nucleus does not implement a parallel design-token or skinning framework.

Use Godot Theme/type variations for visual identity. Dynamically generated
Nucleus controls should expose stable type variations where practical, as
`NucleusUIToastHost` already does.

A consuming game should be able to replace its Theme, fonts, icons and StyleBox
assets without changing UI behavior code.

## Layout and virtualization

Safe-area/breakpoint helpers adapt layouts around viewport constraints.
Virtualization is for large/repeated data views and should not be used when a
normal Godot container is sufficient.

Do not animate layout-owned position on a Control that a Container rewrites every
frame. Insert a presentation/feedback child Control and animate that layer.

## Data and gameplay bindings

UI data components observe stable gameplay/runtime APIs such as ValuePool,
settings, localization, or action state.

UI should not mutate private dictionaries or reach into another subsystem's
implementation details.

## Screen effects

Screen effects are visual presentation. They should not become the authority for
gameplay state such as damage, pause, or status effects.

`NucleusUIScreenEffects` currently owns common fade/flash presentation. More
specialized material effects should remain game-owned until repeated production
usage proves a generic adapter.

## Localization

Localized controls observe `TranslationServer`/Nucleus locale changes. Store
translation keys and source data, not permanently translated output.

## Accessibility

Accessibility helpers improve default usability while preserving native Godot
semantics.

Reduced motion is shared through `NucleusMotionPolicy`; UI-specific duration and
flash preferences remain in `NucleusUIMotionPolicy`.

## Validation lab

Run:

```text
examples/ui/ui_polish_lab.tscn
```

to inspect:

```text
panel transitions
hover/focus/press/selected states
delayed progress feedback
reduced-motion response
```

Use mouse, keyboard and controller while validating focus and motion.

## Extension rule

First ask whether a native Control, Theme, Container, focus, Tween or
AnimationPlayer behavior already solves the problem.

Add a Nucleus component only when it removes repeated production wiring across
projects without taking ownership away from the engine or the game's art
direction.
