import CloudKit
import SwiftUI

/// Apple's participant picker provides private invitations without exposing account lookup in Harta.
struct CloudSharingSheet: UIViewControllerRepresentable {
    let share: CKShare
    let family: FamilyMapStore

    func makeCoordinator() -> Coordinator { Coordinator(family: family) }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: family.container)
        controller.availablePermissions = [.allowPrivate, .allowReadOnly]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let family: FamilyMapStore
        init(family: FamilyMapStore) { self.family = family }
        func itemTitle(for controller: UICloudSharingController) -> String? { "Family map" }
        func cloudSharingController(_ controller: UICloudSharingController, failedToSaveShareWithError error: Error) {
            family.errorMessage = error.localizedDescription
        }
        func cloudSharingControllerDidStopSharing(_ controller: UICloudSharingController) {
            family.sharingStopped()
        }
        func cloudSharingControllerDidSaveShare(_ controller: UICloudSharingController) {
            Task { await family.refresh() }
        }
    }
}
