import UIKit

enum SavedPlaceMarker {
    static func image(icon: SavedPlaceIcon, selected: Bool, dark: Bool) -> UIImage {
        let size = 44.0
        let traits = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
        let teal = UIColor.systemTeal.resolvedColor(with: traits)
        return UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { _ in
            if selected {
                teal.setStroke()
                let ring = UIBezierPath(ovalIn: CGRect(x: 1.5, y: 1.5, width: 41, height: 41))
                ring.lineWidth = 2.5
                ring.stroke()
            }
            let circle = UIBezierPath(ovalIn: CGRect(x: 7, y: 7, width: 30, height: 30))
            (dark ? UIColor(red: 0.10, green: 0.15, blue: 0.17, alpha: 1) : .white).setFill()
            circle.fill()
            teal.setStroke()
            circle.lineWidth = 1.5
            circle.stroke()
            if let symbol = UIImage(systemName: icon.symbol,
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))?
                .withTintColor(teal, renderingMode: .alwaysOriginal) {
                let scale = min(1, 19 / max(symbol.size.width, symbol.size.height))
                let symbolSize = CGSize(width: symbol.size.width * scale, height: symbol.size.height * scale)
                symbol.draw(in: CGRect(x: (size - symbolSize.width) / 2, y: (size - symbolSize.height) / 2,
                                       width: symbolSize.width, height: symbolSize.height))
            }
        }.withRenderingMode(.alwaysOriginal)
    }
}
