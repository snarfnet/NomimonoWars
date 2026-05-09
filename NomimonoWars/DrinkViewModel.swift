import SwiftUI

enum DrinkTab: String, CaseIterable {
    case newRelease = "新商品"
    case ranking = "ランキング"
    case news = "ニュース"

    var icon: String {
        switch self {
        case .newRelease: return "sparkles"
        case .ranking: return "chart.bar.fill"
        case .news: return "newspaper.fill"
        }
    }

    var rssURLs: [String] {
        switch self {
        case .newRelease:
            return [
                "https://news.google.com/rss/search?q=%E6%96%B0%E5%95%86%E5%93%81+%E9%A3%B2%E6%96%99&hl=ja&gl=JP&ceid=JP:ja",
                "https://news.google.com/rss/search?q=%E6%96%B0%E7%99%BA%E5%A3%B2+%E3%83%89%E3%83%AA%E3%83%B3%E3%82%AF&hl=ja&gl=JP&ceid=JP:ja"
            ]
        case .ranking:
            return [
                "https://news.google.com/rss/search?q=%E9%A3%B2%E6%96%99+%E3%83%A9%E3%83%B3%E3%82%AD%E3%83%B3%E3%82%B0&hl=ja&gl=JP&ceid=JP:ja",
                "https://news.google.com/rss/search?q=%E3%83%89%E3%83%AA%E3%83%B3%E3%82%AF+%E5%A3%B2%E3%82%8C%E7%AD%8B&hl=ja&gl=JP&ceid=JP:ja"
            ]
        case .news:
            return [
                "https://news.google.com/rss/search?q=%E9%A3%B2%E6%96%99+%E3%83%8B%E3%83%A5%E3%83%BC%E3%82%B9&hl=ja&gl=JP&ceid=JP:ja",
                "https://news.google.com/rss/search?q=%E3%83%9A%E3%83%83%E3%83%88%E3%83%9C%E3%83%88%E3%83%AB+%E7%BC%B6+%E6%96%B0%E4%BD%9C&hl=ja&gl=JP&ceid=JP:ja"
            ]
        }
    }
}

@MainActor
class DrinkViewModel: ObservableObject {
    @Published var sections: [DrinkSection] = []
    @Published var isLoading = false
    @Published var currentTab: DrinkTab = .newRelease

    private var cache: [DrinkTab: [DrinkItem]] = [:]

    func fetch() async {
        isLoading = true

        if let cached = cache[currentTab], !cached.isEmpty {
            updateSections(from: cached)
            isLoading = false
            return
        }

        var allItems: [DrinkItem] = []

        await withTaskGroup(of: [DrinkItem].self) { group in
            for urlString in currentTab.rssURLs {
                group.addTask { await self.fetchRSS(urlString: urlString) }
            }
            for await items in group {
                allItems.append(contentsOf: items)
            }
        }

        allItems.sort { $0.publishedDate > $1.publishedDate }

        var seen = Set<String>()
        allItems = allItems.filter { seen.insert($0.title).inserted }
        allItems = Array(allItems.prefix(80))

        cache[currentTab] = allItems
        updateSections(from: allItems)
        isLoading = false
    }

    func switchTab(_ tab: DrinkTab) async {
        currentTab = tab
        await fetch()
    }

    func refresh() async {
        cache[currentTab] = nil
        await fetch()
    }

    private func updateSections(from items: [DrinkItem]) {
        let grouped = Dictionary(grouping: items) { $0.dateLabel }
        sections = grouped.keys.sorted { a, b in
            let dateA = grouped[a]!.first!.publishedDate
            let dateB = grouped[b]!.first!.publishedDate
            return dateA > dateB
        }.map { date in
            DrinkSection(date: date, items: grouped[date]!.sorted { $0.publishedDate > $1.publishedDate })
        }
    }

    private func fetchRSS(urlString: String) async -> [DrinkItem] {
        guard let url = URL(string: urlString) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let parser = RSSParser()
            let xmlParser = XMLParser(data: data)
            xmlParser.delegate = parser
            xmlParser.parse()
            return parser.items
        } catch {
            return []
        }
    }
}
