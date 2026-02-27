import Foundation
import SwiftData

@Model
final class DiaryEntry {
    var id: UUID
    var dateKey: String          // "yyyy-MM-dd" format for grouping
    var content: String
    var photoDataArray: [Data]
    var stickerEmoji: String
    var createdAt: Date
    var updatedAt: Date

    init(
        dateKey: String,
        content: String = "",
        photoDataArray: [Data] = [],
        stickerEmoji: String = "🌸"
    ) {
        self.id = UUID()
        self.dateKey = dateKey
        self.content = content
        self.photoDataArray = photoDataArray
        self.stickerEmoji = stickerEmoji
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
