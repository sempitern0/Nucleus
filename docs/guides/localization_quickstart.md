# Localization — Godot Editor Quickstart

Nucleus deliberately uses Godot's localization pipeline instead of inventing a
parallel translation database.

## Add the first translation

1. Open `Project > Project Settings`.
2. Open the `Localization` tab.
3. Add your Translation resource, CSV, or gettext-based localization file.
4. Make sure the resource locale is correct.
5. Run the project.

`NucleusLocalization` discovers loaded locales through `TranslationServer`, so
adding another translation later does not require editing a language array in
code.

## Add a language selector

1. Add an `OptionButton` to the settings UI.
2. Add a child Node.
3. Attach:

```text
components/ui/localization/locale_option_binding.gd
```

4. Keep the default String setting unless the project intentionally uses a
   different preference.
5. Choose whether to show native names and locale codes.

The selector displays:

```text
Automatic
+ loaded project locales
```

and persists the choice through `NucleusSettings`.

## Recommended first-day localization workflow

Even before hiring translators:

1. Use translation keys instead of shipping gameplay strings scattered through
   scripts.
2. Build menus with Containers rather than pixel-perfect manual positions.
3. Enable text wrapping where labels can grow.
4. Test long strings.
5. Test controller focus after text expansion.
6. Test an RTL locale before UI architecture is locked.
7. Use Godot pseudolocalization during development.

This finds localization layout bugs while changing them is still cheap.

## Accessibility strings

Visible text and screen-reader descriptions are separate concerns.

Use `NucleusUIAccessibilityMetadata` when a visual label does not fully describe
a Control's function.

Use `NucleusUITooltipBinding` for translated help text. It can also mirror that
tooltip into the native accessibility description when appropriate.
