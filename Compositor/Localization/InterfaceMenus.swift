import AppKit

/// SwiftUI owns custom command titles; AppKit owns the standard menu titles and window commands. Preserve
/// their original text per item so changing back to English works even on a menu that was not rebuilt.
@MainActor
enum InterfaceMenus {
    private static let originals = NSMapTable<NSMenuItem, NSString>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private static let titles: Set<String> = [
        "File", "Edit", "View", "Window", "Help", "Language", "About Compositor", "Quit Compositor", "Services",
        "Minimize", "Minimize All", "Zoom", "Zoom All", "Fill", "Center", "Move & Resize", "Full Screen Tile",
        "Arrange in Front", "Bring All to Front", "Remove Window from Set", "Move to", "Move to Left",
        "Move to Right", "Move to Top", "Move to Bottom", "Left", "Right", "Top", "Bottom", "Return to Previous Size",
        "Enter Full Screen", "Exit Full Screen", "Compositor Help"
    ]

    static func localize(_ suppliedMenu: NSMenu? = nil, language: AppLanguage? = nil) {
        guard let menu = suppliedMenu ?? NSApp.mainMenu else { return }
        localizeItems(in: menu, isMain: true, language: language ?? Localization.shared.language)
    }

    private static func localizeItems(in menu: NSMenu, isMain: Bool, language: AppLanguage) {
        for (index, item) in menu.items.enumerated() {
            if isMain, index == 0 {
                if let submenu = item.submenu { localizeItems(in: submenu, isMain: false, language: language) }
                continue
            }
            // Translated SwiftUI commands are already up to date. A tracked AppKit item may have been rebuilt.
            let previous = originals.object(forKey: item) as String?
            let key: String
            if titles.contains(item.title) { key = item.title }
            else if let original = titles.first(where: { L10n.text($0, language: .simplifiedChinese) == item.title }) { key = original }
            else if let previous, item.title == L10n.text(previous, language: .simplifiedChinese) { key = previous }
            else { continue }
            originals.setObject(key as NSString, forKey: item)
            item.title = L10n.text(key, language: language)
            if let submenu = item.submenu, !isMain || key == "Window" { localizeItems(in: submenu, isMain: false, language: language) }
        }
    }
}

extension NSSavePanel {
    func localizeForSaving() {
        prompt = L10n.text("Save")
        nameFieldLabel = L10n.text("Save As:")
    }
}
