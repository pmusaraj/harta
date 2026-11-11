import SwiftUI

struct FamilyMapSettings: View {
    @Bindable var family: FamilyMapStore

    var body: some View {
        Section {
            if family.joined != nil {
                Toggle("Show shared map", isOn: $family.showingFamily)
                Text(family.family.isReadOnly
                     ? "This map is view-only. Switch it off to use your personal saved places."
                     : "You can edit this shared map. Changes sync to everyone with access. Switch it off to use your personal saved places.")
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
            Text("Shared map")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                if CloudKitEnvironment.current == .development {
                    Text("For sharing tests, use the TestFlight build on both devices. This build uses separate iCloud data and invitations.")
                }
                Text("Sharing uploads all your personal saved places to iCloud. Invite anyone with an iCloud account and choose whether they can view or edit. Editors can add, change, and remove places for everyone. Existing invitations remain view-only until you grant editing access. Maps sync while Harta is open; downloaded places are available offline. Recent searches and live location are not shared.")
            }
        }
    }
}
