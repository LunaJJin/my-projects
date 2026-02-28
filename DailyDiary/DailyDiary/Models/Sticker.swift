import Foundation
import CoreGraphics

// MARK: - Canvas element types (used by DiaryEntry + editor/decorate views)

struct DiarySticker: Codable, Identifiable {
    var id: UUID = UUID()
    var imageName: String
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat = 1.0
    var rotation: Double = 0.0
}

struct DiaryTextBlock: Codable, Identifiable {
    var id: UUID = UUID()
    var text: String
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat = 1.0
    var rotation: Double = 0.0
    var fontSize: CGFloat = 20
    var colorName: String = "primary"   // "primary", "white", "pink"
    var isBold: Bool = false

    init(text: String, x: CGFloat, y: CGFloat,
         fontSize: CGFloat = 20, colorName: String = "primary", isBold: Bool = false) {
        self.text = text
        self.x = x
        self.y = y
        self.fontSize = fontSize
        self.colorName = colorName
        self.isBold = isBold
    }
}

struct DiaryPhoto: Codable, Identifiable {
    var id: UUID = UUID()
    var data: Data
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat = 1.0
    var rotation: Double = 0.0
}

// MARK: - Emoji sticker picker model

struct Sticker: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let name: String

    static let all: [Sticker] = [
        Sticker(emoji: "🌸", name: "벚꽃"),
        Sticker(emoji: "💖", name: "하트"),
        Sticker(emoji: "🎀", name: "리본"),
        Sticker(emoji: "⭐", name: "별"),
        Sticker(emoji: "🌈", name: "무지개"),
        Sticker(emoji: "🦋", name: "나비"),
        Sticker(emoji: "🍰", name: "케이크"),
        Sticker(emoji: "🌷", name: "튤립"),
        Sticker(emoji: "🐰", name: "토끼"),
        Sticker(emoji: "☁️", name: "구름"),
        Sticker(emoji: "🍓", name: "딸기"),
        Sticker(emoji: "🧸", name: "곰돌이"),
        Sticker(emoji: "💫", name: "반짝"),
        Sticker(emoji: "🌙", name: "달"),
        Sticker(emoji: "🎵", name: "음표"),
        Sticker(emoji: "💐", name: "꽃다발"),
    ]

    // Calendar stickers shown on days with entries
    static let calendarStickers: [String] = [
        "🌸", "💖", "🎀", "⭐", "🦋", "🍰", "🌷", "🐰"
    ]

    static func randomCalendarSticker() -> String {
        calendarStickers.randomElement() ?? "🌸"
    }
}
