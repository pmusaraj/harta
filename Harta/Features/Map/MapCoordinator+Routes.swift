import SwiftUI
@preconcurrency import MapLibre

extension MapCoordinator {
    func updateRoute(on map: MLNMapView, directions: DirectionsModel, animated: Bool) {
        routeDirections = directions
        guard let style = map.style else { return }
        let route = directions.route
        if routeID != route?.id || stepID != directions.selectedStep?.id {
            for id in ["route-highlight", "route-line"] {
                if let layer = style.layer(withIdentifier: id) { style.removeLayer(layer) }
                if let source = style.source(withIdentifier: id) { style.removeSource(source) }
            }
            if let route {
                addLine(route.points, id: "route-line", color: .systemTeal, width: 6, style: style)
                if let step = directions.selectedStep {
                    addLine(Array(route.points[step.start...step.end]), id: "route-highlight",
                            color: .systemOrange, width: 9, style: style)
                }
            }
            routeID = route?.id
            stepID = directions.selectedStep?.id
        }
        guard fitsRouteCamera, let route, lastRouteCameraRequest != directions.cameraRequest else { return }
        lastRouteCameraRequest = directions.cameraRequest
        let points: [MapRoute.Point]
        if let step = directions.selectedStep {
            points = Array(route.points[step.start...step.end])
        } else { points = route.points }
        var coordinates = points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        guard let first = coordinates.first else { return }
        if coordinates.count == 1 {
            map.setCenter(first, zoomLevel: 17, animated: animated)
        } else {
            let line = MLNPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
            map.setVisibleCoordinateBounds(line.overlayBounds,
                edgePadding: UIEdgeInsets(top: 80, left: 35, bottom: 40, right: 35), animated: animated)
        }
    }
    private func addLine(_ points: [MapRoute.Point], id: String, color: UIColor, width: Double, style: MLNStyle) {
        guard points.count >= 2 else { return }
        var coordinates = points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        let shape = MLNPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
        let source = MLNShapeSource(identifier: id, shape: shape, options: nil)
        let layer = MLNLineStyleLayer(identifier: id, source: source)
        layer.lineColor = NSExpression(forConstantValue: color)
        layer.lineWidth = NSExpression(forConstantValue: width)
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "round")
        style.addSource(source)
        style.addLayer(layer)
    }
}
