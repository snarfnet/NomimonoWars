import SwiftUI

struct StatsView: View {
    @ObservedObject var logManager: DrinkLogManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegularWidth: Bool { sizeClass == .regular }

    var body: some View {
        VStack(spacing: 0) {
            statsHeader
            if logManager.entries.isEmpty {
                emptyStatsState
            } else {
                statsContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text("WEEKLY STATS")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(Palette.lime)
                Text("飲み物レポート")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            HStack(spacing: 8) {
                Label("今週 \(logManager.weekEntries().count)杯", systemImage: "chart.bar.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Palette.panelSoft)
                    .clipShape(Capsule())
                let avg = logManager.averageRating()
                if avg > 0 {
                    Label(String(format: "満足度 %.1f", avg), systemImage: "star.fill")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Palette.panelSoft)
                        .clipShape(Capsule())
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var statsContent: some View {
        ScrollView {
            if isRegularWidth {
                VStack(spacing: 14) {
                    weeklyChart
                    HStack(alignment: .top, spacing: 14) {
                        categoryBreakdown
                        topDrinks
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 14)
            } else {
                VStack(spacing: 14) {
                    weeklyChart
                    categoryBreakdown
                    topDrinks
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Weekly Bar Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("日別グラフ")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(Palette.text)

            let data = logManager.dailyCounts()
            let maxVal = max(data.map(\.1).max() ?? 1, 1)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 6) {
                        Text("\(item.1)")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(Palette.text)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(item.1 > 0 ? Palette.lime : Palette.panelSoft)
                            .frame(height: max(CGFloat(item.1) / CGFloat(maxVal) * 100, 8))

                        Text(item.0)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.sub)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Palette.line, lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ内訳")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(Palette.text)

            let breakdown = logManager.categoryBreakdown()
            let total = max(breakdown.reduce(0) { $0 + $1.1 }, 1)

            ForEach(breakdown, id: \.0) { cat, count in
                HStack(spacing: 10) {
                    Image(systemName: cat.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(categoryColor(cat))
                        .frame(width: 24)
                    Text(cat.rawValue)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.text)
                        .frame(width: 70, alignment: .leading)

                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(categoryColor(cat))
                            .frame(width: geo.size.width * CGFloat(count) / CGFloat(total))
                    }
                    .frame(height: 14)

                    Text("\(count)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(Palette.sub)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Palette.line, lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Top Drinks

    private var topDrinksData: [(key: String, value: Int)] {
        var counts: [String: Int] = [:]
        for n in logManager.weekEntries().map(\.name) { counts[n, default: 0] += 1 }
        return Array(counts.sorted { $0.value > $1.value }.prefix(5))
    }

    private var topDrinks: some View {
        let sorted = topDrinksData
        return VStack(alignment: .leading, spacing: 12) {
            Text("よく飲むもの")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(Palette.text)

            if sorted.isEmpty {
                Text("データなし")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.sub)
            } else {
                ForEach(Array(sorted.enumerated()), id: \.offset) { i, item in
                    HStack(spacing: 10) {
                        Text("#\(i + 1)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(i == 0 ? Palette.lime : Palette.sub)
                            .frame(width: 28)
                        Text(item.key)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.text)
                            .lineLimit(1)
                        Spacer()
                        Text("\(item.value)回")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.sub)
                    }
                    if i < sorted.count - 1 {
                        Divider().overlay(Palette.line)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Palette.line, lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func categoryColor(_ cat: DrinkCategory) -> Color {
        switch cat {
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

    private var emptyStatsState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Palette.panel)
                    .frame(width: 86, height: 86)
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 35, weight: .bold))
                    .foregroundStyle(Palette.cyan)
            }
            Text("統計データなし")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(Palette.text)
            Text("飲み物を記録すると、\nここに統計が表示されます。")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.sub)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
