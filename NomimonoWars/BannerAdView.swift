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
        banner.load(GADRequest())
        context.coordinator.loadedAdSize = "\(Int(adSize.size.width))x\(Int(adSize.size.height))"
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
        if !GADAdSizeEqualToSize(uiView.adSize, adSize) {
            uiView.adSize = adSize
            let sizeKey = "\(Int(adSize.size.width))x\(Int(adSize.size.height))"
            context.coordinator.loadedAdSize = sizeKey
            uiView.load(GADRequest())
        }
    }

    final class Coordinator {
        var loadedAdSize: String?
    }
}
#endif
