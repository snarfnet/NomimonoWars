import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
        guard uiView.rootViewController == nil else { return }
        if let windowScene = uiView.window?.windowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            uiView.rootViewController = rootVC
            uiView.load(GADRequest())
        }
    }
}
