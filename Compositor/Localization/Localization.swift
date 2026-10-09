import Foundation
import Observation
import SwiftUI

nonisolated enum AppLanguage: String, CaseIterable, Sendable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var title: String {
        switch self {
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        }
    }
    static let storageKey = "interface.language"
}

/// Shared by SwiftUI and AppKit. Reading the language participates in SwiftUI observation; a switch keeps
/// the document and each view's editing state intact. The lock also allows errors to be translated off-main.
@Observable
nonisolated final class Localization: @unchecked Sendable {
    static let shared = Localization()
    @ObservationIgnored private let lock = NSLock()
    @ObservationIgnored private var selected: AppLanguage
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selected = AppLanguage(rawValue: defaults.string(forKey: AppLanguage.storageKey) ?? "") ?? .english
    }

    var language: AppLanguage {
        get {
            access(keyPath: \.language)
            return lock.withLock { selected }
        }
        set {
            guard language != newValue else { return }
            withMutation(keyPath: \.language) {
                lock.withLock {
                    selected = newValue
                    defaults.set(newValue.rawValue, forKey: AppLanguage.storageKey)
                }
            }
        }
    }
}

nonisolated enum L10n {
    private static let bundles: [AppLanguage: Bundle] = Dictionary(uniqueKeysWithValues: AppLanguage.allCases.compactMap { language in
        Bundle.main.path(forResource: language.rawValue, ofType: "lproj").flatMap(Bundle.init(path:)).map { (language, $0) }
    })

    static func text(_ key: String, language: AppLanguage = Localization.shared.language) -> String {
        bundles[language]?.localizedString(forKey: key, value: key, table: nil) ?? key
    }

    static func action(_ name: String) -> String {
        let translated = text(name)
        guard translated == name else { return translated }
        for prefix in ["Add ", "Edit ", "Cancel ", "Copy ", "Hide ", "Show ", "Remove ", "New "] where name.hasPrefix(prefix) {
            let remainder = String(name.dropFirst(prefix.count))
            if remainder.hasSuffix(" Adjustment") {
                return text(prefix) + text(String(remainder.dropLast(11))) + text(" Adjustment")
            }
            return text(prefix) + text(remainder)
        }
        return name
    }

    /// Named UI strings stay separate from interpolated user content, such as filenames and layer names.
    static func format(_ key: String, _ arguments: Any..., language: AppLanguage = Localization.shared.language) -> String {
        String(format: text(key, language: language), locale: Locale(identifier: language.rawValue),
               arguments: arguments.map { String(describing: $0) })
    }
}

extension View {
    func localizedInterface() -> some View { modifier(InterfaceLanguageModifier()) }
}

private struct InterfaceLanguageModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.environment(\.locale, Locale(identifier: Localization.shared.language.rawValue))
    }
}
