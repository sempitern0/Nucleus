# Nucleus UI Components

Target engine: Godot 4.7.x.

## Philosophy

The UI layer should remove repetitive engineering without removing art
direction.

Nucleus therefore provides:

```text
behavior
timing policy
accessibility hooks
focus ownership
interaction feedback
common effects
```

but does not impose a theme, font, color palette, button skin, or menu layout.

## Structure

```text
components/ui/
├── accessibility/
│   └── ui_accessibility_metadata.gd
├── effects/
│   ├── ui_screen_effects.gd
│   └── ui_screen_effects.tscn
├── feedback/
│   ├── ui_feedback_profile.gd
│   └── ui_interaction_feedback.gd
├── focus/
│   └── ui_focus_scope.gd
├── localization/
│   └── locale_option_binding.gd
├── motion/
│   ├── ui_motion.gd
│   ├── ui_motion_policy.gd
│   └── ui_motion_profile.gd
└── presentation/
    └── ui_presenter.gd
```

No UI component is an Autoload.

## Motion API

Common one-off effects do not require a custom AnimationPlayer:

```gdscript
NucleusUIMotion.fade_to(panel, 1.0)
NucleusUIMotion.scale_to(button, Vector2.ONE)
NucleusUIMotion.pop(dialog)
NucleusUIMotion.punch_scale(icon)
NucleusUIMotion.shake(error_panel)
```

For Controls managed by a Container, prefer scale/opacity effects. If position
must be animated, place the visual Control inside a wrapper so the Container
owns the wrapper layout and the child can move freely.

Tweens ignore `Engine.time_scale` by default, which keeps pause-menu UI
responsive while gameplay is paused.

## Accessibility policy

The base Settings catalog now includes:

```text
accessibility/reduced_motion
accessibility/ui_motion_scale
accessibility/screen_flash_intensity
```

Every Nucleus motion profile can honor reduced-motion preferences.

Full-screen flashes multiply their requested intensity by the global
`screen_flash_intensity` preference, so a settings panel can expose a direct
photosensitivity control without editing individual effects.

## Interaction feedback

Attach `NucleusUIInteractionFeedback` below any Control:

```text
Button
└── UIInteractionFeedback
```

It supports:

```text
hover scale
keyboard/controller focus scale
pressed scale
optional opacity response
optional hover/focus/press NucleusAudioCue
```

The component does not execute the button action.

When reduced motion is enabled, transform feedback can be suppressed while
focus styling and native accessibility remain intact.

## Focus scope

`NucleusUIFocusScope` solves recurring menu focus ownership:

```text
MenuPanel
├── UIFocusScope
├── ContinueButton
├── SettingsButton
└── QuitButton
```

It can:

```text
focus the first usable control
prefer an explicit initial focus
remember the last focused child
restore focus when a panel reopens
release hidden-panel focus
```

It uses `Viewport.gui_focus_changed` and native Control focus modes.

Visible focus styling must still be present in the Theme. Removing focus
outlines harms keyboard/controller accessibility.

## Accessibility metadata

Godot 4.7 exposes accessibility metadata directly on `Control`.

`NucleusUIAccessibilityMetadata` binds translation keys to:

```text
accessibility_name
accessibility_description
accessibility_live
```

This means the same component updates its screen-reader metadata automatically
when the locale changes.

Godot owns the accessibility tree and screen-reader bridge.

## Presenter

`NucleusUIPresenter` provides a reusable panel/dialog show-hide workflow:

```gdscript
await presenter.show_animated().finished
await presenter.hide_animated().finished
```

It handles:

```text
fade
subtle scale
mouse blocking while hiding
time-scale-independent motion
reduced-motion preference
```

The component is useful for modal dialogs, pause panels, settings pages, HUD
cards, and lightweight popovers.

## Screen effects

`NucleusUIScreenEffects` is scene-owned:

```text
PersistentUI
└── UIScreenEffects
```

It provides:

```gdscript
effects.fade_to(Color.BLACK)
effects.fade_from()
effects.flash(Color.WHITE, 0.5)
await effects.cover_and_reveal()
```

If an effect must survive `SceneTree` replacement, place the component in the
project's persistent UI shell. Nucleus does not turn presentation into a global
Core service.

## Relation to Barebone

Useful ideas retained:

```text
UIAnimationOptions Resource
pop/shrink/fade patterns
GlobalEffects fade/flash idea
LanguageSelector convenience
Label/accessibility intent
```

Changes:

```text
no UiAnimations Autoload
no GlobalEffects Autoload
no metadata-driven fade chaining
no UI animation dependency on viewport globals
motion obeys accessibility settings
screen flashes have a user intensity policy
focus/controller navigation is first-class
screen-reader metadata uses Godot 4.7 APIs
localization uses TranslationServer as source of truth
```
