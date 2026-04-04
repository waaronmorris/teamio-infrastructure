import SwiftUI

@Observable
@MainActor
final class TeamDetailViewModel {
    var team: Team?
    var roster: [Player] = []
    var isLoading = false
    var error: String?

    func load(teamId: String) async {
        isLoading = true
        error = nil

        do {
            async let teamTask: Team = APIClient.shared.request(.team(teamId))
            async let rosterTask: [Player] = APIClient.shared.request(.teamRoster(teamId))

            let (loadedTeam, loadedRoster) = try await (teamTask, rosterTask)
            self.team = loadedTeam
            self.roster = loadedRoster.sorted { ($0.jersey_number ?? "99") < ($1.jersey_number ?? "99") }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct TeamDetailView: View {
    let teamId: String
    @State private var viewModel = TeamDetailViewModel()

    var body: some View {
        Group {
            if let team = viewModel.team {
                ScrollView {
                    VStack(spacing: AppTheme.spacingLG) {
                        teamHeader(team)
                        infoSection(team)
                        rosterSection
                    }
                    .padding()
                }
            } else if viewModel.isLoading {
                ProgressView("Loading team...")
            } else if let error = viewModel.error {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            }
        }
        .navigationTitle(viewModel.team?.name ?? "Team")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(teamId: teamId)
        }
        .refreshable {
            await viewModel.load(teamId: teamId)
        }
    }

    private func teamHeader(_ team: Team) -> some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay {
                    Text(String(team.name.prefix(2)).uppercased())
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }

            Text(team.name)
                .font(.title2.bold())

            if let coach = team.coach {
                Label("Coach \(coach.fullName)", systemImage: "megaphone.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func infoSection(_ team: Team) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                InfoItem(icon: "person.3.fill", label: "Players", value: "\(viewModel.roster.count)")
                if let field = team.home_field {
                    InfoItem(icon: "mappin", label: "Home Field", value: field.name)
                }
                if let season = team.season_name {
                    InfoItem(icon: "calendar", label: "Season", value: season)
                }
            }
        }
        .cardStyle()
    }

    private var rosterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Roster")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.roster.count) players")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.roster.isEmpty && !viewModel.isLoading {
                Text("Roster is empty -- players will appear once added.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.roster) { player in
                        NavigationLink {
                            PlayerDetailView(playerId: player.id)
                        } label: {
                            PlayerRowView(player: player)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct InfoItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PlayerRowView: View {
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            if let jersey = player.jerseyDisplay {
                Text(jersey)
                    .font(.headline.monospacedDigit())
                    .frame(width: 44)
            } else {
                Image(systemName: "person.fill")
                    .frame(width: 44)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(player.displayName)
                    .font(.subheadline.weight(.medium))
                if let position = player.position {
                    Text(position)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        TeamDetailView(teamId: "test")
    }
}
