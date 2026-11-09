import SwiftUI
import UIKit

enum SavedPlaceTint: String, CaseIterable, Identifiable, Sendable {
    case teal, blue, purple, pink, orange, green

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var color: Color { Color(uiColor: uiColor) }

    var uiColor: UIColor {
        UIColor { traits in
            let dark = traits.userInterfaceStyle == .dark
            let hex: UInt32 = switch self {
            case .teal: dark ? 0x87B9B3 : 0x559B93
            case .blue: dark ? 0x91AFCD : 0x6C95BC
            case .purple: dark ? 0xB3A0C8 : 0x9E83B5
            case .pink: dark ? 0xD1A0B1 : 0xC2829B
            case .orange: dark ? 0xD5B084 : 0xC09460
            case .green: dark ? 0xA6BA95 : 0x86A171
            }
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255,
                           alpha: 1)
        }
    }
}
