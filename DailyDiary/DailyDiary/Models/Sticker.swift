import Foundation
import CoreGraphics
import SwiftUI

// MARK: - Canvas element types (used by DiaryEntry + editor/decorate views)

struct DiarySticker: Codable, Identifiable {
    var id: UUID = UUID()
    var imageName: String
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat = 1.0
    var rotation: Double = 0.0
    var zOrder: Int = 0

    enum CodingKeys: String, CodingKey {
        case id, imageName, x, y, scale, rotation, zOrder
    }

    init(imageName: String, x: CGFloat, y: CGFloat) {
        self.imageName = imageName
        self.x = x
        self.y = y
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = (try? c.decode(UUID.self,    forKey: .id))        ?? UUID()
        imageName = try  c.decode(String.self,   forKey: .imageName)
        x         = try  c.decode(CGFloat.self,  forKey: .x)
        y         = try  c.decode(CGFloat.self,  forKey: .y)
        scale     = (try? c.decode(CGFloat.self, forKey: .scale))     ?? 1.0
        rotation  = (try? c.decode(Double.self,  forKey: .rotation))  ?? 0.0
        zOrder    = (try? c.decode(Int.self,     forKey: .zOrder))    ?? 0
    }
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
    var fontName: String = "system"     // DiaryFont.Option.id
    var zOrder: Int = 0

    enum CodingKeys: String, CodingKey {
        case id, text, x, y, scale, rotation, fontSize, colorName, isBold, fontName, zOrder
    }

    init(text: String, x: CGFloat, y: CGFloat,
         fontSize: CGFloat = 20, colorName: String = "primary", isBold: Bool = false,
         fontName: String = "system", zOrder: Int = 0) {
        self.text = text
        self.x = x
        self.y = y
        self.fontSize = fontSize
        self.colorName = colorName
        self.isBold = isBold
        self.fontName = fontName
        self.zOrder = zOrder
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = (try? c.decode(UUID.self,    forKey: .id))        ?? UUID()
        text      = try  c.decode(String.self,   forKey: .text)
        x         = try  c.decode(CGFloat.self,  forKey: .x)
        y         = try  c.decode(CGFloat.self,  forKey: .y)
        scale     = (try? c.decode(CGFloat.self, forKey: .scale))     ?? 1.0
        rotation  = (try? c.decode(Double.self,  forKey: .rotation))  ?? 0.0
        fontSize  = (try? c.decode(CGFloat.self, forKey: .fontSize))  ?? 20
        colorName = (try? c.decode(String.self,  forKey: .colorName)) ?? "primary"
        isBold    = (try? c.decode(Bool.self,    forKey: .isBold))    ?? false
        fontName  = (try? c.decode(String.self,  forKey: .fontName))  ?? "system"
        zOrder    = (try? c.decode(Int.self,     forKey: .zOrder))    ?? 0
    }
}

// MARK: - 색상 시스템
struct DiaryColor {
    struct Option: Identifiable {
        let id: String      // colorName 저장값
        let color: Color
        let label: String
    }

    static let options: [Option] = [
        Option(id: "primary", color: Color(red: 80/255,  green: 60/255,  blue: 70/255),  label: "기본"),
        Option(id: "black",   color: .black,                                              label: "검정"),
        Option(id: "white",   color: .white,                                              label: "흰색"),
        Option(id: "pink",    color: Color(red: 255/255, green: 182/255, blue: 193/255), label: "핑크"),
        Option(id: "red",     color: Color(red: 255/255, green: 100/255, blue: 100/255), label: "빨강"),
        Option(id: "orange",  color: Color(red: 255/255, green: 170/255, blue: 80/255),  label: "주황"),
        Option(id: "yellow",  color: Color(red: 255/255, green: 220/255, blue: 50/255),  label: "노랑"),
        Option(id: "green",   color: Color(red: 100/255, green: 200/255, blue: 130/255), label: "초록"),
        Option(id: "blue",    color: Color(red: 100/255, green: 180/255, blue: 240/255), label: "파랑"),
        Option(id: "purple",  color: Color(red: 190/255, green: 150/255, blue: 230/255), label: "보라"),
    ]

    static func color(name: String) -> Color {
        options.first(where: { $0.id == name })?.color
            ?? Color(red: 80/255, green: 60/255, blue: 70/255)
    }

    /// 밝은 색상(흰색·노랑)은 배경과 구분을 위해 그림자 필요
    static func needsShadow(name: String) -> Bool {
        name == "white" || name == "yellow"
    }
}

// MARK: - 폰트 시스템
// ⚠️ 폰트 파일 추가 후 PostScript 이름은 Font Book 앱에서 확인하세요
struct DiaryFont {
    struct Option: Identifiable {
        let id: String      // fontName 저장값
        let label: String   // UI 표시명
    }

    static let options: [Option] = [
        Option(id: "system",          label: "기본체"),
        Option(id: "NanumGothic",     label: "나눔고딕"),
        Option(id: "NanumMyeongjo",   label: "나눔명조"),
        Option(id: "NanumPen_ac00",   label: "손글씨 펜"),
        Option(id: "NanumSquareR",    label: "나눔스퀘어"),
    ]

    static func font(name: String, size: CGFloat, isBold: Bool) -> Font {
        switch name {
        case "NanumGothic":
            return .custom(isBold ? "NanumGothicBold" : "NanumGothic", size: size)
        case "NanumMyeongjo":
            return .custom(isBold ? "NanumMyeongjoBold" : "NanumMyeongjo", size: size)
        case "NanumPen_ac00":
            return .custom("NanumPen_ac00", size: size)  // 볼드 없음
        case "NanumSquareR":
            return .custom(isBold ? "NanumSquareB" : "NanumSquareR", size: size)
        default: // "system"
            return .system(size: size, weight: isBold ? .bold : .regular, design: .rounded)
        }
    }
}

struct DiaryPhoto: Codable, Identifiable {
    var id: UUID = UUID()
    var data: Data
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat = 1.0
    var rotation: Double = 0.0
    var zOrder: Int = 0

    enum CodingKeys: String, CodingKey {
        case id, data, x, y, scale, rotation, zOrder
    }

    init(data: Data, x: CGFloat, y: CGFloat) {
        self.data = data
        self.x = x
        self.y = y
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id       = (try? c.decode(UUID.self,    forKey: .id))       ?? UUID()
        data     = try  c.decode(Data.self,     forKey: .data)
        x        = try  c.decode(CGFloat.self,  forKey: .x)
        y        = try  c.decode(CGFloat.self,  forKey: .y)
        scale    = (try? c.decode(CGFloat.self, forKey: .scale))    ?? 1.0
        rotation = (try? c.decode(Double.self,  forKey: .rotation)) ?? 0.0
        zOrder   = (try? c.decode(Int.self,     forKey: .zOrder))   ?? 0
    }
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
