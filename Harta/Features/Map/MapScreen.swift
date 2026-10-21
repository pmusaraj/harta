import SwiftUI

struct MapScreen: View {
    @State private var model = MapModel()
    @State private var directions = DirectionsModel()
    @State private var location = LocationService()
    @State private var saved = SavedPlacesStore()
    @State private var search = SearchModel()
    @State private var recents = RecentPlacesStore()
    @State private var searching = false
    @State private var placeDetent: PresentationDetent = .height(320)
    @State private var sheet: MapSheet?
    @State private var pendingPlace: Place?
    @State private var alertMessage: String?
    @State private var showLocationError = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        MapCanvas(model: model, directions: directions, userCoordinate: location.fix?.coordinate,
                  isShowingPlace: sheet == .place, onSelect: selectFromMap,
                  onPan: model.stopLocationCentering,
                  onDeselect: dismissMapPanes,
                  compactPlaceCard: placeDetent == .height(320), savedPlaces: saved.places)
            .ignoresSafeArea()
            .accessibilityAction(named: "Drop pin here", dropCenterPin)
            .overlay {
                if searching {
                    Button(action: dismissMapPanes) {
                        Color.clear.contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss search")
                    .accessibilityIdentifier("search.dismiss")
                }
            }
            .overlay(alignment: .top) {
                if searching {
                    SearchPanel(model: search, store: saved, recents: recents,
                                latitude: model.latitude, longitude: model.longitude,
                                onSelect: selectFromSearch, onClose: { searching = false })
                        .padding()
                } else {
                    HStack(spacing: 10) {
                        Spacer()
                        Button("Settings", systemImage: "gearshape", action: openSettings)
                            .labelStyle(.iconOnly)
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .frame(width: 52, height: 52)
                            .background(.regularMaterial, in: .rect(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                            .accessibilityIdentifier("map.settings")
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
            }
            .overlay(alignment: .leading) {
                MapCredits()
                    .padding(.leading, 2)
            }
            .overlay(alignment: .bottom) {
                if !searching {
                    MapControls(isLocating: location.isLocating, onSaved: openSaved,
                                onLocate: locateUser, onSearch: openSearch,
                                onLayers: { sheet = .layers })
                        .padding(.horizontal)
                        .padding(.bottom, 2)
                }
            }
            .overlay(alignment: .top) {
                if let error = model.mapError {
                    MapErrorBanner(message: error, retry: model.retryMap)
                        .padding(.top, 80)
                        .padding(.horizontal)
                }
            }
            .sheet(item: $sheet, onDismiss: finishDismissal) { activeSheet in
                Group {
                    switch activeSheet {
                    case .saved:
                        SavedPlacesSheet(store: saved, onSelect: selectFromSheet)
                            .presentationDetents([.medium, .large])
                    case .place:
                        if let place = model.selectedPlace {
                            PlaceSheet(place: place, store: saved, directionsModel: directions, location: location, detent: $placeDetent)
                                .presentationDetents([.height(320), .medium, .large], selection: $placeDetent)
                        }
                    case .layers:
                        MapLayersSheet()
                            .presentationDetents([.medium, .large])
                    case .settings:
                        SettingsSheet()
                            .presentationDetents([.medium, .large])
                    }
                }
                .presentationBackgroundInteraction(.enabled)
            }
            .task {
                if model.beginStartupLocation() { location.startTracking(requestPermission: true) }
            }
            .onChange(of: location.fix) { _, fix in
                if let fix, sheet != .place { model.receiveLocation(fix.coordinate) }
            }
            .onChange(of: location.errorMessage) { _, message in
                if let message {
                    model.stopLocationCentering()
                    alertMessage = message
                    showLocationError = true
                    location.errorMessage = nil
                }
            }
            .onChange(of: scenePhase) { _, phase in
                // Permission prompts temporarily make the scene inactive. Keep the request alive.
                if phase == .background { location.stop(); search.cancel() }
                if phase == .active { location.startTracking() }
            }
            .alert("Location", isPresented: $showLocationError) {
                Button("OK", role: .cancel) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
    }

    private func locateUser() {
        model.requestLocationCentering()
        location.locate()
    }

    private func openSearch() {
        model.stopLocationCentering()
        search.query = ""; search.queryChanged(); searching = true
    }
    private func selectFromSearch(_ place: Place) {
        searching = false
        selectFromMap(place)
    }
    private func openSaved() { sheet = .saved }
    private func openSettings() { sheet = .settings }
    private func dropCenterPin() { selectFromMap(model.centerPin()) }

    private func selectFromMap(_ place: Place) {
        searching = false
        placeDetent = .height(320)
        directions.clear()
        model.focus(on: place)
        sheet = .place
    }

    private func selectFromSheet(_ place: Place) {
        pendingPlace = place
        sheet = nil
    }

    private func dismissMapPanes() {
        searching = false
        pendingPlace = nil
        model.selectedPlace = nil
        directions.clear()
        sheet = nil
    }

    private func finishDismissal() {
        directions.clear()
        guard let place = pendingPlace else { return }
        pendingPlace = nil
        placeDetent = .height(320)
        model.focus(on: place)
        sheet = .place
    }
}
