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

Attach `NucleusUIPresenter` and assign `PresentationRoot` as `target`.

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

Then add `NucleusUIInteractionFeedback` next to the Button.

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

Selection authority remains in the menu/game model.

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

For normalized data:

```gdscript
progress_feedback.set_ratio(0.65)
```

The component can also present shield, stamina, XP, boss health or loading
sub-progress.

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

## 7. Tune reduced motion

`NucleusUIMotionProfile` exposes:

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

## 8. Theme the result

Do not put game art into Nucleus behavior profiles.

Use Godot Theme/type variations for:

```text
fonts
font sizes
colors
icons
StyleBoxes
```

Use Nucleus profiles for timing, transform motion, opacity and interaction
response.

## 9. Add input glyphs

Create one `NucleusInputGlyphProfile` owned by the game.

For every supported binding glyph create a `NucleusInputGlyphEntry`:

```text
event_key
texture
```

When authoring tools or setup code have the relevant InputEvent:

```gdscript
entry.event_key = NucleusInputGlyphProfile.event_key(event)
```

Keep separate arrays for:

```text
keyboard/mouse
generic gamepad
Xbox
PlayStation
Nintendo
Steam
touch
```

Add a `TextureRect`, optional fallback `Label`, then:

```gdscript
var binding := NucleusInputGlyphBinding.new()
binding.action = &"interact"
binding.profile = glyph_profile
binding.glyph_target = glyph
binding.fallback_label = fallback
```

The binding refreshes after rebinds and input-source/gamepad-family changes.

If no matching texture exists, the text label can remain usable. Nucleus does not
ship copyrighted or style-specific controller artwork.

## 10. Animate a game-owned shader parameter

Create the shader and ShaderMaterial normally in Godot.

Attach `NucleusUIShaderEffect` to that Control:

```gdscript
shader_effect.animate_parameter(
    &"intensity",
    1.0,
)
```

The default mode duplicates the material at runtime so the effect is local.

When the shader uses `instance uniform`, switch the component to
`INSTANCE_UNIFORM` to keep one shared material across many controls.

Use this for reusable glue around effects such as highlight, dissolve, glow or
selection, while keeping the actual shader completely game-owned.

For authored multi-parameter timelines, use `AnimationPlayer`.

## 11. Add RichTextLabel reveal

Build dialogue/help/tutorial text with native `RichTextLabel`.

Attach:

```text
NucleusUITypewriter
```

Then:

```gdscript
typewriter.restart()
```

A skip action can call:

```gdscript
typewriter.skip()
```

Tune cadence independently from authored text:

```gdscript
typewriter.characters_per_second = 42.0
typewriter.minor_punctuation_delay = 0.08
typewriter.major_punctuation_delay = 0.2
```

Minor and major punctuation are configurable character sets. The defaults cover
common Latin, Arabic, CJK and Japanese punctuation; line breaks use the major
delay. This keeps localization flexible without adding dialogue semantics.

The component reads parsed RichTextLabel content for cadence, so BBCode tags do
not consume reveal time or need to be interpreted by Nucleus.

The component controls only character visibility. Dialogue graphs, speaker
portraits, localization, audio and choices remain outside it.

Under reduced motion the complete text is revealed immediately by default.

## 12. Validate

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

Inspect the lab manually with mouse, keyboard and controller. Pay attention to
punctuation timing at normal frame rate and after deliberate frame stalls.

## Common mistakes

Avoid:

- animating a Container-owned position directly;
- assigning presenter and feedback scale animation to the same Control;
- putting Theme colors/fonts/textures inside behavior profiles;
- storing copyrighted/vendor glyph artwork inside Nucleus;
- mutating shared ShaderMaterial Resources unintentionally;
- turning typewriter presentation into dialogue authority;
- hard-coding one locale's punctuation rules outside the typewriter exports;
- using UI state as gameplay authority;
- bypassing reduced-motion policy with ad hoc Tweens;
- replacing `AnimationPlayer` with generic code for complex authored sequences.

## Technical contract

[`../../components/ui_and_accessibility.md`](../../components/ui_and_accessibility.md)
