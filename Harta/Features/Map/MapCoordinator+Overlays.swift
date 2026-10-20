import UIKit
@preconcurrency import MapLibre

extension MapCoordinator {
    func updateOverlays(on map: MLNMapView) {
        guard let style = map.style else { return }
        for overlay in MapOverlay.allCases {
            style.layer(withIdentifier: overlay.layerIdentifier)?.isVisible = overlay.isEnabled(in: overlaySelection)
        }
    }

    func installOverlayImages(in style: MLNStyle) {
        for overlay in MapOverlay.allCases where overlay != .cycling && overlay != .transit && overlay != .essentials {
            let color: UIColor = switch overlay {
            case .chargers: .systemGreen
            case .toilets: .systemTeal
            case .parking: .systemBlue
            default: .systemTeal
            }
            installMarker(in: style, name: overlay.layerIdentifier, symbol: overlay.symbol, color: color)
        }
        for kind in EssentialKind.allCases {
            let color: UIColor = switch kind {
            case .pharmacy: .systemGreen
            case .convenience: .systemBlue
            case .grocery: .systemOrange
            case .atm: .systemTeal
            }
            installMarker(in: style, name: kind.imageName, symbol: kind.symbol, color: color)
        }
        for kind in TransitKind.allCases {
            installMarker(in: style, name: kind.imageName, symbol: kind.symbol,
                          color: kind == .bus ? .systemBlue : .systemPurple)
        }
    }

    private func installMarker(in style: MLNStyle, name: String, symbol: String, color: UIColor) {
        let diameter: CGFloat = 22
        let image = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter)).image { _ in
            color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).setFill()
            let circle = UIBezierPath(ovalIn: CGRect(x: 1, y: 1, width: diameter - 2, height: diameter - 2))
            circle.fill()
            UIColor.white.setStroke()
            circle.lineWidth = 1.5
            circle.stroke()
            if let icon = UIImage(systemName: symbol,
                                  withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold))?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                let scale = min(1, 14 / max(icon.size.width, icon.size.height))
                let size = CGSize(width: icon.size.width * scale, height: icon.size.height * scale)
                icon.draw(in: CGRect(x: (diameter - size.width) / 2, y: (diameter - size.height) / 2,
                                     width: size.width, height: size.height))
            }
        }
        style.setImage(image, forName: name)
    }

    @objc func selectOverlay(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let map = gesture.view as? MLNMapView else { return }
        let point = gesture.location(in: map)
        if let selected = model.selectedPlace {
            let marker = map.convert(selected.coordinate, toPointTo: map)
            if hypot(marker.x - point.x, marker.y - point.y) <= 22 {
                onSelect(selected)
                return
            }
        }
        let enabled = MapOverlay.allCases.filter { $0 != .cycling && $0.isEnabled(in: overlaySelection) }
        guard !enabled.isEmpty else {
            onDeselect?()
            return
        }
        let area = CGRect(x: point.x - 22, y: point.y - 22, width: 44, height: 44)
        let features = map.visibleFeatures(in: area, styleLayerIdentifiers: Set(enabled.map(\.layerIdentifier)))
        guard let feature = features.compactMap({ $0 as? MLNPointFeature }).min(by: {
            let a = map.convert($0.coordinate, toPointTo: map)
            let b = map.convert($1.coordinate, toPointTo: map)
            return hypot(a.x - point.x, a.y - point.y) < hypot(b.x - point.x, b.y - point.y)
        }) else {
            onDeselect?()
            return
        }
        let subclass = feature.attribute(forKey: "subclass") as? String ?? "Place"
        let kind = EssentialKind.from(subclass: subclass)?.title
            ?? TransitKind.from(subclass: subclass)?.title
            ?? subclass.replacingOccurrences(of: "_", with: " ").capitalized
        let name = feature.attribute(forKey: "name:en") as? String ?? feature.attribute(forKey: "name") as? String
        let coordinate = feature.coordinate
        onSelect(Place(id: "overlay:\(coordinate.latitude):\(coordinate.longitude):\(kind)",
                       name: name.flatMap { $0.isEmpty ? nil : $0 } ?? kind, address: kind,
                       latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
}
