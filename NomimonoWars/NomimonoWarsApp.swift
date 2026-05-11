import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct NomimonoWarsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    try? await Task.sleep(for: .seconds(1))
                    ATTrackingManager.requestTrackingAuthorization { _ in
                        DispatchQueue.main.async {
                            GADMobileAds.sharedInstance().start(completionHandler: nil)
                        }
                    }
                }
        }
    }
}
