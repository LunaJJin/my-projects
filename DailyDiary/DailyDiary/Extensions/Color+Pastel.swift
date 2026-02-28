import SwiftUI
import UIKit

extension Color {
    func withOpacity(_ value: Double) -> Color {
        Color(UIColor(self).withAlphaComponent(CGFloat(value)))
    }

    // Main pastel theme colors
    static let pastelPink = Color(red: 255/255, green: 182/255, blue: 193/255)
    static let pastelPinkLight = Color(red: 255/255, green: 228/255, blue: 235/255)
    static let pastelPinkBackground = Color(red: 255/255, green: 245/255, blue: 248/255)
    static let pastelLavender = Color(red: 232/255, green: 213/255, blue: 245/255)
    static let pastelLavenderLight = Color(red: 245/255, green: 237/255, blue: 252/255)
    static let pastelYellow = Color(red: 255/255, green: 249/255, blue: 196/255)
    static let pastelYellowWarm = Color(red: 255/255, green: 240/255, blue: 180/255)
    static let pastelMint = Color(red: 200/255, green: 240/255, blue: 228/255)
    static let pastelPeach = Color(red: 255/255, green: 218/255, blue: 193/255)
    static let pastelBlue = Color(red: 189/255, green: 224/255, blue: 254/255)

    // Text colors
    static let diaryText = Color(red: 80/255, green: 60/255, blue: 70/255)
    static let diaryTextLight = Color(red: 160/255, green: 130/255, blue: 145/255)
    static let diaryTextMuted = Color(red: 200/255, green: 175/255, blue: 185/255)

    // Card & surface colors
    static let cardBackground = Color(white: 1.0, opacity: 0.9)
    static let cardShadow = Color(red: 255/255, green: 182/255, blue: 193/255, opacity: 0.3)
}

// Gradient presets
extension LinearGradient {
    static let pastelBackground = LinearGradient(
        colors: [Color.pastelPinkBackground, Color.pastelLavenderLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let pastelHeader = LinearGradient(
        colors: [Color.pastelPink, Color.pastelLavender],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let pastelCard = LinearGradient(
        colors: [Color.white, Color(red: 255/255, green: 228/255, blue: 235/255, opacity: 0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
