import SwiftUI
#if !SCREENSHOT_MODE
import GoogleMobileAds
import AppTrackingTransparency
#endif

@main
struct NomimonoWarsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var attRequested = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) {
                    #if !SCREENSHOT_MODE
                    if scenePhase == .active && !attRequested {
                        attRequested = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            ATTrackingManager.requestTrackingAuthorization { _ in
                                DispatchQueue.main.async {
                                    MobileAds.shared.start()
                                }
                            }
                        }
                    }
                    #endif
                }
        }
    }
}
