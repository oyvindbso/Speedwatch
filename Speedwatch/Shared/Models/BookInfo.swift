import Foundation

/// Lightweight, Codable book representation shared between iOS and watchOS.
struct BookInfo: Codable, Identifiable {
    let id: UUID
    let title: String
    let author: String?
    let currentPosition: Int
    let totalWords: Int

    var progress: Double {
        guard totalWords > 0 else { return 0 }
        return Double(currentPosition) / Double(totalWords)
    }
}
