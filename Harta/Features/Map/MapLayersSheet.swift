import SwiftUI

struct MapLayersSheet: View {
    @AppStorage(MapOverlay.preferenceKey) private var selection = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(MapOverlay.allCases) { overlay in
                        MapLayerToggle(overlay: overlay)
                    }
                } footer: {
                    Text("Layers work with every map style. Zoom in to see places and paths. Coverage varies by area; missing markers don’t mean no places exist.")
                }
                Button("Turn off all layers") { selection = 0 }
                    .disabled(MapOverlay.enabledCount(in: selection) == 0)
            }
            .navigationTitle("Map layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
