import SwiftUI
#if !SCREENSHOT_MODE
import GoogleMobileAds
import AppTrackingTransparency
#endif

#if !SCREENSHOT_MODE
@MainActor
final class AdMobStartup: ObservableObject {
    static let shared = AdMobStartup()
    @Published private(set) var isReady = false
    private var didRequest = false

    func requestTrackingAndStart() {
        guard !isReady, !didRequest else { return }
        didRequest = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            _ = await ATTrackingManager.requestTrackingAuthorization()
            await MobileAds.shared.start()
            isReady = true
        }
    }
}
#endif

@main
struct NomimonoWarsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
