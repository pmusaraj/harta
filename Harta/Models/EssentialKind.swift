import Foundation

enum EssentialKind: String, CaseIterable {
    case pharmacy, convenience, grocery, atm

    var imageName: String { "harta-essential-\(rawValue)" }
    var symbol: String {
        switch self {
        case .pharmacy: "cross.case"
        case .convenience: "storefront"
        case .grocery: "basket"
        case .atm: "banknote"
        }
    }
    var title: String {
        switch self {
        case .pharmacy: "Pharmacy"
        case .convenience: "Corner store"
        case .grocery: "Groceries"
        case .atm: "ATM"
        }
    }
    static func from(subclass: String) -> EssentialKind? {
        switch subclass {
        case "pharmacy": .pharmacy
        case "convenience": .convenience
        case "supermarket", "grocery", "greengrocer", "marketplace": .grocery
        case "atm": .atm
        default: nil
        }
    }
}
