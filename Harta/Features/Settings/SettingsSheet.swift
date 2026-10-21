import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(MapStyle.preferenceKey) private var mapStyle: MapStyle = .everyday

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(MapStyle.allCases) { style in
                        Button {
                            mapStyle = style
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(style.title).font(.headline)
                                    Text(style.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: mapStyle == style ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(mapStyle == style ? Color.teal : Color.secondary)
                                    .font(.title3)
                                    .accessibilityHidden(true)
                            }
                            .padding(.vertical, 4)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settings.style.\(style.rawValue)")
                        .accessibilityValue(mapStyle == style ? "Selected" : "Not selected")
                        .accessibilityAddTraits(mapStyle == style ? .isSelected : [])
                    }
                } header: {
                    Text("Map style")
                } footer: {
                    Text("Applies to browsing and navigation. Colors follow your device’s appearance.")
                }
                Section("Privacy") {
                    Text("Voice search records only while you ask a question. Speech recognition and command extraction run on this device; audio and transcripts are not saved. Speech language support may need an initial download. Unmatched destination searches go to Photon, and route requests use the routing service.")
                    Text("Saved places stay on this device. Location updates while the app is active and pauses in the background. During navigation, precise location updates continue while the phone is locked. Ending navigation stops background tracking.")
                    Text("Map requests go to OpenFreeMap. Submitted searches go to Photon. Searches prefer your current location when available; an explicit map-area search uses the map center. Searches for a named locality omit the location bias. Routing sends your starting point, destination, and travel mode to the FOSSGIS Valhalla service. Navigation rerouting sends your updated position. These providers receive your IP address.")
                }
                Section("Map credits") {
                    Link("© OpenStreetMap contributors · ODbL", destination: AppConfiguration.osmCredit)
                    Link("© OpenMapTiles", destination: AppConfiguration.tilesCredit)
                    Link("OpenFreeMap", destination: AppConfiguration.mapsCredit)
                    Text("Map styles adapted from OpenFreeMap’s Positron and Dark Matter styles, by OpenMapTiles / MapTiler, derived from CartoDB basemaps by Stamen and Paul Norman. Harta adjusts colors, labels, and map detail.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Link("Map style design · CC BY 4.0", destination: AppConfiguration.url("https://creativecommons.org/licenses/by/4.0/"))
                    NavigationLink("Map style licenses") { MapStyleLicensesView() }
                    Link("MapLibre Native · BSD 2-Clause", destination: AppConfiguration.mapLibreCredit)
                    Link("Photon search", destination: AppConfiguration.searchCredit)
                    Link("Valhalla routing · FOSSGIS", destination: AppConfiguration.routingCredit)
                    Link("Ferrostar navigation · BSD 3-Clause", destination: AppConfiguration.url("https://github.com/stadiamaps/ferrostar"))
                }
                Section {
                    Text("Maps and search need an internet connection. Public map and search services may be temporarily unavailable.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done", action: close) } }
        }
    }

    private func close() { dismiss() }
}
