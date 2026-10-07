# Localization

Compositor has bundled resources for English, Simplified Chinese, Traditional Chinese,
Japanese, Korean, German, French, Spanish, and Brazilian Portuguese. No network access
or translation model is needed at runtime.

Choose **Compositor > Language** in the menu bar. The menu lists languages by their
native names and includes **Follow System**. Changes take effect after closing and
reopening Compositor, keeping AppKit menus, system dialogs, and SwiftUI views in the
same language. The app does not quit automatically or discard open documents.
The preference uses macOS's standard per-app `AppleLanguages` setting; choosing Follow
System removes the app override without changing the system language.

## Translation status

Simplified Chinese covers the complete extracted UI inventory, including errors,
PSD conversion warnings, tool instructions, accessibility labels, and history actions.
Traditional Chinese uses region-specific Photoshop terminology rather than only
character substitution. `glossary.tsv` contains the reviewed terminology and common
commands in all eight translated languages. Custom numeric text fields accept both
decimal commas and decimal points, and display the system region’s decimal separator.

Japanese, Korean, German, French, Spanish, and Brazilian Portuguese have been reviewed
against the full extracted inventory, with source-context corrections to tool names,
keyboard hints, error messages, and Photoshop terms. The catalog's review states record
that pass. The checker rejects any new entries left in `needs_review` when run with
`--require-reviewed`.

Terminology references:

- [Adobe: Simplified Chinese blending modes](https://helpx.adobe.com/cn/photoshop/desktop/repair-retouch/adjust-light-tone/blending-mode-descriptions.html)
- [Adobe: Traditional Chinese blending modes](https://helpx.adobe.com/tw/photoshop/desktop/repair-retouch/adjust-light-tone/blending-mode-descriptions.html)
- [Adobe: Clone Stamp](https://helpx.adobe.com/cn/photoshop/desktop/repair-retouch/heal-clone/retouch-images-with-the-clone-stamp-tool.html)
- [Adobe: Spot Healing Brush](https://helpx.adobe.com/cn/photoshop/desktop/repair-retouch/clean-restore-images/spot-healing-brush-tool.html)

## Adding or editing text

- Put display text in `Compositor/Localizable.xcstrings` and use `L10n.tr("…")` for
  literals, including interpolation. Supply every language and keep review status
  accurate. `InfoPlist.xcstrings` localizes Finder's document type descriptions.
- Interpolation produces numbered tokens such as `%1$@`. Translators may reorder
  them. `L10n` substitutes them in one pass, so a user's filename containing `%`,
  quotes, or placeholder-like text is never interpreted as a format string.
- Use `L10n.text(value)` only for known display keys, such as an enum's English raw
  value. Do not translate filenames, user-entered layer names, font names, SF Symbols,
  accessibility identifiers, preference keys, keyboard shortcut IDs, or serialized
  enum values. Do not infer an action from its translated title.
- Keep picker tags and menu `representedObject` values stable. In particular, crop
  ratios, canvas fill colors, measurement units, blend modes, and shortcut definitions
  keep their existing identities. The project file format is unchanged.
- Use plural variations for quantities rather than concatenating fragments. Project
  tab overflow uses the catalog's plural forms. Give labels enough room for longer text.

## Verification

```sh
python3 scripts/check-localizations.py
# Release readiness: also fail on outstanding linguistic review.
python3 scripts/check-localizations.py --require-reviewed

xcodebuild -project Compositor.xcodeproj -scheme Compositor \
  -destination 'platform=macOS' -testLanguage en -testRegion US \
  test -only-testing:CompositorTests/LocalizationTests

# Includes Simplified and Traditional Chinese UI launch/menu screenshots.
xcodebuild -project Compositor.xcodeproj -scheme 'Compositor Localization' \
  -destination 'platform=macOS' test
```

The UI tests require macOS UI automation to be available. Unit tests explicitly load
all nine localization bundles, check interpolation and plurals, verify Chinese
Photoshop terms, and protect serialized blend modes and shortcut IDs. Language
preference tests use an isolated defaults domain rather than the user's settings.
