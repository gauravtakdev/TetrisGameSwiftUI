import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

enum Theme {
    static let background = Color(hex: 0x0E0F1E)
    static let card = Color(hex: 0x1B2030)
    static let cardBorder = Color(hex: 0x2A3144)
    static let accent = Color(hex: 0xD98336)
    static let button = Color(hex: 0x4A475A)
    static let secondaryText = Color(hex: 0xA6A9C4)
    static let boardTop = Color(hex: 0x131A2E)
    static let boardBottom = Color(hex: 0x070810)
}
