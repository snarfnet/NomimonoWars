#if SCREENSHOT_MODE
import Foundation

@MainActor
class InterstitialAdManager: NSObject, ObservableObject {
    func countTap() {}
    func loadAd() {}
}
#else
import GoogleMobileAds

@MainActor
class InterstitialAdManager: NSObject, ObservableObject {
    private var interstitial: InterstitialAd?
    private var tapCount = 0
    private let showEvery = 5

    func countTap() {
        tapCount += 1
        if tapCount >= showEvery {
            tapCount = 0
            showAd()
        }
    }

    func loadAd() {
        InterstitialAd.load(
            with: "ca-app-pub-9404799280370656/9605394446",
            request: Request()
        ) { [weak self] ad, error in
            if let error {
                print("Interstitial load error: \(error.localizedDescription)")
                return
            }
            self?.interstitial = ad
        }
    }

    private func showAd() {
        guard let interstitial,
              let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = windowScene.keyWindow?.rootViewController else {
            loadAd()
            return
        }
        interstitial.present(from: rootVC)
        loadAd()
    }
}
#endif
