#if SCREENSHOT_MODE
import SwiftUI
struct AdaptiveBannerAdView: View {
    let adUnitID: String
    let maxWidth: CGFloat
    var body: some View { EmptyView() }
}
#else
import SwiftUI
import UIKit
import GoogleMobileAds

struct AdaptiveBannerAdView: View {
    let adUnitID: String
    let maxWidth: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let width = min(max(proxy.size.width, 320), maxWidth)
            let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)

            BannerAdContainer(adUnitID: adUnitID, adSize: adSize)
                .frame(width: adSize.size.width, height: adSize.size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 90)
    }
}

private struct BannerAdContainer: UIViewRepresentable {
    let adUnitID: String
    let adSize: GADAdSize

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.backgroundColor = .clear
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
        if !GADAdSizeEqualToSize(uiView.adSize, adSize) {
            uiView.adSize = adSize
            context.coordinator.loadedAdSize = nil
        }

        guard let rootViewController = uiView.window?.rootViewController ?? UIApplication.shared.activeRootViewController else { return }

        uiView.rootViewController = rootViewController
        let sizeKey = "\(Int(adSize.size.width))x\(Int(adSize.size.height))"
        guard context.coordinator.loadedAdSize != sizeKey else { return }

        context.coordinator.loadedAdSize = sizeKey
        uiView.load(GADRequest())
    }

    final class Coordinator {
        var loadedAdSize: String?
    }
}

private extension UIApplication {
    var activeRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
#endif
