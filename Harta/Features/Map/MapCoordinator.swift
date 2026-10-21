import SwiftUI
@preconcurrency import MapLibre

@MainActor
final class MapCoordinator: NSObject, @preconcurrency MLNMapViewDelegate {
    let model: MapModel
    var onSelect: (Place) -> Void
    var onDeselect: (() -> Void)?
    var onPan: (() -> Void)?
    var fitsRouteCamera = true
    var overlaySelection = 0
    var lastRouteCameraRequest: UUID?
    var routeID: UUID?
    var stepID: Int?
    var routeDirections: DirectionsModel?
    var lastCameraRequest: UUID?
    var lastReloadRequest: UUID?
    private var selectedAnnotation: PlaceMapAnnotation?
    private var savedAnnotations: [String: PlaceMapAnnotation] = [:]
    private var locationAnnotation: MLNPointAnnotation?
    private var selectedPlace: Place?
    private var usesDarkMarkers = false

    init(model: MapModel, onSelect: @escaping (Place) -> Void) {
        self.model = model
        self.onSelect = onSelect
    }

    @objc func dropPin(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let map = gesture.view as? MLNMapView else { return }
        onSelect(.pin(at: map.convert(gesture.location(in: map), toCoordinateFrom: map)))
    }

    func mapView(_ mapView: MLNMapView, regionWillChangeAnimated animated: Bool) {
        if mapView.gestureRecognizers?.contains(where: { $0.state == .began || $0.state == .changed }) == true {
            onPan?()
        }
    }

    func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        let zoom = mapView.zoomLevel
        Task { @MainActor [weak self] in
            self?.model.viewportChanged(center: center, zoom: zoom)
        }
    }

    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        installOverlayImages(in: style)
        updateOverlays(on: mapView)
        routeID = nil
        if let routeDirections { updateRoute(on: mapView, directions: routeDirections, animated: false) }
    }

    func mapViewDidFinishLoadingMap(_ mapView: MLNMapView) {
        mapView.attributionButton.isHidden = true
        Task { @MainActor [weak self] in self?.model.mapError = nil }
    }

    func mapViewDidFailLoadingMap(_ mapView: MLNMapView, withError error: Error) {
        Task { @MainActor [weak self] in
            self?.model.mapError = "The map couldn’t load. Check your connection and try again."
        }
    }

    func mapView(_ mapView: MLNMapView, didSelect annotation: any MLNAnnotation) {
        guard let annotation = annotation as? PlaceMapAnnotation else { return }
        onSelect(annotation.place)
    }

    func mapView(_ mapView: MLNMapView, imageFor annotation: any MLNAnnotation) -> MLNAnnotationImage? {
        if let place = annotation as? PlaceMapAnnotation, let icon = place.icon {
            let identifier = "saved-\(icon.rawValue)-\(place.isSelectedPlace)-\(usesDarkMarkers)"
            if let reused = mapView.dequeueReusableAnnotationImage(withIdentifier: identifier) { return reused }
            return MLNAnnotationImage(image: SavedPlaceMarker.image(icon: icon, selected: place.isSelectedPlace,
                                                                   dark: usesDarkMarkers),
                                      reuseIdentifier: identifier)
        }
        let isLocation = annotation === locationAnnotation
        let identifier = isLocation ? "location" : (usesDarkMarkers ? "target-dark" : "target-light")
        if let reused = mapView.dequeueReusableAnnotationImage(withIdentifier: identifier) { return reused }
        let size = isLocation ? 36.0 : 40.0
        // Rasterize explicit colors: MapLibre does not preserve SF Symbol palette rendering.
        let image = UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { _ in
            if isLocation {
                UIColor.systemBlue.withAlphaComponent(0.18).setFill()
                UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).fill()
                UIColor.white.setFill()
                UIBezierPath(ovalIn: CGRect(x: 7, y: 7, width: 22, height: 22)).fill()
                UIColor.systemBlue.setFill()
                UIBezierPath(ovalIn: CGRect(x: 10, y: 10, width: 16, height: 16)).fill()
                return
            }
            let bounds = CGRect(x: 1, y: 1, width: size - 2, height: size - 2)
            if !usesDarkMarkers {
                UIColor.white.setFill()
                UIBezierPath(ovalIn: bounds).fill()
            }
            let teal = UIColor.systemTeal.resolvedColor(with:
                UITraitCollection(userInterfaceStyle: usesDarkMarkers ? .dark : .light))
            teal.setStroke()
            let border = UIBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
            border.lineWidth = 2.5
            border.stroke()
            let innerRing = UIBezierPath(ovalIn: CGRect(x: 10, y: 10, width: 20, height: 20))
            innerRing.lineWidth = 2
            innerRing.stroke()
            teal.setFill()
            UIBezierPath(ovalIn: CGRect(x: 17, y: 17, width: 6, height: 6)).fill()
        }.withRenderingMode(.alwaysOriginal)
        return MLNAnnotationImage(image: image, reuseIdentifier: identifier)
    }

    func updateAnnotations(on map: MLNMapView, selected: Place?, user: CLLocationCoordinate2D?, isDark: Bool,
                           saved: [Place] = []) {
        let appearanceChanged = usesDarkMarkers != isDark
        usesDarkMarkers = isDark
        let selectedIcon = saved.first { $0.id == selected?.id }?.icon ?? selected?.suggestedIcon
        if selectedPlace != selected || selectedAnnotation?.icon != selectedIcon || appearanceChanged {
            if let selectedAnnotation { map.removeAnnotation(selectedAnnotation) }
            selectedAnnotation = nil
            selectedPlace = selected
            if let selected {
                let annotation = PlaceMapAnnotation(place: selected, icon: selectedIcon, isSelected: true)
                selectedAnnotation = annotation
                map.addAnnotation(annotation)
            }
        }
        let visibleSaved = saved.filter { $0.id != selected?.id }
        let savedByID = Dictionary(visibleSaved.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for (id, annotation) in savedAnnotations {
            if savedByID[id] != annotation.place || appearanceChanged {
                map.removeAnnotation(annotation)
                savedAnnotations.removeValue(forKey: id)
            }
        }
        for place in visibleSaved where savedAnnotations[place.id] == nil {
            let annotation = PlaceMapAnnotation(place: place, icon: place.icon, isSelected: false)
            savedAnnotations[place.id] = annotation
            map.addAnnotation(annotation)
        }
        if let user {
            if let locationAnnotation {
                if locationAnnotation.coordinate.latitude != user.latitude || locationAnnotation.coordinate.longitude != user.longitude {
                    locationAnnotation.coordinate = user
                }
            } else {
                let annotation = MLNPointAnnotation()
                annotation.coordinate = user
                annotation.title = "Your last located position"
                locationAnnotation = annotation
                map.addAnnotation(annotation)
            }
        }
    }

    func savedPlace(at point: CGPoint, on map: MLNMapView) -> Place? {
        savedAnnotations.values.compactMap { annotation -> (Place, CGFloat)? in
            let marker = map.convert(annotation.coordinate, toPointTo: map)
            let distance = hypot(marker.x - point.x, marker.y - point.y)
            return distance <= 22 ? (annotation.place, distance) : nil
        }.min { $0.1 < $1.1 }?.0
    }
}
