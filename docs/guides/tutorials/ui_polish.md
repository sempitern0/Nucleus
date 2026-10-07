# UI Polish Foundation Tutorial

This tutorial builds a small menu/HUD lab using Nucleus' reusable UI polish
primitives while keeping Godot `Control`, `Theme`, layout and focus authoritative.

A ready-made validation scene ships at:

```text
examples/ui/ui_polish_lab.tscn
```

## 1. Build transform layers

Start with:

```text
VBoxContainer
└── PanelSlot : Control
    └── PresentationRoot : PanelContainer
        └── FeedbackRoot : Control
            └── Content
```

Do not animate the position of a direct `Container` child if the Container owns
that layout property.

The outer slot participates in layout. The inner roots are free to animate.

## 2. Add a panel presenter

Attach:

```text
NucleusUIPresenter
```

and assign `PresentationRoot` as `target`.

Create a `NucleusUITransitionProfile` Resource or configure one in code:

```gdscript
var slide := NucleusUITransitionProfile.slide(
    Vector2(0.0, 24.0),
    0.22,
    true,
)

presenter.transition = slide
```

Now:

```gdscript
presenter.show_animated()
presenter.hide_animated()
```

animates the panel without teaching the rest of the menu how Tweens are built.

For art-directed multi-track sequences, keep native `AnimationPlayer`.

## 3. Add button microinteraction

Create visual-state Resources:

```gdscript
var hover := NucleusUIVisualStateProfile.new()
hover.scale_multiplier = Vector2(1.025, 1.025)

var focus := NucleusUIVisualStateProfile.new()
focus.scale_multiplier = Vector2(1.04, 1.04)

var pressed := NucleusUIVisualStateProfile.new()
pressed.scale_multiplier = Vector2(0.97, 0.97)
```

Assign them to:

```gdscript
var feedback_profile := NucleusUIFeedbackProfile.new()
feedback_profile.hover_state = hover
feedback_profile.focus_state = focus
feedback_profile.pressed_state = pressed
```

Then add `NucleusUIInteractionFeedback` next to the Button and assign:

```text
target = Button
profile = feedback_profile
```

Mouse hover, keyboard/controller focus and button-down now use the same reusable
presentation contract.

Godot Theme still owns the button's actual style.

## 4. Add a selected state

For toggle buttons:

```gdscript
var selected := NucleusUIVisualStateProfile.new()
selected.scale_multiplier = Vector2(1.02, 1.02)

feedback_profile.selected_state = selected
```

`BaseButton.toggled` drives the state automatically.

For another type of selectable widget:

```gdscript
feedback.set_selected(is_selected)
```

Use selected state for presentation only. Selection authority remains in the
menu/game model.

## 5. Build a delayed health/progress bar

Create two overlapping ProgressBars:

```text
ProgressSlot : Control
├── Trailing : ProgressBar
├── Primary  : ProgressBar
└── ProgressFeedback : NucleusUIProgressFeedback
```

Assign:

```text
primary_target = Primary
trailing_target = Trailing
decrease_trail_delay = 0.18
```

When gameplay changes health:

```gdscript
progress_feedback.set_value(current_health)
```

The primary display responds first. The trailing display waits and catches up.

For normalized data:

```gdscript
progress_feedback.set_ratio(0.65)
```

The component is not health-specific; it can present shield, stamina, XP, boss
health, a resource meter or loading sub-progress.

## 6. Add optional punch feedback

Create a dedicated `FeedbackRoot` and assign it to:

```text
NucleusUIProgressFeedback.feedback_target
```

For example:

```text
pulse_on_decrease = true
pulse_scale = 1.04
```

Do not assign the same Control that another component is independently scaling.
Use the layer pattern instead.

## 7. Tune reduced motion

`NucleusUIMotionProfile` now exposes:

```text
reduced_motion_scale
```

`0` means the nonessential motion completes immediately when reduced motion is
enabled.

A subtle feedback profile can retain part of its cue:

```gdscript
motion.reduced_motion_scale = 0.25
```

The same factor attenuates Nucleus-owned shake/punch/transition displacement.

Test with both the OS accessibility preference and Nucleus' Reduce Motion
setting.

## 8. Theme the result

Do not put game art into Nucleus profiles.

Use Godot Theme/type variations for:

```text
fonts
font sizes
colors
icons
StyleBoxes
```

Use Nucleus profiles for reusable behavior:

```text
timing
transform motion
opacity feedback
focus/interaction response
```

This lets the same interaction component serve very different visual styles.

## 9. Validate

Run:

```text
examples/ui/ui_polish_lab.tscn
```

Then execute:

```bash
python3 scripts/ci/static_checks.py
python3 scripts/ci/documentation_audit.py
python3 scripts/ci/productization_audit.py

godot --headless --path . --import
godot --headless --path . res://tests/headless/test_runner.tscn
```

Inspect the lab manually with mouse and controller/keyboard focus.

## Common mistakes

Avoid:

- animating a Container-owned position directly;
- assigning presenter and feedback scale animation to the same Control;
- putting Theme colors/fonts/textures inside behavior profiles;
- using UI state as gameplay authority;
- bypassing reduced-motion policy with ad hoc Tweens;
- replacing `AnimationPlayer` with generic code for complex authored sequences.

## Technical contract

[`../../components/ui_and_accessibility.md`](../../components/ui_and_accessibility.md)
