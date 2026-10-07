import SwiftUI
import AppKit

/// Use the same preference as macOS's per-app language setting. Bundle and AppKit cache their
/// language at launch, so the new preference takes effect together when the app is reopened.
nonisolated struct LanguageSettings {
    private(set) var selection: String
    private let defaults: UserDefaults

    static let languages: [(id: String, name: String)] = [
        ("en", "English"), ("zh-Hans", "简体中文"), ("zh-Hant", "繁體中文"),
        ("ja", "日本語"), ("ko", "한국어"), ("de", "Deutsch"),
        ("fr", "Français"), ("es", "Español"), ("pt-BR", "Português (Brasil)")
    ]

    init(defaults: UserDefaults = .standard, domain: String = Bundle.main.bundleIdentifier ?? "com.wonderassembly.compositor") {
        self.defaults = defaults
        selection = Self.savedSelection(defaults: defaults, domain: domain)
    }

    private static func savedSelection(defaults: UserDefaults, domain: String) -> String {
        guard let saved = defaults.persistentDomain(forName: domain)?["AppleLanguages"] as? [String],
              !saved.isEmpty else { return "" }
        return Bundle.preferredLocalizations(from: languages.map(\.id), forPreferences: saved).first ?? ""
    }

    mutating func select(_ language: String) {
        guard language != selection,
              language.isEmpty || Self.languages.contains(where: { $0.id == language }) else { return }
        if language.isEmpty { defaults.removeObject(forKey: "AppleLanguages") }
        else { defaults.set([language], forKey: "AppleLanguages") }
        selection = language
    }
}

struct LanguageMenu: View {
    @State private var settings = LanguageSettings()

    var body: some View {
        Menu(L10n.tr("Language")) {
            Picker(L10n.tr("Language"), selection: Binding(get: { settings.selection }, set: choose)) {
                Text(L10n.tr("Follow System")).tag("")
                Divider()
                ForEach(LanguageSettings.languages, id: \.id) { language in
                    Text(verbatim: language.name).tag(language.id)
                }
            }
            .pickerStyle(.inline)
        }
    }

    private func choose(_ language: String) {
        guard language != settings.selection else { return }
        settings.select(language)
        let alert = NSAlert()
        alert.messageText = L10n.tr("Language Changed")
        alert.informativeText = L10n.tr("The new language will take effect the next time you open Compositor. You can keep working and save your documents before closing the app.")
        alert.addButton(withTitle: L10n.tr("OK"))
        alert.runModal()
    }
}
