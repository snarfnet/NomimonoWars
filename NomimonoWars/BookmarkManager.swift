import SwiftUI

@MainActor
class BookmarkManager: ObservableObject {
    @Published var bookmarks: [DrinkItem] = []

    private let key = "nomimonowars_bookmarks"

    init() {
        load()
    }

    func isBookmarked(_ item: DrinkItem) -> Bool {
        bookmarks.contains { $0.id == item.id }
    }

    func toggle(_ item: DrinkItem) {
        if let idx = bookmarks.firstIndex(where: { $0.id == item.id }) {
            bookmarks.remove(at: idx)
        } else {
            bookmarks.insert(item, at: 0)
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([DrinkItem].self, from: data) else { return }
        bookmarks = saved
    }
}
