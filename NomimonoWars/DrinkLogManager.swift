import SwiftUI

@MainActor
class DrinkLogManager: ObservableObject {
    @Published var entries: [DrinkLogEntry] = []

    private let key = "nomimonowars_drinklog"

    init() { load() }

    func add(_ entry: DrinkLogEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func todayCount() -> Int {
        let cal = Calendar.current
        return entries.filter { cal.isDateInToday($0.date) }.count
    }

    func weekEntries() -> [DrinkLogEntry] {
        let cal = Calendar.current
        let weekAgo = cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.date >= weekAgo }
    }

    func categoryBreakdown() -> [(DrinkCategory, Int)] {
        let week = weekEntries()
        var counts: [DrinkCategory: Int] = [:]
        for e in week { counts[e.category, default: 0] += 1 }
        return counts.sorted { $0.value > $1.value }
    }

    func dailyCounts(days: Int = 7) -> [(String, Int)] {
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "E"

        var result: [(String, Int)] = []
        for i in (0..<days).reversed() {
            let day = cal.date(byAdding: .day, value: -i, to: Date())!
            let count = entries.filter { cal.isDate($0.date, inSameDayAs: day) }.count
            result.append((f.string(from: day), count))
        }
        return result
    }

    func averageRating() -> Double {
        let week = weekEntries()
        guard !week.isEmpty else { return 0 }
        return Double(week.reduce(0) { $0 + $1.rating }) / Double(week.count)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([DrinkLogEntry].self, from: data) else { return }
        entries = saved
    }
}
