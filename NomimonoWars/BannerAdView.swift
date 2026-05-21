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
    @ObservedObject private var startup = AdMobStartup.shared

    var body: some View {
        GeometryReader { proxy in
            if startup.isReady, proxy.size.width > 0 {
                let width = min(max(proxy.size.width, 320), maxWidth)
                let adSize = largeAnchoredAdaptiveBanner(width: width)

                BannerAdContainer(adUnitID: adUnitID, adSize: adSize)
                    .frame(width: adSize.size.width, height: adSize.size.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(height: startup.isReady ? 90 : 0)
        .task { startup.requestTrackingAndStart() }
    }
}

private struct BannerAdContainer: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.backgroundColor = .clear
        banner.load(Request())
        context.coordinator.loadedAdSize = "\(Int(adSize.size.width))x\(Int(adSize.size.height))"
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        if !isAdSizeEqualToSize(size1: uiView.adSize, size2: adSize) {
            uiView.adSize = adSize
            let sizeKey = "\(Int(adSize.size.width))x\(Int(adSize.size.height))"
            context.coordinator.loadedAdSize = sizeKey
            uiView.load(Request())
        }
    }

    final class Coordinator {
        var loadedAdSize: String?
    }
}
#endif
