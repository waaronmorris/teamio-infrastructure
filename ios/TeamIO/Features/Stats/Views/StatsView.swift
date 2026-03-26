import SwiftUI

struct StatType: Decodable, Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let display_name: String?
    let category: String?
    let is_higher_better: Bool?
}

struct LeaderboardEntry: Decodable, Identifiable, Sendable {
    let id: String
    let player_id: String
    let player_name: String?
    let team_name: String?
    let value: Double

    var formattedValue: String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}

@Observable
@MainActor
final class StatsViewModel {
    var seasons: [Season] = []
    var statTypes: [StatType] = []
    var leaderboard: [LeaderboardEntry] = []
    var selectedSeasonId: String?
    var selectedStatType: StatType?
    var isLoading = false
    var error: String?

    var groupedStatTypes: [(String, [StatType])] {
        let grouped = Dictionary(grouping: statTypes) { $0.category ?? "General" }
        return grouped.sorted { $0.key < $1.key }
    }

    func loadInitial() async {
        do {
            let seasonsResp: SeasonsResponse = try await APIClient.shared.request(.seasons())
            self.seasons = seasonsResp.seasons
            if let active = seasons.first(where: { $0.status.isActive }) {
                selectedSeasonId = active.id
            } else if let first = seasons.first {
                selectedSeasonId = first.id
            }
        } catch {
            print("[Stats] seasons decode error: \(error)")
        }

        do {
            self.statTypes = try await APIClient.shared.request(.statTypes())
        } catch {
            print("[Stats] statTypes decode error: \(error)")
        }
    }

    func loadLeaderboard() async {
        guard let seasonId = selectedSeasonId, let statType = selectedStatType else {
            leaderboard = []
            return
        }
        isLoading = true
        do {
            leaderboard = try await APIClient.shared.request(
                .leaderboard(seasonId: seasonId, statTypeId: statType.id)
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct StatsView: View {
    @State private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingLG) {
                    seasonPicker
                    statTypePicker
                    leaderboardSection
                }
                .padding()
            }
            .navigationTitle("Stats & Leaderboards")
            .refreshable {
                await viewModel.loadInitial()
                await viewModel.loadLeaderboard()
            }
            .task {
                await viewModel.loadInitial()
            }
        }
    }

    private var seasonPicker: some View {
        Picker("Season", selection: Binding(
            get: { viewModel.selectedSeasonId ?? "" },
            set: {
                viewModel.selectedSeasonId = $0.isEmpty ? nil : $0
                Task { await viewModel.loadLeaderboard() }
            }
        )) {
            ForEach(viewModel.seasons) { season in
                Text(season.name).tag(season.id)
            }
        }
        .pickerStyle(.menu)
    }

    private var statTypePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)

            ForEach(viewModel.groupedStatTypes, id: \.0) { category, types in
                VStack(alignment: .leading, spacing: 8) {
                    Text(category.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(types) { statType in
                            Button {
                                viewModel.selectedStatType = statType
                                Task { await viewModel.loadLeaderboard() }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(statType.display_name ?? statType.name)
                                    if statType.is_higher_better == true {
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption2)
                                    }
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    viewModel.selectedStatType?.id == statType.id
                                        ? Color.accentColor
                                        : Color(.secondarySystemBackground)
                                )
                                .foregroundStyle(
                                    viewModel.selectedStatType?.id == statType.id
                                        ? .white
                                        : .primary
                                )
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let statType = viewModel.selectedStatType {
                Text("\(statType.display_name ?? statType.name) Leaders")
                    .font(.headline)
            } else {
                Text("Select a stat to view leaderboard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.leaderboard.isEmpty && viewModel.selectedStatType != nil {
                Text("No data for this stat")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, entry in
                    HStack(spacing: 12) {
                        rankBadge(index + 1)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.player_name ?? "Unknown")
                                .font(.subheadline.weight(.medium))
                            if let team = entry.team_name {
                                Text(team)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Text(entry.formattedValue)
                            .font(.headline.monospacedDigit())
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func rankBadge(_ rank: Int) -> some View {
        switch rank {
        case 1:
            Image(systemName: "medal.fill")
                .foregroundStyle(.yellow)
                .font(.title3)
        case 2:
            Image(systemName: "medal.fill")
                .foregroundStyle(.gray)
                .font(.title3)
        case 3:
            Image(systemName: "medal.fill")
                .foregroundStyle(.orange)
                .font(.title3)
        default:
            Text("\(rank)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

#Preview {
    StatsView()
}
