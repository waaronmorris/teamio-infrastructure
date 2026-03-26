import SwiftUI

@Observable
@MainActor
final class PlayerDetailViewModel {
    var player: Player?
    var guardians: [Guardian] = []
    var stats: [PlayerStats] = []
    var isLoading = false
    var error: String?

    func load(playerId: String) async {
        isLoading = true
        error = nil

        do {
            async let playerTask: Player = APIClient.shared.request(.player(playerId))
            async let guardiansTask: [Guardian] = APIClient.shared.request(.playerGuardians(playerId))

            let (loadedPlayer, loadedGuardians) = try await (playerTask, guardiansTask)
            self.player = loadedPlayer
            self.guardians = loadedGuardians
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct PlayerDetailView: View {
    let playerId: String
    @State private var viewModel = PlayerDetailViewModel()

    var body: some View {
        Group {
            if let player = viewModel.player {
                ScrollView {
                    VStack(spacing: AppTheme.spacingLG) {
                        playerHeader(player)
                        playerInfoCard(player)
                        if !viewModel.guardians.isEmpty {
                            guardiansSection
                        }
                    }
                    .padding()
                }
            } else if viewModel.isLoading {
                ProgressView("Loading player...")
            } else if let error = viewModel.error {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            }
        }
        .navigationTitle(viewModel.player?.displayName ?? "Player")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.load(playerId: playerId)
        }
        .task {
            await viewModel.load(playerId: playerId)
        }
    }

    private func playerHeader(_ player: Player) -> some View {
        VStack(spacing: 12) {
            AvatarView(name: player.displayName, size: 80)

            Text(player.displayName)
                .font(.title2.bold())

            HStack(spacing: 16) {
                if let jersey = player.jerseyDisplay {
                    Label(jersey, systemImage: "tshirt.fill")
                }
                if let position = player.position {
                    Label(position, systemImage: "figure.run")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private func playerInfoCard(_ player: Player) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Info")
                .font(.headline)

            if let dob = player.date_of_birth {
                HStack {
                    Text("Date of Birth")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(dob.shortDate)
                }
                .font(.subheadline)
            }

            HStack {
                Text("Status")
                    .foregroundStyle(.secondary)
                Spacer()
                StatusBadge(
                    text: player.isActive ? "Active" : "Inactive",
                    color: player.isActive ? .green : .red
                )
            }
            .font(.subheadline)

            if let joined = player.joined_at {
                HStack {
                    Text("Joined")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(joined.shortDate)
                }
                .font(.subheadline)
            }
        }
        .cardStyle()
    }

    private var guardiansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Guardians")
                .font(.headline)

            ForEach(viewModel.guardians) { guardian in
                HStack(spacing: 12) {
                    AvatarView(name: guardian.fullName, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(guardian.fullName)
                            .font(.subheadline.weight(.medium))
                        if let relationship = guardian.relationship {
                            Text(relationship.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if let phone = guardian.phone {
                        Link(destination: URL(string: "tel:\(phone)")!) {
                            Image(systemName: "phone.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        PlayerDetailView(playerId: "test")
    }
}
