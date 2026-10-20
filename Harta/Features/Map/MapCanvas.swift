import SwiftUI
@preconcurrency import MapLibre

struct MapCanvas: UIViewRepresentable {
    let model: MapModel
    let directions: DirectionsModel
    let userCoordinate: CLLocationCoordinate2D?
    let isShowingPlace: Bool
    let onSelect: (Place) -> Void
    var isNavigating = false
    var onPan: (() -> Void)?
    var compactPlaceCard = false
    @AppStorage(MapStyle.preferenceKey) private var mapStyle: MapStyle = .everyday
    @AppStorage(MapOverlay.preferenceKey) private var overlays = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeCoordinator() -> MapCoordinator {
        MapCoordinator(model: model, onSelect: onSelect)
    }

    func makeUIView(context: Context) -> MLNMapView {
        let view = MLNMapView(frame: .zero, styleURL: styleURL)
        view.delegate = context.coordinator
        view.setCenter(CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude),
                       zoomLevel: model.zoom, animated: false)
        view.isPitchEnabled = false
        view.isRotateEnabled = false
        view.compassView.isHidden = true
        view.logoView.isHidden = true
        view.attributionButton.isHidden = true
        view.automaticallyAdjustsContentInset = false
        view.accessibilityLabel = "Map. Use Search to find a place, or press and hold to drop a pin."
        context.coordinator.overlaySelection = overlays
        context.coordinator.lastCameraRequest = model.cameraRequest
        context.coordinator.lastReloadRequest = model.styleReloadRequest
        let press = UILongPressGestureRecognizer(target: context.coordinator,
                                                 action: #selector(MapCoordinator.dropPin(_:)))
        if !isNavigating {
            view.addGestureRecognizer(press)
            let tap = UITapGestureRecognizer(target: context.coordinator,
                                             action: #selector(MapCoordinator.selectOverlay(_:)))
            tap.require(toFail: press)
            // Preserve the map's double-tap zoom gesture.
            for recognizer in view.gestureRecognizers ?? [] {
                if let existing = recognizer as? UITapGestureRecognizer, existing.numberOfTapsRequired > 1 {
                    tap.require(toFail: existing)
                }
            }
            view.addGestureRecognizer(tap)
        }
        return view
    }

    func updateUIView(_ view: MLNMapView, context: Context) {
        let coordinator = context.coordinator
        coordinator.overlaySelection = overlays
        coordinator.updateOverlays(on: view)
        coordinator.onSelect = onSelect
        coordinator.onPan = onPan
        coordinator.fitsRouteCamera = !isNavigating
        view.attributionButton.isHidden = true
        let inset = UIEdgeInsets(top: isNavigating ? 200 : 100, left: 0,
                                 bottom: isShowingPlace ? (compactPlaceCard ? 350 : view.bounds.height * 0.52) : (isNavigating ? 220 : 100), right: 0)
        if view.contentInset != inset { view.contentInset = inset }
        if view.styleURL != styleURL {
            view.styleURL = styleURL
        }
        if coordinator.lastReloadRequest != model.styleReloadRequest {
            coordinator.lastReloadRequest = model.styleReloadRequest
            view.reloadStyle(view)
        }
        if coordinator.lastCameraRequest != model.cameraRequest {
            coordinator.lastCameraRequest = model.cameraRequest
            view.setCenter(CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude),
                           zoomLevel: model.zoom, animated: !reduceMotion)
        }
        coordinator.updateRoute(on: view, directions: directions, animated: !reduceMotion)
        coordinator.updateAnnotations(on: view, selected: model.selectedPlace, user: userCoordinate,
                                      isDark: colorScheme == .dark)
    }

    static func dismantleUIView(_ view: MLNMapView, coordinator: MapCoordinator) {
        view.delegate = nil
    }

    private var styleURL: URL? {
        mapStyle.url(isDark: colorScheme == .dark)
    }
}
