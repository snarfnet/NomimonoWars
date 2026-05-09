import Foundation

struct DrinkItem: Identifiable, Codable {
    let id: String
    let title: String
    let link: String
    let source: String
    let publishedDate: Date
    var isBookmarked: Bool = false

    var url: URL? { URL(string: link) }

    var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: publishedDate)
    }

    var timeLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: publishedDate, relativeTo: Date())
    }

    enum CodingKeys: String, CodingKey {
        case id, title, link, source, publishedDate, isBookmarked
    }
}

struct DrinkSection {
    let date: String
    let items: [DrinkItem]
}
