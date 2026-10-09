import SwiftUI

struct LanguageCommands: Commands {
    var body: some Commands {
        CommandMenu(L10n.text("Language")) {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Toggle(language.title, isOn: Binding(
                    get: { Localization.shared.language == language },
                    set: { selected in if selected { select(language) } }))
            }
        }
    }

    private func select(_ language: AppLanguage) {
        Localization.shared.language = language
        DispatchQueue.main.async { InterfaceMenus.localize() }
    }
}
