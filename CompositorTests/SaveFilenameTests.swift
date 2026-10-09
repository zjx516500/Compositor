import Foundation
import Testing
@testable import Compositor

struct SaveFilenameTests {
    @Test func openedFileKeepsItsWholeStemAndAddsLocalTimestamp() {
        let source = URL(fileURLWithPath: "/images/照片.edit.final.jpeg")
        let date = Date(timeIntervalSince1970: 0)
        let timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        #expect(SaveFilename.suggested(source: source, untitled: "Untitled", extension: "png", date: date,
                                      timeZone: timeZone) == "照片.edit.final_19700101_080000.png")
        #expect(SaveFilename.suggested(source: source, untitled: "Untitled", extension: "comp", date: date,
                                      timeZone: timeZone) == "照片.edit.final_19700101_080000.comp")
        #expect(SaveFilename.suggested(source: source, untitled: "Untitled", extension: "pdf", date: date,
                                      timeZone: timeZone) == "照片.edit.final_19700101_080000.pdf")
    }

    @Test func newCanvasHasNoSourceTimestamp() {
        #expect(SaveFilename.suggested(source: nil, untitled: "Untitled", extension: "comp") == "Untitled.comp")
        #expect(SaveFilename.suggested(source: nil, untitled: "未命名", extension: "png") == "未命名.png")
    }

    @MainActor @Test func importsRememberTheFirstSuccessfulFileAndProjectsTakePriority() async throws {
        let first = try ImageImportTests().fixture(.png)
        let second = try ImageImportTests().fixture(.png)
        defer {
            try? FileManager.default.removeItem(at: first)
            try? FileManager.default.removeItem(at: second)
        }
        let session = EditorSession()
        let date = Date(timeIntervalSince1970: 0), timeZone = TimeZone(secondsFromGMT: 0)!
        await session.importImages([first.appendingPathExtension("missing"), first])
        #expect(session.sourceImageURL == first)
        await session.importImages([second])
        #expect(session.sourceImageURL == first)
        let controller = ProjectController(session: session)
        #expect(controller.suggestedFilename(extension: "png", date: date, timeZone: timeZone)
                == first.deletingPathExtension().lastPathComponent + "_19700101_000000.png")
        let project = URL(fileURLWithPath: "/projects/合成.comp")
        let snapshot = try #require(session.projectSnapshot())
        session.installProject(snapshot, from: project)
        #expect(session.sourceImageURL == nil)
        #expect(controller.suggestedFilename(extension: "jpeg", date: date, timeZone: timeZone) == "合成_19700101_000000.jpeg")
        session.clearProject()
        #expect(session.sourceImageURL == nil)
        #expect(session.projectURL == nil)
    }

    @MainActor @Test func addingAnImageToANewCanvasDoesNotGiveItASourceFilename() async throws {
        let url = try ImageImportTests().fixture(.png)
        defer { try? FileManager.default.removeItem(at: url) }
        let session = EditorSession()
        session.createNewProject(width: 128, height: 128)
        await session.importImages([url])
        #expect(session.sourceImageURL == nil)
    }
}
