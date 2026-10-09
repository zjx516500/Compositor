import Foundation
import AppKit
import Observation
import os
import Testing
@testable import Compositor

struct LocalizationTests {
    @Test func preferencePersistsAndUnknownLanguagesFallBackToEnglish() throws {
        let name = "LocalizationTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let localization = Localization(defaults: defaults)
        #expect(localization.language == .english)
        localization.language = .simplifiedChinese
        #expect(Localization(defaults: defaults).language == .simplifiedChinese)
        defaults.set("unknown", forKey: AppLanguage.storageKey)
        #expect(Localization(defaults: defaults).language == .english)
    }

    @Test func switchingLanguageInvalidatesObservedText() throws {
        let name = "LocalizationTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let localization = Localization(defaults: defaults)
        let changed = OSAllocatedUnfairLock(initialState: false)
        withObservationTracking { _ = L10n.text("Crop", language: localization.language) } onChange: { changed.withLock { $0 = true } }
        localization.language = .simplifiedChinese
        #expect(changed.withLock { $0 })
    }

    @Test func stringsTranslateBothWaysAndPreserveUserContent() {
        #expect(L10n.text("Crop", language: .simplifiedChinese) == "裁剪")
        #expect(L10n.text("Free", language: .simplifiedChinese) == "自由")
        #expect(L10n.text("Original", language: .simplifiedChinese) == "原始")
        #expect(L10n.text("Crop", language: .english) == "Crop")
        #expect(L10n.text("A future untranslated label", language: .simplifiedChinese) == "A future untranslated label")
        let name = "Save_照片_100%.png"
        #expect(L10n.format("Save changes to %@?", name, language: .simplifiedChinese) == "保存对 Save_照片_100%.png 的更改？")
        #expect(L10n.format("Save changes to %@?", name, language: .english) == "Save changes to Save_照片_100%.png?")
    }

    @Test func resourcesHaveMatchingKeysAndFormatArguments() throws {
        func strings(_ language: AppLanguage) throws -> [String: String] {
            let path = try #require(Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil,
                                                    forLocalization: language.rawValue))
            return try #require(PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: path)),
                                                                      format: nil) as? [String: String])
        }
        let english = try strings(.english), chinese = try strings(.simplifiedChinese)
        #expect(Set(english.keys) == Set(chinese.keys))
        for (key, value) in chinese {
            #expect(key.components(separatedBy: "%@").count == value.components(separatedBy: "%@").count)
        }
    }

    @MainActor @Test func nativeMenusSwitchBothWaysAndRecentFilenamesStayIntact() {
        let main = NSMenu()
        main.addItem(NSMenuItem(title: "Compositor", action: nil, keyEquivalent: ""))
        let file = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        file.submenu = NSMenu()
        let recentFilename = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        file.submenu?.addItem(recentFilename)
        main.addItem(file)
        let window = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        window.submenu = NSMenu()
        let minimize = NSMenuItem(title: "Minimize", action: nil, keyEquivalent: "")
        window.submenu?.addItem(minimize)
        main.addItem(window)
        InterfaceMenus.localize(main, language: .simplifiedChinese)
        #expect(file.title == "文件")
        #expect(window.title == "窗口")
        #expect(minimize.title == "最小化")
        #expect(recentFilename.title == "Window")
        InterfaceMenus.localize(main, language: .english)
        #expect(file.title == "File")
        #expect(window.title == "Window")
        #expect(minimize.title == "Minimize")
    }

}
