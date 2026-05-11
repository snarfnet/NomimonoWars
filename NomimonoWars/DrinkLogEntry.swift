import Foundation

struct DrinkLogEntry: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: DrinkCategory
    var rating: Int
    var note: String
    var date: Date

    init(id: UUID = UUID(), name: String, category: DrinkCategory, rating: Int = 3, note: String = "", date: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.rating = rating
        self.note = note
        self.date = date
    }

    var dateLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d (E)"
        return f.string(from: date)
    }

    var timeLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

enum DrinkCategory: String, Codable, CaseIterable, Identifiable {
    case coffee = "コーヒー"
    case tea = "お茶"
    case juice = "ジュース"
    case carbonated = "炭酸"
    case water = "水"
    case energy = "エナジー"
    case alcohol = "お酒"
    case other = "その他"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .coffee: return "cup.and.saucer.fill"
        case .tea: return "leaf.fill"
        case .juice: return "carrot.fill"
        case .carbonated: return "bubbles.and.sparkles.fill"
        case .water: return "drop.fill"
        case .energy: return "bolt.fill"
        case .alcohol: return "wineglass.fill"
        case .other: return "mug.fill"
        }
    }

    var color: String {
        switch self {
        case .coffee: return "brown"
        case .tea: return "green"
        case .juice: return "orange"
        case .carbonated: return "cyan"
        case .water: return "blue"
        case .energy: return "yellow"
        case .alcohol: return "purple"
        case .other: return "gray"
        }
    }
}
