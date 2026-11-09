import SwiftUI

@main
struct HartaApp: App {
    @UIApplicationDelegateAdaptor(SharingAppDelegate.self) private var sharingDelegate
    var body: some Scene {
        WindowGroup {
            MapScreen()
                .tint(.teal)
        }
    }
}
