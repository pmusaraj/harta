@preconcurrency import MapLibre

final class PlaceMapAnnotation: MLNPointAnnotation {
    let place: Place
    let tint: SavedPlaceTint
    let icon: SavedPlaceIcon?
    let isSelectedPlace: Bool

    init(place: Place, icon: SavedPlaceIcon?, isSelected: Bool, tint: SavedPlaceTint = .teal) {
        self.tint = tint
        self.place = place
        self.icon = icon
        self.isSelectedPlace = isSelected
        super.init()
        coordinate = place.coordinate
        title = place.name
    }

    required init?(coder: NSCoder) { nil }
}
