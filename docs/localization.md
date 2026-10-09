# Interface languages

The Language menu changes the interface immediately, without rebuilding the workspace or resetting view state.
`Localization.shared.language` is observable and stored under `interface.language` in user defaults. The initial
language is English. AppKit and SwiftUI share `L10n.text` and `L10n.format` and the resources in
`Compositor/Localization/{language}.lproj/Localizable.strings`.

Use `L10n.text("Stable English key")` at the presentation boundary. For dynamic enum options, translate the raw
value only for display; keep tags, represented objects, shortcut IDs, and saved values in their original form.
Keep user filenames, layer names, font names, and editable text out of translation lookups. For messages containing
user content, use a stable template, for example `L10n.format("Save changes to %@?", filename)`.

To add a language, add an `AppLanguage` case and its native title, add an `.lproj` resource directory with the same
keys, and register the localization in the Xcode project's `knownRegions`. Keep the `%@` placeholders aligned
between translations. `LocalizationTests` checks resource parity and formatting. Missing strings fall back to their
English keys. Standard menu titles owned by AppKit are handled by `InterfaceMenus`; floating panels and hosted
views use `localizedInterface()` to pass the selected locale to SwiftUI. System-owned open/save panel controls and
third-party updater UI continue to use the macOS language where no per-panel language API is available.

New save destinations use `SaveFilename`: an opened project's URL takes precedence over the image that originally
created the canvas. The default is `stem_yyyyMMdd_HHmmss.extension` in the current time zone. A newly created canvas
uses its localized untitled name. Ordinary Save on an existing `.comp` package keeps its destination. Source image
URLs are session metadata and are never persisted in the project format.
