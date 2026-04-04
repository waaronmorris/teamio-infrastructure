import SwiftUI

struct StandingsEntry: Decodable, Identifiable, Sendable {
    let id: String
    let team_id: String
    let team_name: String
    let wins: Int
    let losses: Int
    let ties: Int
    let points_for: Int?
    let points_against: Int?
    let games_played: Int?

    var winPercentage: Double {
        let total = wins + losses + ties
        guard total > 0 else { return 0 }
        return Double(wins) / Double(total)
    }

    var differential: Int {
        (points_for ?? 0) - (points_against ?? 0)
    }

    var record: String {
        "\(wins)-\(losses)-\(ties)"
    }
}

@Observable
@MainActor
final class StandingsViewModel {
    var standings: [StandingsEntry] = []
    var recentResults: [ScheduledEvent] = []
    var seasons: [Season] = []
    var selectedSeasonId: String?
    var isLoading = false
    var error: String?

    func loadSeasons() async {
        do {
            let seasonsResponse: SeasonsResponse = try await APIClient.shared.request(.seasons())
            seasons = seasonsResponse.seasons
            if let active = seasons.first(where: { $0.status.isActive }) {
                selectedSeasonId = active.id
            } else if let first = seasons.first {
                selectedSeasonId = first.id
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadStandings() async {
        guard let seasonId = selectedSeasonId else { return }
        isLoading = true

        // Fetch standings and events independently
        do {
            let result: [StandingsEntry] = try await APIClient.shared.request(.standings(seasonId: seasonId))
            self.standings = result.sorted { $0.winPercentage > $1.winPercentage }
        } catch {
            print("[Standings] standings decode error: \(error)")
        }

        do {
            let eventsResp: EventsResponse = try await APIClient.shared.request(.events(),
                queryItems: [URLQueryItem(name: "season_id", value: seasonId), URLQueryItem(name: "per_page", value: "100")]
            )
            self.recentResults = eventsResp.events
                .filter { $0.status == "completed" }
                .sorted { $0.start_time > $1.start_time }
                .prefix(8)
                .map { $0 }
        } catch {
            print("[Standings] events decode error: \(error)")
        }
        isLoading = false
    }
}

struct StandingsView: View {
    @State private var viewModel = StandingsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingLG) {
                    seasonPicker
                    standingsTable
                    recentResultsSection
                }
                .padding()
            }
            .navigationTitle("Standings")
            .refreshable {
                await viewModel.loadStandings()
            }
            .task {
                await viewModel.loadSeasons()
                await viewModel.loadStandings()
            }
            .onChange(of: viewModel.selectedSeasonId) {
                Task { await viewModel.loadStandings() }
            }
        }
    }

    private var seasonPicker: some View {
        Picker("Season", selection: Binding(
            get: { viewModel.selectedSeasonId ?? "" },
            set: { viewModel.selectedSeasonId = $0.isEmpty ? nil : $0 }
        )) {
            ForEach(viewModel.seasons) { season in
                Text(season.name).tag(season.id)
            }
        }
        .pickerStyle(.menu)
    }

    private var standingsTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("League Standings")
                .font(.headline)

            if viewModel.isLoading && viewModel.standings.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.standings.isEmpty {
                Text("No standings data yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                // Header
                HStack {
                    Text("#")
                        .frame(width: 24)
                    Text("Team")
                    Spacer()
                    Text("W")
                        .frame(width: 28)
                    Text("L")
                        .frame(width: 28)
                    Text("T")
                        .frame(width: 28)
                    Text("Win%")
                        .frame(width: 44)
                    Text("+/-")
                        .frame(width: 36)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                Divider()

                ForEach(Array(viewModel.standings.enumerated()), id: \.element.id) { index, entry in
                    HStack {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.bold))
                            .frame(width: 24)
                        Text(entry.team_name)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Text("\(entry.wins)")
                            .frame(width: 28)
                        Text("\(entry.losses)")
                            .frame(width: 28)
                        Text("\(entry.ties)")
                            .frame(width: 28)
                        Text(String(format: "%.0f%%", entry.winPercentage * 100))
                            .frame(width: 44)
                        Text(entry.differential >= 0 ? "+\(entry.differential)" : "\(entry.differential)")
                            .foregroundStyle(entry.differential >= 0 ? .green : .red)
                            .frame(width: 36)
                    }
                    .font(.subheadline.monospacedDigit())

                    if index < viewModel.standings.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }

    private var recentResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Results")
                .font(.headline)

            if viewModel.recentResults.isEmpty {
                Text("No results yet -- games are still being played!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.recentResults) { event in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.displayTitle)
                                .font(.subheadline.weight(.medium))
                            Text(event.start_time.shortDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let score = event.scoreDisplay {
                            Text(score)
                                .font(.headline.monospacedDigit())
                        }
                    }
                    Divider()
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    StandingsView()
}
