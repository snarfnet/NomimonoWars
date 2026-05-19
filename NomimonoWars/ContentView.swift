import SwiftUI
import SafariServices

private let kBannerAdID = "ca-app-pub-9404799280370656/4115440217"

struct ContentView: View {
    @StateObject private var vm = DrinkViewModel()
    @StateObject private var bookmarkManager = BookmarkManager()
    @StateObject private var interstitialManager = InterstitialAdManager()
    @StateObject private var logManager = DrinkLogManager()
    @State private var selectedMainTab: MainTab = .newRelease

    @Environment(\.horizontalSizeClass) private var sizeClass

    enum MainTab: CaseIterable {
        case newRelease, ranking, news, log, stats, bookmarks

        var title: String {
            switch self {
            case .newRelease: return "新商品"
            case .ranking: return "ランキング"
            case .news: return "ニュース"
            case .log: return "飲みログ"
            case .stats: return "統計"
            case .bookmarks: return "保存"
            }
        }

        var icon: String {
            switch self {
            case .newRelease: return "sparkles"
            case .ranking: return "chart.bar.fill"
            case .news: return "newspaper.fill"
            case .log: return "cup.and.saucer.fill"
            case .stats: return "chart.pie.fill"
            case .bookmarks: return "bookmark.fill"
            }
        }

        var drinkTab: DrinkTab? {
            switch self {
            case .newRelease: return .newRelease
            case .ranking: return .ranking
            case .news: return .news
            default: return nil
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            NavigationStack {
                ZStack {
                    Palette.bg.ignoresSafeArea()
                    GeneratedBackground()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)

                    Group {
                        switch selectedMainTab {
                        case .newRelease, .ranking, .news:
                            drinkView
                        case .log: DrinkLogView(logManager: logManager)
                        case .stats: StatsView(logManager: logManager)
                        case .bookmarks: bookmarkView
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Palette.bg.opacity(0.92), for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Palette.lime)
                                    .frame(width: 23, height: 23)
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(Palette.ink)
                            }
                            Text("飲み物ウォーズ")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(Palette.text)
                        }
                    }
                }
            }

            mainTabBar

            AdaptiveBannerAdView(adUnitID: kBannerAdID, maxWidth: UIScreen.main.bounds.width)
                .frame(height: 50)
                .background(Palette.ink)
        }
        .task {
            interstitialManager.loadAd()
            if let drinkTab = selectedMainTab.drinkTab {
                await vm.switchTab(drinkTab)
            } else {
                await vm.fetch()
            }
        }
    }

    // MARK: - Drink View

    @ViewBuilder
    private var drinkView: some View {
        VStack(spacing: 0) {
            hero
            drinkContent
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("DRINK RADAR")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(Palette.lime)
                    Text(heroTitle)
                        .font(.system(size: sizeClass == .regular ? 28 : 32, weight: .black, design: .rounded))
                        .foregroundStyle(Palette.text)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                }
                Spacer(minLength: 12)
                fizzBadge
            }

            HStack(spacing: 8) {
                statusPill(icon: "flame.fill", text: "新着 \(itemCount)本")
                statusPill(icon: "arrow.clockwise", text: vm.isLoading ? "更新中" : "更新済み")
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 16)
    }

    private var heroTitle: String {
        switch selectedMainTab {
        case .newRelease: return "新作ドリンクを迎撃"
        case .ranking: return "売れ筋の気配を追跡"
        case .news: return "飲料ニュースを即チェック"
        default: return ""
        }
    }

    private var itemCount: Int {
        vm.sections.reduce(0) { $0 + $1.items.count }
    }

    private var fizzBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Palette.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Palette.line, lineWidth: 1)
                )
                .shadow(color: Palette.cyan.opacity(0.18), radius: 18, y: 8)
            VStack(spacing: 4) {
                Image(systemName: "drop.degreesign.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Palette.cyan)
                Text("HOT")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.text)
            }
        }
        .frame(width: 70, height: 70)
    }

    private func statusPill(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(Palette.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Palette.panelSoft)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var drinkContent: some View {
        if vm.isLoading && vm.sections.isEmpty {
            loadingState
        } else if vm.sections.isEmpty {
            emptyState(
                icon: "cup.and.saucer.fill",
                title: "記事が見つかりません",
                subtitle: "通信状況を確認して、もう一度読み込んでください。",
                buttonTitle: "再読み込み"
            ) {
                Task { await vm.refresh() }
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(vm.sections, id: \.date) { section in
                        sectionHeader(section.date)
                        ForEach(section.items) { item in
                            DrinkCard(
                                item: item,
                                bookmarkManager: bookmarkManager,
                                interstitialManager: interstitialManager
                            )
                            .padding(.horizontal, 14)
                            .padding(.bottom, 12)
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 14)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await vm.refresh()
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Palette.lime)
                .scaleEffect(1.18)
            Text("最新の飲み物情報を読み込み中")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.sub)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sectionHeader(_ date: String) -> some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Palette.lime)
                .frame(width: 20, height: 3)
                .clipShape(Capsule())
            Text(date)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(Palette.text)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    // MARK: - Bookmark View

    @ViewBuilder
    private var bookmarkView: some View {
        if bookmarkManager.bookmarks.isEmpty {
            emptyState(
                icon: "bookmark.slash.fill",
                title: "保存した記事はまだありません",
                subtitle: "気になる記事のブックマークを押すと、ここに集まります。",
                buttonTitle: nil,
                action: nil
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    sectionHeader("保存した記事")
                    ForEach(bookmarkManager.bookmarks) { item in
                        DrinkCard(
                            item: item,
                            bookmarkManager: bookmarkManager,
                            interstitialManager: interstitialManager
                        )
                        .padding(.horizontal, 14)
                    }
                }
                .padding(.vertical, 14)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func emptyState(
        icon: String,
        title: String,
        subtitle: String,
        buttonTitle: String?,
        action: (() -> Void)?
    ) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Palette.panel)
                    .frame(width: 86, height: 86)
                Image(systemName: icon)
                    .font(.system(size: 35, weight: .bold))
                    .foregroundStyle(Palette.cyan)
            }
            Text(title)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(Palette.lime)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    // MARK: - Main Tab Bar

    private var mainTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    mainTabButton(tab: tab)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 9)
        .background(
            Palette.bg
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Palette.line)
                        .frame(height: 1)
                }
        )
    }

    private func mainTabButton(tab: MainTab) -> some View {
        Button {
            selectedMainTab = tab
            if let drinkTab = tab.drinkTab {
                Task { await vm.switchTab(drinkTab) }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .bold))
                Text(tab.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(selectedMainTab == tab ? Palette.lime : Palette.sub)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Drink Card

private struct DrinkCard: View {
    let item: DrinkItem
    @ObservedObject var bookmarkManager: BookmarkManager
    @ObservedObject var interstitialManager: InterstitialAdManager
    @State private var showSafari = false

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 8) {
                Text(item.source)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Palette.cyan)
                    .clipShape(Capsule())
                Spacer(minLength: 8)
                Text(item.timeLabel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.sub)
            }

            Text(item.title)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(Palette.text)
                .lineLimit(3)
                .lineSpacing(4)

            HStack(spacing: 10) {
                Label("読む", systemImage: "safari.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.sub)

                Spacer()

                Button {
                    bookmarkManager.toggle(item)
                } label: {
                    Image(systemName: bookmarkManager.isBookmarked(item) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(bookmarkManager.isBookmarked(item) ? Palette.lime : Palette.sub)
                        .frame(width: 38, height: 34)
                        .background(Palette.panelSoft)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 34, height: 34)
                    .background(Palette.lime)
                    .clipShape(Circle())
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Palette.line, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
        .contentShape(Rectangle())
        .onTapGesture {
            interstitialManager.countTap()
            showSafari = true
        }
        .sheet(isPresented: $showSafari) {
            if let url = item.url {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Background

private struct GeneratedBackground: View {
    var body: some View {
        ZStack {
            Image("GeneratedDrinkBackground")
                .resizable()
                .scaledToFill()
            Palette.bg.opacity(0.66)
            LinearGradient(
                colors: [Color.black.opacity(0.24), Color.black.opacity(0.56), Color.black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Safari

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}

// MARK: - Colors

enum Palette {
    static let bg = Color(red: 0.03, green: 0.05, blue: 0.06)
    static let ink = Color(red: 0.02, green: 0.03, blue: 0.03)
    static let card = Color(red: 0.10, green: 0.13, blue: 0.14).opacity(0.94)
    static let panel = Color(red: 0.12, green: 0.16, blue: 0.17).opacity(0.90)
    static let panelSoft = Color.white.opacity(0.07)
    static let text = Color(red: 0.94, green: 0.97, blue: 0.94)
    static let sub = Color(red: 0.62, green: 0.70, blue: 0.69)
    static let lime = Color(red: 0.74, green: 0.96, blue: 0.20)
    static let cyan = Color(red: 0.24, green: 0.88, blue: 0.93)
    static let line = Color.white.opacity(0.10)
}
