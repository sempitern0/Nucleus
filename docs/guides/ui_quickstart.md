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
input glyph presentation
shader-parameter effects
text reveal
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

For complex authored sequences use `AnimationPlayer`.

## Interaction visual states

For hover/focus/press/selected polish:

```gdscript
var focus := NucleusUIVisualStateProfile.new()
focus.scale_multiplier = Vector2(1.04, 1.04)

var profile := NucleusUIFeedbackProfile.new()
profile.focus_state = focus

feedback.profile = profile
```

Theme still owns the actual button skin.

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

The same component can present health, shield, stamina, experience, or loading
sub-progress.

## Input glyphs

Create a game-owned `NucleusInputGlyphProfile` and populate it with
`NucleusInputGlyphEntry` Resources.

Each entry stores:

```text
event_key
Texture2D
```

Obtain a key from an actual InputEvent with:

```gdscript
var key := NucleusInputGlyphProfile.event_key(event)
```

Then add `NucleusInputGlyphBinding` to the UI and assign:

```text
action
profile
glyph_target : TextureRect
fallback_label : Label
```

The component follows active keyboard/gamepad/touch source and gamepad family.

No icon pack ships with Nucleus. When a texture mapping is absent, the optional
Label uses Nucleus' normal human-readable binding text.

## Shader effects

Attach `NucleusUIShaderEffect` beside a `CanvasItem` with a game-owned
`ShaderMaterial`.

```gdscript
shader_effect.animate_parameter(
    &"intensity",
    1.0,
)
```

The default mode duplicates the ShaderMaterial so local animation does not
mutate every user of a shared resource. If the shader declares `instance uniform`,
select `INSTANCE_UNIFORM` to preserve shared-material reuse.

Nucleus animates parameters; the game's shader owns the look.

## Typewriter/text reveal

Attach `NucleusUITypewriter` to an existing `RichTextLabel`:

```gdscript
typewriter.restart()
typewriter.skip()
```

The component reveals parsed characters and leaves text, BBCode, localization,
voice, dialogue state and choices to the consuming game.

Cadence can be tuned without changing text ownership:

```gdscript
typewriter.characters_per_second = 42.0
typewriter.minor_punctuation_delay = 0.08
typewriter.major_punctuation_delay = 0.2
```

`minor_punctuation_characters` and `major_punctuation_characters` are
project-configurable strings, so localization can use different punctuation
conventions. Line breaks use the major delay by default.

Reduced-motion users see the complete text immediately by default.

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

If text changes while a typewriter is active, restart the reveal explicitly.
Review the typewriter punctuation sets when the selected locale uses different
clause or sentence marks.

## Manual polish lab

Open and run:

```text
examples/ui/ui_polish_lab.tscn
```

Use it to compare transitions, interaction states, progress feedback, glyph
fallback, shader animation and punctuation-aware text reveal with mouse,
keyboard/controller focus, hot swap and reduced motion.

Hands-on tutorial:

[`tutorials/ui_polish.md`](tutorials/ui_polish.md)

Technical contract:

[`../components/ui_and_accessibility.md`](../components/ui_and_accessibility.md)
