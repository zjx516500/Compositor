import Foundation

nonisolated enum SaveFilename {
    /// A new destination keeps the opened file's stem and adds a filesystem-safe local timestamp.
    static func suggested(source: URL?, untitled: String, extension fileExtension: String,
                          date: Date = Date(), timeZone: TimeZone = .current) -> String {
        guard let source else { return untitled + "." + fileExtension }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return source.deletingPathExtension().lastPathComponent + "_" + formatter.string(from: date) + "." + fileExtension
    }
}
