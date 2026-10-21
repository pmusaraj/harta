import SwiftUI
import CoreLocation

struct PlaceSheet: View {
    let place: Place
    @Bindable var store: SavedPlacesStore
    @Bindable var directionsModel: DirectionsModel
    let location: LocationService
    @Binding var detent: PresentationDetent
    var opensDirections = false
    @State private var lastEstimateFix: LocationFix?
    @State private var showError = false
    @State private var showingDirections = false
    @State private var showingNavigation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(place.name).font(.title2).bold().lineLimit(2)
                    if !place.address.isEmpty {
                        Text(place.address).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                    }
                    Picker("Travel mode", selection: $directionsModel.mode) {
                        ForEach(TravelMode.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.segmented)
                    HStack {
                        Button {
                            showingNavigation = true
                        } label: {
                            Label(goLabel, systemImage: "location.north.fill")
                                .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("place.go")
                        Button(store.contains(place) ? "Saved" : "Save",
                               systemImage: store.contains(place) ? "bookmark.fill" : "bookmark", action: save)
                            .buttonStyle(.bordered).frame(minHeight: 44)
                            .accessibilityIdentifier("place.save")
                    }
                    Button("Route details", systemImage: "list.bullet") {
                        detent = .medium
                        showingDirections = true
                    }
                    .accessibilityIdentifier("place.directions")
                    if detent != .height(320) {
                        Divider()
                        Text(place.coordinateLabel).font(.subheadline).foregroundStyle(.secondary).textSelection(.enabled)
                        ShareLink(item: place.shareURL, subject: Text(place.name), message: Text(place.name)) {
                            Label("Share place", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal).padding(.bottom)
            }
            .navigationDestination(isPresented: $showingDirections) {
                DirectionsView(destination: place, store: store, model: directionsModel)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .alert("Couldn’t save", isPresented: $showError) {
                Button("OK", role: .cancel) { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "Please try again.") }
        }
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $showingNavigation) {
            NavigationScreen(destination: place, mode: directionsModel.mode)
        }
        .task(id: place.id) {
            lastEstimateFix = nil
            if opensDirections {
                showingDirections = true
                return
            }
            directionsModel.clear()
            // Estimates are optional: Go is available without waiting for a preview or permission prompt.
            if let fix = location.fix, abs(fix.timestamp.timeIntervalSinceNow) < 120 {
                estimate(from: fix)
            } else { location.locateIfAuthorized() }
        }
        .onChange(of: location.fix) { _, fix in
            if let fix, !showingDirections, !showingNavigation { estimate(from: fix) }
        }
        .onChange(of: directionsModel.mode) {
            if !showingDirections, let fix = location.fix, abs(fix.timestamp.timeIntervalSinceNow) < 120 { estimate(from: fix, force: true) }
        }
    }
    private var goLabel: String {
        if let route = directionsModel.route, directionsModel.origin?.id == "current-location" {
            return "Go · \(max(1, Int(ceil(route.seconds / 60)))) min"
        }
        return "Go"
    }
    private func estimate(from fix: LocationFix, force: Bool = false) {
        if !force, let previous = lastEstimateFix {
            let distance = CLLocation(latitude: fix.latitude, longitude: fix.longitude)
                .distance(from: CLLocation(latitude: previous.latitude, longitude: previous.longitude))
            guard fix.timestamp.timeIntervalSince(previous.timestamp) >= 60, distance >= 100 else { return }
        }
        lastEstimateFix = fix
        directionsModel.origin = Place(id: "current-location", name: "My location", address: "", latitude: fix.latitude, longitude: fix.longitude)
        directionsModel.calculate(to: place)
    }
    private func save() { store.toggle(place); showError = store.errorMessage != nil }
}
