# UI Accessibility and Production QA Checklist

Use this checklist before considering a menu or HUD production-ready.

## Input and focus

- Every interactive action can be reached without a mouse.
- Opening a screen establishes a sensible initial focus.
- Closing a modal restores focus to the invoking control.
- Hidden panels do not retain focus.
- Focus has a visible Theme state.
- Controller navigation works after localization changes label sizes.

## Motion and photosensitivity

- Nonessential UI movement obeys OS and in-game reduced-motion preferences.
- UI timing obeys `accessibility/ui_motion_scale`.
- Full-screen flashes obey `accessibility/screen_flash_intensity`.
- Critical information is never communicated by animation alone.
- Important state changes remain understandable with motion disabled.

## Screen readers

- Icon-only controls have an accessibility name.
- Ambiguous controls have an accessibility description.
- Tooltips that carry meaningful help are mirrored to accessibility metadata.
- Dynamic critical status text uses an appropriate native live-region policy.

## Localization

- No player-facing strings are assembled from untranslated fragments.
- Long translated text wraps or expands safely.
- UI survives 30–50% text expansion.
- Regional locales are not reduced blindly to two-letter language codes.
- RTL layouts have been tested.
- Pseudolocalization is part of regular UI QA.

## Responsive layout

- The UI is usable at minimum supported window size.
- Window resizing does not overlap interactive elements.
- Important content respects device safe areas.
- Decorative backgrounds are not unnecessarily constrained to safe areas.
- Breakpoint-specific layouts preserve the same functionality.

## Performance

- Small lists use ordinary Containers.
- Large fixed-row datasets use virtualization only when profiling justifies it.
- Opening/closing menus does not continually instantiate expensive assets.
- Toast queues have a bounded number of simultaneous visible notifications.

## Destructive actions

- High-impact actions use confirmation or hold-to-confirm where appropriate.
- Hold-to-confirm communicates progress visually.
- The destructive action is connected to `confirmed`, not the underlying
  Button's normal `pressed` signal.
