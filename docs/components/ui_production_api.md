# UI Production Tooling — Technical Reference

Target engine: Godot 4.7.x.

This document explains ownership, contracts, and runtime behavior. For editor
setup recipes, start with `docs/guides/ui_production_quickstart.md`.

## Design constraints

Production UI tooling follows the same Nucleus rules:

- no UI Autoload by default;
- composition over custom control inheritance;
- Godot Controls, Containers, Themes, TranslationServer, and ScrollContainer
  remain the underlying implementation;
- motion obeys both Nucleus and operating-system reduced-motion policy;
- keyboard/controller focus is not secondary to mouse input;
- reusable behavior must not impose game art direction.

## Modal stack

### Components

```text
NucleusUIModalHost
NucleusUIModal
NucleusUIDialog
```

The host owns:

```text
stack order
backdrop
ui_cancel policy
backdrop-click policy
focus restoration
```

A modal owns:

```text
target Control
NucleusUIPresenter
NucleusUIFocusScope
dismiss policy
```

A dialog only adapts:

```text
title/message Labels
confirm/cancel BaseButtons
translation keys
```

The stack stores the focus owner before the first modal and restores it after
the final modal closes.

Multiple modals are supported. The top modal receives cancel/backdrop policy.

## Toast queue

`NucleusUIToastHost` bounds visible notifications and queues the rest.

Queue ordering is:

```text
higher priority first
then FIFO registration order
```

A non-empty `dedupe_key` prevents the same logical notification from appearing
twice in pending or visible state.

Toasts are generated from Godot Controls and use Theme type variations:

```text
NucleusToast
NucleusToastTitle
NucleusToastMessage
```

This means a project can restyle the default implementation in its Theme
without subclassing the queue.

Toast timers ignore `Engine.time_scale`.

## Native tooltip adapter

`NucleusUITooltipBinding` intentionally does not implement a tooltip popup.

Godot already provides:

```text
Control.tooltip_text
gui/timers/tooltip_delay_sec
TooltipPanel Theme type
TooltipLabel Theme type
Button shortcut_in_tooltip
```

Nucleus adds translation-key synchronization and optional mirroring to
`accessibility_description`.

## Hold-to-confirm

`NucleusUIHoldToConfirm` listens to `BaseButton.button_down` and `button_up`.

Progress uses `Time.get_ticks_usec()`, so confirmation duration is real time and
is not stretched by gameplay slow motion or paused by `Engine.time_scale`.

The component emits:

```text
hold_started
progress_changed
confirmed
canceled
```

The destructive action must connect to `confirmed`, not `BaseButton.pressed`.

## Page controller

`NucleusUIPageController` owns one mutually exclusive array of page Controls.

It supports:

```text
show_page(index)
show_page_by_name(node_name)
next_page()
previous_page()
optional tab-button wiring
crossfade
focus restoration through NucleusUIFocusScope
```

A request during an active page transition returns `ERR_BUSY` instead of
silently producing competing tweens.

## Animated values

`NucleusUIAnimatedValue` uses `Tween.tween_method()` to interpolate a numeric
value.

It can drive:

```text
ProgressBar / Slider / other Range
Label
both at once
```

This covers score counters, XP bars, health interpolation, download/loading
progress, and settings previews without reimplementing Tween plumbing.

## Safe area

`NucleusUISafeArea` maps physical display safe-area margins into logical
viewport coordinates.

Godot's safe-area rectangle is reported in physical screen coordinates, while
game Controls live in viewport coordinates. Nucleus converts each inset by the
ratio between physical screen size and the current logical viewport.

In Godot 4.7, native safe-area reporting is provided on Android/iOS. Other
platforms fall back to the main display usable rectangle. Nucleus applies that
desktop fallback only in fullscreen modes and keeps explicit fallback insets
for Web/custom host shells.

## Responsive breakpoints

`NucleusUIBreakpoints` works in logical viewport pixels, not physical display
pixels.

Default categories are:

```text
COMPACT  <= 720
REGULAR   721..1279
WIDE     >= 1280
```

Projects can change both thresholds in the Inspector.

`NucleusUIResponsiveVisibility` declaratively toggles a Control by size class
and portrait/landscape orientation.

Breakpoints complement Containers and anchors; they do not replace them.

## Virtualized list

`NucleusUIVirtualList` is for large fixed-height datasets.

Instead of:

```text
10,000 data rows
→ 10,000 Controls
```

it creates approximately:

```text
visible rows + overscan
```

and recycles those Controls while scrolling.

The consumer receives:

```gdscript
bind_item(item, index, data)
unbind_item(item, previous_index)
```

No custom item superclass is required.

This first implementation deliberately supports fixed-height rows only. Variable
row heights require a cumulative-height index and a different invalidation
strategy and should not be hidden behind an inaccurate abstraction.

It virtualizes rendering/data binding, not controller focus. For very large
interactive selectable datasets, prefer Godot controls such as `ItemList`/`Tree`
or add an indexed focus/navigation layer explicitly.


## CanvasLayer and multiple Viewports

`UIModalHost` and `UIToastHost` are CanvasLayer-based. A CanvasLayer belongs to
one Viewport. Split-screen projects should instance the appropriate host per
Viewport (or assign `custom_viewport`) rather than expecting one CanvasLayer to
render independently into every local player's view.


## Operating-system accessibility preferences

`NucleusUIMotionPolicy` also checks:

```gdscript
DisplayServer.accessibility_should_reduce_animation()
```

When the operating system asks applications to reduce animation, Nucleus treats
motion as reduced even if the in-game preference has not been changed yet.

The same OS preference suppresses full-screen flash intensity because Godot
defines the signal as covering flashing, blinking, and moving content.

The in-game setting remains useful on platforms where Godot reports an unknown
OS accessibility state and for players who prefer stricter behavior than their
system-wide configuration.
