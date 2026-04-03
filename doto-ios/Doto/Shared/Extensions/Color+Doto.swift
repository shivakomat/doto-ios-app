import SwiftUI

extension Color {
    static let memberBlue   = Color(hex: "#185FA5")
    static let memberGreen  = Color(hex: "#1D9E75")
    static let memberAmber  = Color(hex: "#BA7517")
    static let memberMaroon = Color(hex: "#993556")
    static let memberPurple = Color(hex: "#534AB7")
    static let memberRed    = Color(hex: "#E24B4A")

    static let memberPalette: [Color] = [
        .memberBlue, .memberGreen, .memberAmber,
        .memberMaroon, .memberPurple, .memberRed
    ]

    static let memberHexPalette = [
        "#185FA5", "#1D9E75", "#BA7517",
        "#993556", "#534AB7", "#E24B4A"
    ]

    // Backend API color palette (6 colors)
    static let settingsColorPalette = [
        "#6C63FF",  // Purple (default)
        "#FF6B6B",  // Red/Coral
        "#4ECDC4",  // Teal
        "#FFE66D",  // Yellow
        "#95E1D3",  // Mint
        "#F38181"   // Pink
    ]

    static let appNavy      = Color(hex: "#1E2761")
    static let appNavySub   = Color(hex: "#CADCFC")

    static let conflictBg     = Color(hex: "#FAEEDA")
    static let conflictBorder = Color(hex: "#F0C070")
    static let conflictText   = Color(hex: "#633806")
    static let overdueBg      = Color(hex: "#FCEBEB")
    static let overdueText    = Color(hex: "#791F1F")
    static let doneBg         = Color(hex: "#EAF3DE")
    static let doneText       = Color(hex: "#27500A")
    static let dueTodayBg     = Color(hex: "#FAEEDA")
    static let dueTodayText   = Color(hex: "#633806")
    static let selectedDayBg  = Color(hex: "#DBEAFE")

    static let screenBg      = Color(hex: "#F8FAFC")
    static let cardBorder    = Color(hex: "#E2E8F0")
    static let textPrimary   = Color(hex: "#1E293B")
    static let textSecondary = Color(hex: "#64748B")
    static let textMuted     = Color(hex: "#94A3B8")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red:   Double((int & 0xFF0000) >> 16) / 255,
            green: Double((int & 0x00FF00) >> 8)  / 255,
            blue:  Double(int & 0x0000FF)          / 255
        )
    }
}
