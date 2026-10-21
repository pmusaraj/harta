import SwiftUI

struct SearchPanel: View {
    @Bindable var model: SearchModel
    let store: SavedPlacesStore
    let recents: RecentPlacesStore
    let latitude: Double
    let longitude: Double
    let onSelect: (Place) -> Void
    let onClose: () -> Void
    var location: LocationService?
    var onDirections: ((Place, TravelMode?) -> Void)?
    @State private var voice = VoiceCommandModel()
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var focused: Bool
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Place or address", text: $model.query)
                    .focused($focused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("search.input")
                    .onSubmit(submit)
                if !model.query.isEmpty {
                    Button("Clear search", systemImage: "xmark.circle.fill") {
                        model.query = ""; focused = true
                    }.labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                }
                Button(voice.status == .listening ? "Stop listening" : "Voice search",
                       systemImage: voice.status == .listening ? "stop.circle.fill" : "mic.fill") {
                    if voice.status == .listening { voice.stop() } else { startVoice() }
                }
                .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                .disabled(voice.status != nil && voice.status != .listening)
                .accessibilityIdentifier("search.microphone")
                Button("Close search", systemImage: "xmark", action: onClose)
                    .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("search.close")
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let status = voice.status {
                        HStack {
                            if case .downloading(let progress) = status {
                                ProgressView(value: progress).frame(maxWidth: 80)
                            } else if status != .listening { ProgressView() }
                            Text(status.message)
                            Spacer()
                            Button("Cancel") { voice.cancel() }
                        }
                        .accessibilityIdentifier("search.voice.status")
                    }
                    if let error = voice.errorMessage {
                        Text(error).foregroundStyle(.secondary)
                            .accessibilityIdentifier("search.voice.error")
                        Button("Try voice again", action: startVoice)
                    }
                    if !voice.candidates.isEmpty {
                        Text("Which place?").font(.headline)
                        ForEach(voice.candidates) { row($0) }
                    }
                    if let error = store.errorMessage { Text(error).foregroundStyle(.red) }
                    if let message = model.locationMessage {
                        Text(message).font(.footnote).foregroundStyle(.secondary)
                    }
                    if model.isSearching {
                        HStack { ProgressView(); Text("Finding places…") }
                    }
                    if let error = model.errorMessage {
                        Text(error)
                        Button("Try again", action: retrySearch)
                        if model.needsLocation {
                            Button("Use map area") {
                                guard var request = model.request else { return }
                                request.area = .map
                                runSearch(request)
                            }
                            if let location {
                                Button("Update my location") { location.locate() }
                            }
                        }
                    }
                    if !model.results.isEmpty {
                        ForEach(model.results) { place in
                            row(place)
                            if place.id != model.results.last?.id { Divider() }
                        }
                    } else if model.hasSearched && !model.isSearching && model.errorMessage == nil {
                        Text("No places found. Try another name or address.").foregroundStyle(.secondary)
                    } else if !model.hasSearched && voice.status == nil && voice.errorMessage == nil && voice.candidates.isEmpty {
                        if !recents.places.isEmpty {
                            HStack {
                                Text("Recent").font(.subheadline.bold()).foregroundStyle(.secondary)
                                Spacer()
                                Button("Clear", action: recents.clear)
                                    .accessibilityLabel("Clear recent places")
                                    .frame(minHeight: 44)
                            }
                            ForEach(recents.places) { place in
                                row(place)
                                if place.id != recents.places.last?.id { Divider() }
                            }
                        }
                        if !store.places.isEmpty {
                            Text("Saved").font(.subheadline.bold()).foregroundStyle(.secondary)
                            ForEach(store.places) { place in
                                row(place)
                                if place.id != store.places.last?.id { Divider() }
                            }
                        }
                        if recents.places.isEmpty && store.places.isEmpty {
                            Text("Enter a place or address, then tap Search.").foregroundStyle(.secondary)
                        }
                    }
                    Text("Photon · OpenStreetMap").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .frame(height: min(contentHeight, 280))
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 24))
        .clipShape(.rect(cornerRadius: 24))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("search.panel")
        .onChange(of: model.query) { voice.cancel(); model.queryChanged() }
        .onChange(of: voice.selection) { _, selection in
            if let selection { select(selection.place, command: selection.command) }
        }
        .onChange(of: voice.status) { _, status in
            if let status, case .downloading = status { return }
            if let status { AccessibilityNotification.Announcement(status.message).post() }
        }
        .onChange(of: voice.errorMessage) { _, message in
            if let message { AccessibilityNotification.Announcement(message).post() }
        }
        .onChange(of: voice.candidates) { _, places in
            if !places.isEmpty { AccessibilityNotification.Announcement("Choose a saved place").post() }
        }
        .onChange(of: model.results) { _, places in
            if voice.command != nil { AccessibilityNotification.Announcement("\(places.count) places found").post() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { voice.cancel(); model.cancel() }
        }
        .task { recents.reload(); focused = true }
        .onDisappear { voice.cancel(); model.cancel() }
    }
    private func row(_ place: Place) -> some View {
        SearchPlaceRow(place: place, store: store) { selected in
            select(selected, command: voice.command)
        }
    }
    private func select(_ place: Place, command: VoiceCommand?) {
        recents.record(place)
        focused = false
        if command?.action == .directions, let onDirections {
            onDirections(place, command?.mode)
        } else { onSelect(place) }
    }

    private func startVoice() {
        focused = false
        voice.start(store: store, search: model, latitude: latitude, longitude: longitude,
                    currentLocation: { location?.fix })
    }

    private func submit() {
        focused = false
        voice.cancel()
        runSearch(PlaceSearchRequest(text: model.query))
    }

    private func runSearch(_ request: PlaceSearchRequest) {
        model.submit(request: request, latitude: latitude, longitude: longitude,
                     currentLocation: location?.fix, savedPlaces: store.places)
    }

    private func retrySearch() {
        focused = false
        if let request = model.request { runSearch(request) }
        else { submit() }
    }
}
