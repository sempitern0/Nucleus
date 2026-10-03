# Nucleus Localization

Target engine: Godot 4.7.x.

## Ownership

Godot already provides the authoritative localization backend:

```text
TranslationServer
```

Nucleus does not replace it.

Nucleus adds:

```text
Settings persistence
automatic locale resolution
locale presentation metadata
language-selector binding
RTL query helpers
```

The runtime relationship is:

```text
NucleusSettings
      │
      ▼
LocalizationSettingsApplier
      │
      ▼
TranslationServer
```

There is no `LocalizationManager` Autoload.

## Default setting

Nucleus ships:

```text
localization/locale = "automatic"
```

Automatic mode resolves the operating-system locale and compares it against
loaded project translations.

Godot recommends using the user's preferred system language by default while
still allowing the player to choose a language manually.

## Adding a language

The important design property is that adding a translation does not require
adding code.

1. Add the CSV, gettext, or Translation resource through Godot localization.
2. Godot loads the new locale.
3. `NucleusLocaleOptionBinding` discovers it through
   `TranslationServer.get_loaded_locales()`.
4. The language appears in the selector.

The default `NucleusLocaleCatalog` only enriches common locales with stable
native/English names. Unknown loaded locales still work and use
`TranslationServer.get_locale_name()`.

## Curated starter catalog

The default catalog includes common PC/console/indie localization targets such
as English, Spanish, French, German, Italian, Portuguese, Brazilian Portuguese,
Polish, Russian, Ukrainian, Turkish, Arabic, Hebrew, Hindi, Japanese, Korean,
Simplified/Traditional Chinese, Indonesian, Vietnamese, Thai, and several
European languages.

This is presentation metadata, not the source of translation truth.

## Locale selector

Attach `NucleusLocaleOptionBinding` below an `OptionButton`.

```text
OptionButton
└── LocaleOptionBinding
```

By default it shows:

```text
Automatic
+ every loaded translation locale
```

and persists the selected locale through `NucleusSettings`.

## Regional locales

Nucleus uses `TranslationServer.standardize_locale()` and
`TranslationServer.compare_locales()`.

This lets `pt_BR`, `pt_PT`, `zh_CN`, `zh_TW`, and similar regional/script
variants behave correctly instead of reducing everything to a two-letter code.

## RTL

Use:

```gdscript
NucleusLocalization.is_right_to_left()
```

It delegates direction detection to the active Godot TextServer rather than a
hardcoded Arabic/Hebrew language list.

Godot provides bidirectional text shaping and automatic UI mirroring when the
Control layout is configured correctly.

## Pseudolocalization

Nucleus intentionally does not recreate pseudolocalization.

Godot already supports:

```text
accent replacement
string expansion
double vowels
fake bidirectional text
override markers
```

through TranslationServer and ProjectSettings.

This should be part of localization QA from the beginning of a project.
