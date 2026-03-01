import Foundation
import SwiftData

@available(iOS 17, *)
@Model
final class DiaryEntry {
    var id: UUID
    var dateKey: String          // "yyyy-MM-dd" format for grouping
    var content: String
    var photoDataArray: [Data]
    var stickerEmoji: String
    var createdAt: Date
    var updatedAt: Date
    var stickersData: Data = Data()
    var textBlocksData: Data = Data()
    var canvasPhotosData: Data = Data()

    var stickers: [DiarySticker] {
        get { (try? JSONDecoder().decode([DiarySticker].self, from: stickersData)) ?? [] }
        set { stickersData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var textBlocks: [DiaryTextBlock] {
        get { (try? JSONDecoder().decode([DiaryTextBlock].self, from: textBlocksData)) ?? [] }
        set { textBlocksData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var canvasPhotos: [DiaryPhoto] {
        get { (try? JSONDecoder().decode([DiaryPhoto].self, from: canvasPhotosData)) ?? [] }
        set { canvasPhotosData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

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
        self.stickersData = Data()
        self.textBlocksData = Data()
        self.canvasPhotosData = Data()
    }
}
