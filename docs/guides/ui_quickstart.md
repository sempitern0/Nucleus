# UI and Accessibility Quickstart

## Start with native Controls and Theme

Build the UI hierarchy with Godot `Control`/Container nodes first. Use Godot
`Theme` for fonts, icons, colors and StyleBoxes.

Add Nucleus components only for reusable production concerns such as:

```text
settings bindings
focus/navigation
presentation/data bindings
motion and microinteractions
modal/toast/tooltip hosts
safe-area/breakpoint layout
virtualization
screen effects
localization
accessibility behavior
```

## Avoid transform ownership conflicts

When a widget needs both show/hide presentation and local interaction feedback,
use separate transform layers:

```text
LayoutSlot
└── PresentationRoot
    └── FeedbackRoot
        └── Content
```

Recommended ownership:

```text
Container            -> LayoutSlot
NucleusUIPresenter   -> PresentationRoot
interaction/pulses   -> FeedbackRoot
Theme/content        -> Content
```

This prevents independent Tweens from fighting over the same properties.

## Declarative show/hide transitions

Create a reusable transition profile:

```gdscript
var transition := NucleusUITransitionProfile.slide(
    Vector2(0.0, 24.0),
    0.2,
    true,
)

presenter.transition = transition
presenter.show_animated()
```

Built-in builders:

```text
fade_only
pop
slide
```

For complex authored sequences use `AnimationPlayer`; the transition profile is
for repeated panel/widget motion.

## Interaction visual states

For hover/focus/press/selected polish:

```gdscript
var focus := NucleusUIVisualStateProfile.new()
focus.scale_multiplier = Vector2(1.04, 1.04)

var profile := NucleusUIFeedbackProfile.new()
profile.focus_state = focus

feedback.profile = profile
```

Theme still owns the actual button skin. Visual states are additive
transform/opacity feedback only.

Toggle buttons automatically drive `selected`. Other Controls may call:

```gdscript
feedback.set_selected(true)
```

## Progress bars with delayed feedback

Compose two overlapping `Range` controls:

```text
ProgressSlot
├── Trailing
├── Primary
└── ProgressFeedback
```

Then:

```gdscript
progress_feedback.set_value(health)
```

or:

```gdscript
progress_feedback.set_ratio(0.65)
```

The primary value moves first. On decreases the trailing bar can wait briefly
before catching up.

Use the same component for health, shield, stamina, experience or loading
sub-progress; gameplay owns the meaning of the value.

## Reduced motion

All Nucleus UI motion goes through `NucleusUIMotionProfile`.

```text
duration
transition/easing
UI motion-speed setting
shared reduced-motion preference
reduced_motion_scale
```

The default `reduced_motion_scale = 0` preserves instant completion under reduced
motion. Set a small value such as `0.25` if a subtle orientation cue should
remain.

## Focus and navigation

Use the existing focus scopes/navigation helpers for controller/keyboard
workflows. Keep Godot focus neighbors/modes authoritative.

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

## Manual polish lab

Open and run:

```text
examples/ui/ui_polish_lab.tscn
```

Use it to compare panel transitions, interaction states and progress feedback
with mouse, keyboard/controller focus and reduced motion.

Hands-on tutorial:

[`tutorials/ui_polish.md`](tutorials/ui_polish.md)

Technical contract:

[`../components/ui_and_accessibility.md`](../components/ui_and_accessibility.md)
