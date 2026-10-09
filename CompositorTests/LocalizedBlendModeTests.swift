import AppKit
import Testing
@testable import Compositor

@MainActor struct LocalizedBlendModeTests {
    @Test func translatedMenuUsesTheModelValueForPreviewAndCommit() throws {
        let session = EditorSession()
        session.createDocument(width: 32, height: 32)
        session.addBlankLayer()
        let coordinator = BlendModePicker.Coordinator(session: session)
        let button = NSPopUpButton()
        button.addItem(withTitle: L10n.text("Multiply", language: .simplifiedChinese))
        let item = try #require(button.lastItem)
        item.representedObject = LayerBlendMode.multiply.rawValue
        let menu = try #require(button.menu)
        coordinator.menuWillOpen(menu)
        coordinator.menu(menu, willHighlight: item)
        #expect(session.displayedBlendMode(for: try #require(session.activeLayer)) == .multiply)
        coordinator.choose(button)
        #expect(session.activeLayer?.blendMode == .multiply)
        session.undo()
        #expect(session.activeLayer?.blendMode == .normal)
    }
}
