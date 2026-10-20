import SwiftUI

struct NavigationScreen: View {
    @State private var model: NavigationModel
    @Environment(\.dismiss) private var dismiss
    init(destination: Place, mode: TravelMode) {
        _model = State(initialValue: NavigationModel(destination: destination, mode: mode))
    }
    var body: some View {
        MapCanvas(model: model.map, directions: model.directions, userCoordinate: model.coordinate,
                  isShowingPlace: false, onSelect: { _ in }, isNavigating: true,
                  onPan: { model.followsLocation = false })
            .ignoresSafeArea()
            .safeAreaInset(edge: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    if let distance = model.turnDistance, !model.arrived {
                        Text(distance).font(.title).bold().monospacedDigit()
                    }
                    HStack(spacing: 16) {
                        if !model.isPreparing { Image(systemName: model.maneuverSymbol).font(.largeTitle).foregroundStyle(.teal).accessibilityHidden(true) }
                        Text(model.instruction).font(.title2).bold()
                            .accessibilityIdentifier("navigation.instruction")
                    }
                    if model.rerouting { Label("Finding a new route…", systemImage: "arrow.triangle.turn.up.right.diamond") }
                    else if model.offRoute { Text("Off route — waiting for an updated route") }
                    if let message = model.gpsMessage ?? model.errorMessage {
                        Text(message).font(.callout)
                        Button("Retry", action: model.start).buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding().background(.regularMaterial, in: .rect(cornerRadius: 24)).padding()
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    if let remaining = model.remaining, !model.arrived { Text(remaining).font(.headline) }
                    Text(model.destination.name).lineLimit(2)
                    HStack {
                        Button(model.isMuted ? "Unmute" : "Mute", systemImage: model.isMuted ? "speaker.slash" : "speaker.wave.2", action: model.toggleMute)
                            .accessibilityIdentifier("navigation.mute")
                        Spacer()
                        Button("Recenter", systemImage: "location.fill", action: model.recenter)
                        Spacer()
                        Button(model.arrived ? "Done" : "End", role: .destructive, action: end)
                            .accessibilityIdentifier("navigation.end")
                    }
                    .buttonStyle(.bordered)
                    HStack {
                        Link("© OpenStreetMap", destination: AppConfiguration.osmCredit)
                        Link("© OpenMapTiles", destination: AppConfiguration.tilesCredit)
                    }.font(.caption2)
                }
                .padding().background(.regularMaterial, in: .rect(cornerRadius: 24)).padding()
            }
            .task { model.start() }
            .onDisappear { model.stop() }
            .interactiveDismissDisabled()
    }
    private func end() { model.stop(); dismiss() }
}
