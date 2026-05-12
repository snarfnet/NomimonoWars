import SwiftUI

struct DrinkLogView: View {
    @ObservedObject var logManager: DrinkLogManager
    @State private var showAddSheet = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                logHeader
                if logManager.entries.isEmpty {
                    emptyLogState
                } else {
                    logList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !logManager.entries.isEmpty {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Palette.ink)
                        .frame(width: 56, height: 56)
                        .background(Palette.lime)
                        .clipShape(Circle())
                        .shadow(color: Palette.lime.opacity(0.4), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddDrinkView(logManager: logManager)
        }
    }

    private var logHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("DRINK LOG")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(Palette.lime)
                    Text("今日の飲み物を記録")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Palette.text)
                }
                Spacer(minLength: 12)
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(Palette.ink)
                        .frame(width: 48, height: 48)
                        .background(Palette.lime)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                todayPill
                ratingPill
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 16)
    }

    private var todayPill: some View {
        Label("今日 \(logManager.todayCount())杯", systemImage: "cup.and.saucer.fill")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(Palette.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Palette.panelSoft)
            .clipShape(Capsule())
    }

    private var ratingPill: some View {
        let avg = logManager.averageRating()
        return Label(avg > 0 ? String(format: "平均 %.1f", avg) : "---", systemImage: "star.fill")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(Palette.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Palette.panelSoft)
            .clipShape(Capsule())
    }

    private var logList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(logManager.entries) { entry in
                    DrinkLogCard(entry: entry)
                        .padding(.horizontal, 14)
                }
            }
            .padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
    }

    private var emptyLogState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Palette.panel)
                    .frame(width: 86, height: 86)
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 35, weight: .bold))
                    .foregroundStyle(Palette.cyan)
            }
            Text("まだ記録がありません")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(Palette.text)
            Text("右上の＋ボタンから\n今日飲んだものを記録しよう")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
            Button {
                showAddSheet = true
            } label: {
                Text("記録する")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(Palette.lime)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

// MARK: - Log Card

private struct DrinkLogCard: View {
    let entry: DrinkLogEntry

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(categoryColor.opacity(0.18))
                    .frame(width: 50, height: 50)
                Image(systemName: entry.category.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(categoryColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(entry.category.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(categoryColor)
                        .clipShape(Capsule())
                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Palette.sub)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= entry.rating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundStyle(i <= entry.rating ? Palette.lime : Palette.sub.opacity(0.4))
                    }
                }
                Text(entry.timeLabel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.sub)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Palette.line, lineWidth: 1)
                )
        )
    }

    private var categoryColor: Color {
        switch entry.category {
        case .coffee: return Color.brown
        case .tea: return Color.green
        case .juice: return Color.orange
        case .carbonated: return Palette.cyan
        case .water: return Color.blue
        case .energy: return Color.yellow
        case .alcohol: return Color.purple
        case .other: return Color.gray
        }
    }
}

// MARK: - Add Drink Sheet

struct AddDrinkView: View {
    @ObservedObject var logManager: DrinkLogManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: DrinkCategory = .coffee
    @State private var rating = 3
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        nameField
                        categoryPicker
                        ratingPicker
                        noteField
                    }
                    .padding(20)
                }
            }
            .navigationTitle("飲み物を記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.bg.opacity(0.92), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(Palette.sub)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let entry = DrinkLogEntry(name: name, category: category, rating: rating, note: note)
                        logManager.add(entry)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? Palette.sub : Palette.lime)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("名前")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.sub)
            TextField("例: ほうじ茶ラテ", text: $name)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.text)
                .padding(14)
                .background(Palette.panel)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("カテゴリ")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.sub)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                ForEach(DrinkCategory.allCases) { cat in
                    Button {
                        category = cat
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 18))
                            Text(cat.rawValue)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(category == cat ? Palette.ink : Palette.sub)
                        .background(category == cat ? Palette.lime : Palette.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var ratingPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("評価")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.sub)
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        rating = i
                    } label: {
                        Image(systemName: i <= rating ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundStyle(i <= rating ? Palette.lime : Palette.sub.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(14)
            .background(Palette.panel)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メモ")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.sub)
            TextField("感想など（任意）", text: $note)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.text)
                .padding(14)
                .background(Palette.panel)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
