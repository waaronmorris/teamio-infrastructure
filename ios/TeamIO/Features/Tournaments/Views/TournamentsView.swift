import SwiftUI

@Observable
@MainActor
final class TournamentsViewModel {
    var tournaments: [Tournament] = []
    var selectedTournament: Tournament?
    var matchups: [TournamentMatchup] = []
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        do {
            tournaments = try await APIClient.shared.request(.tournaments())
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadMatchups(bracketId: String) async {
        do {
            matchups = try await APIClient.shared.request(.tournamentMatchups(bracketId))
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct TournamentsView: View {
    @State private var viewModel = TournamentsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.tournaments.isEmpty {
                    ProgressView("Loading tournaments...")
                } else if viewModel.tournaments.isEmpty {
                    ContentUnavailableView(
                        "No Tournaments",
                        systemImage: "trophy",
                        description: Text("No tournaments have been created yet.")
                    )
                } else {
                    List(viewModel.tournaments) { tournament in
                        NavigationLink {
                            BracketDetailView(tournament: tournament)
                        } label: {
                            TournamentRow(tournament: tournament)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Tournaments")
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
        }
    }
}

struct TournamentRow: View {
    let tournament: Tournament

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.name)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 12) {
                    if let type = tournament.bracket_type {
                        Label(type.replacingOccurrences(of: "_", with: " ").capitalized, systemImage: "trophy")
                    }
                    if let teams = tournament.team_count {
                        Label("\(teams) teams", systemImage: "person.3")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if let status = tournament.status {
                StatusBadge(
                    text: status.capitalized,
                    color: status == "completed" ? .green : status == "in_progress" ? .orange : .blue
                )
            }
        }
    }
}

struct BracketDetailView: View {
    let tournament: Tournament
    @State private var matchups: [TournamentMatchup] = []
    @State private var isLoading = false

    var roundCount: Int {
        matchups.map { $0.round }.max() ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLG) {
                // Info
                VStack(spacing: 8) {
                    if let desc = tournament.description {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 20) {
                        if let type = tournament.bracket_type {
                            InfoItem(icon: "trophy", label: "Format", value: type.replacingOccurrences(of: "_", with: " ").capitalized)
                        }
                        if let teams = tournament.team_count {
                            InfoItem(icon: "person.3", label: "Teams", value: "\(teams)")
                        }
                        InfoItem(icon: "number", label: "Rounds", value: "\(roundCount)")
                    }
                }
                .cardStyle()

                // Bracket rounds
                ForEach(1...max(roundCount, 1), id: \.self) { round in
                    roundSection(round: round)
                }
            }
            .padding()
        }
        .navigationTitle(tournament.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isLoading = true
            do {
                matchups = try await APIClient.shared.request(.tournamentMatchups(tournament.id))
            } catch {}
            isLoading = false
        }
    }

    private func roundSection(round: Int) -> some View {
        let roundMatchups = matchups.filter { $0.round == round }.sorted { $0.position < $1.position }
        let roundName: String = {
            if round == roundCount { return "Final" }
            if round == roundCount - 1 && roundCount > 1 { return "Semifinal" }
            return "Round \(round)"
        }()

        return VStack(alignment: .leading, spacing: 8) {
            Text(roundName)
                .font(.headline)

            ForEach(roundMatchups) { matchup in
                MatchupCard(matchup: matchup)
            }
        }
    }
}

struct MatchupCard: View {
    let matchup: TournamentMatchup

    var body: some View {
        VStack(spacing: 0) {
            teamRow(
                name: matchup.team1_name,
                seed: matchup.team1_seed,
                score: matchup.team1_score,
                isWinner: matchup.winner_id == matchup.team1_id
            )
            Divider()
            teamRow(
                name: matchup.team2_name,
                seed: matchup.team2_seed,
                score: matchup.team2_score,
                isWinner: matchup.winner_id == matchup.team2_id
            )
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM))
    }

    private func teamRow(name: String?, seed: Int?, score: Int?, isWinner: Bool) -> some View {
        HStack {
            if let seed {
                Text("#\(seed)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
            }
            Text(name ?? "TBD")
                .font(.subheadline.weight(isWinner ? .bold : .regular))
                .foregroundStyle(name == nil ? .tertiary : .primary)
            Spacer()
            if let score {
                Text("\(score)")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(isWinner ? Color.accentColor : .primary)
            }
            if isWinner {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isWinner ? Color.green.opacity(0.05) : .clear)
    }
}

#Preview {
    TournamentsView()
}
