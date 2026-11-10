import SwiftUI

struct FamilyMapSettings: View {
    @Bindable var family: FamilyMapStore

    var body: some View {
        Section {
            if family.joined != nil {
                Toggle("Show family map", isOn: $family.showingFamily)
                Text("You can view this family map. Switch it off to use your personal saved places.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Manage membership") { Task { await family.manageJoinedMap() } }
            }
            Button(family.enabled ? "Manage my map’s sharing" : "Share my saved places") {
                Task { await family.sharePersonalMap() }
            }
            .disabled(family.busy)
            if family.enabled || family.joined != nil {
                Button("Sync now", systemImage: "arrow.triangle.2.circlepath") {
                    Task { await family.refresh() }
                }
                .disabled(family.busy)
                if family.busy {
                    ProgressView("Syncing…")
                } else if !family.status.isEmpty {
                    Text(family.status).foregroundStyle(.secondary)
                }
                if let date = family.lastSynced {
                    Text("Last synced \(date.formatted(date: .omitted, time: .shortened))")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            if let error = family.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Family map")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                if CloudKitEnvironment.current == .development {
                    Text("For sharing tests, use the TestFlight build on both devices. This build uses separate iCloud data and invitations.")
                }
                Text("Sharing uploads all your personal saved places to iCloud. Invited members can view them, including later changes. Everyone needs an iCloud account. Maps sync while Harta is open; downloaded places are available offline. Recent searches and live location are not shared.")
            }
        }
    }
}
