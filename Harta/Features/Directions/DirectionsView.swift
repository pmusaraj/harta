import SwiftUI

struct DirectionsView: View {
    let destination: Place
    let store: SavedPlacesStore
    @Bindable var model: DirectionsModel
    @State private var location = LocationService()
    @State private var search = SearchModel()
    @State private var showSearch = false
    @State private var showNavigation = false
    @State private var hasStarted = false
    @State private var locationError: String?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        List {
            Section {
                Menu {
                    Button("My location", systemImage: "location", action: locate)
                    Button("Search starting point", systemImage: "magnifyingglass") { showSearch = true }
                } label: {
                    LabeledContent("From", value: model.origin?.name ?? "My location")
                }
                .accessibilityIdentifier("directions.origin")
                LabeledContent("To", value: destination.name)
                Picker("Travel mode", selection: $model.mode) {
                    ForEach(TravelMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("directions.mode")
            }
            if location.isLocating {
                HStack { ProgressView(); Text("Finding your location…") }
            } else if let locationError {
                Section {
                    Text(locationError)
                    Button("Try location again", action: locate)
                    Button("Search starting point") { showSearch = true }
                }
            }
            if model.isLoading {
                HStack { ProgressView(); Text("Finding a route…") }
            } else if let error = model.errorMessage {
                Section {
                    Text(error)
                    Button("Try again") { model.calculate(to: destination) }
                }
            } else if let route = model.route {
                Section {
                    Button { model.select(nil) } label: {
                        Label(route.summary, systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                            .font(.headline)
                    }
                    .accessibilityIdentifier("directions.summary")
                    Button("Start navigation", systemImage: "location.north.fill") { showNavigation = true }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("directions.start")
                    Text("Navigation starts from your current location. No live traffic updates.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Directions") {
                    ForEach(route.steps) { step in
                        Button { model.select(step) } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.instruction)
                                if step.kilometers > 0 {
                                    Text("\(Int((step.kilometers * 1000).rounded())) m")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(model.selectedStep?.id == step.id ? .teal : .primary)
                        }
                        .accessibilityIdentifier("directions.step.\(step.id)")
                    }
                }
            }
            Section {
                Link("Routing by Valhalla · FOSSGIS · OpenStreetMap", destination: AppConfiguration.routingCredit)
                    .font(.footnote)
            }
        }
        .navigationTitle("Directions")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !hasStarted else { return }
            hasStarted = true
            if model.origin == nil { locate() } else if model.route == nil { model.calculate(to: destination) }
        }
        .onChange(of: model.mode) { model.calculate(to: destination) }
        .onChange(of: location.fix) { _, fix in
            guard let fix else { return }
            model.origin = Place(id: "current-location", name: "My location", address: "",
                                 latitude: fix.latitude, longitude: fix.longitude)
            model.calculate(to: destination)
        }
        .onChange(of: location.errorMessage) { _, error in locationError = error }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { location.stop() }
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet(model: search, store: store, latitude: destination.latitude, longitude: destination.longitude) { place in
                location.stop(); locationError = nil
                model.origin = place
                model.calculate(to: destination)
                showSearch = false
            }
        }
        .fullScreenCover(isPresented: $showNavigation) {
            NavigationScreen(destination: destination, mode: model.mode)
        }
        .onDisappear { location.stop() }
    }
    private func locate() {
        model.clear(); model.origin = nil; locationError = nil
        location.errorMessage = nil; location.locate()
    }
}
