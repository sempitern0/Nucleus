# UI and Accessibility Quickstart

Build the interface with native `Control`, `Container`, `Theme`, focus and
`AnimationPlayer` first. Add Nucleus components for reusable behavior, not for
visual ownership.

## Ownership layers

When layout, presentation and interaction all affect transforms, separate them:

```text
LayoutSlot          ← Container owns layout
└── PresentationRoot ← show/hide transition
    └── FeedbackRoot ← hover/focus/press/pulse
        └── Content  ← Theme/content
```

This avoids two independent systems writing the same transform.

## Presentation and feedback

Use:

```text
NucleusUIPresenter + NucleusUITransitionProfile
NucleusUIInteractionFeedback + NucleusUIFeedbackProfile
NucleusUIProgressFeedback
NucleusUIShaderEffect
NucleusUITypewriter
```

For authored multi-track sequences, keep using `AnimationPlayer`.

## Input prompts and glyphs

`NucleusInputGlyphBinding` follows the active keyboard/gamepad/touch source and
gamepad family. Glyph artwork is game-owned. Keep the optional human-readable
text fallback so an icon pack is never the only way to understand an action.

## Accessibility preferences

Built-in preferences include:

```text
accessibility/reduced_motion
accessibility/ui_motion_scale
accessibility/screen_flash_intensity
accessibility/ui_scale
accessibility/high_contrast
```

`ui_scale` and `high_contrast` express user intent. Nucleus deliberately does not
scale an entire `Control` root or impose a universal contrast palette. Compose
`NucleusUIAccessibilityBinding` and map those values into the game's Theme and
responsive layout strategy.

Essential state should not depend on color alone; combine color with text, icon,
shape, pattern or another redundant cue.

## Reduced motion

Nucleus UI motion uses the shared reduced-motion policy. Each motion profile can
choose how much nonessential movement remains through `reduced_motion_scale`.
Camera feedback has the same policy boundary.

## Signal-driven UI and coalescing

Prefer:

```text
runtime state changes
→ signal
→ binding / local refresh
```

over per-frame HUD polling.

When several signals update the same expensive presentation in one frame,
`NucleusUIRefreshCoalescer` can collapse them into one deferred refresh. Do not
coalesce focus, confirmation or modal ownership when a one-frame delay changes
interaction correctness.

`NucleusUIResourceLoadBinding` can optionally coalesce high-frequency progress
updates through `coalesce_progress_updates`.

## Focus and navigation

Keep native Godot focus authoritative. Use Nucleus focus helpers to reduce
repeated setup, not to build another navigation engine.

## Validate manually

Run:

```text
examples/ui/ui_polish_lab.tscn
```

Test mouse, keyboard and controller hot-swap, focus traversal, missing-glyph text
fallback, reduced motion, UI scaling and the game's high-contrast presentation.

Hands-on: [`tutorials/ui_polish.md`](tutorials/ui_polish.md).
