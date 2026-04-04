import SwiftUI

@Observable
@MainActor
final class PlayerPortalViewModel {
    var player: Player?
    var teams: [Team] = []
    var upcomingEvents: [ScheduledEvent] = []
    var recentResults: [ScheduledEvent] = []
    var teammates: [Player] = []
    var isLoading = false
    var error: String?

    func load(userId: String) async {
        isLoading = true
        do {
            let portal: PlayerDashboardResponse = try await APIClient.shared.request(.playerPortal(userId))
            self.player = portal.player
            self.teams = portal.teams ?? []
            self.upcomingEvents = (portal.upcoming_events ?? [])
                .filter { $0.isUpcoming }
                .sorted { $0.start_time < $1.start_time }
                .prefix(5).map { $0 }
            self.recentResults = (portal.upcoming_events ?? [])
                .filter { $0.status == "completed" }
                .sorted { $0.start_time > $1.start_time }
                .prefix(5).map { $0 }

            if let teamId = teams.first?.id {
                self.teammates = try await APIClient.shared.request(.teamRoster(teamId))
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func submitRsvp(eventId: String, status: String) async {
        let request = RsvpRequest(status: status, player_id: player?.id, note: nil)
        do {
            let _: EventRsvp = try await APIClient.shared.request(.submitRsvp(eventId), body: request)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct PlayerPortalView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = PlayerPortalViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingLG) {
                    statsCards
                    teamInfoCard
                    upcomingSchedule
                    teammatesSection
                    recentResultsSection
                }
                .padding()
            }
            .navigationTitle("Player Portal")
            .refreshable {
                if let userId = authManager.currentUser?.id {
                    await viewModel.load(userId: userId)
                }
            }
            .task {
                if let userId = authManager.currentUser?.id {
                    await viewModel.load(userId: userId)
                }
            }
        }
    }

    private var statsCards: some View {
        HStack(spacing: 12) {
            StatCard(icon: "person.3.fill", value: viewModel.teams.first?.name ?? "--", label: "My Team")
            StatCard(icon: "tshirt.fill", value: viewModel.player?.jerseyDisplay ?? "--", label: "Jersey")
            StatCard(icon: "figure.run", value: viewModel.player?.position ?? "--", label: "Position")
            StatCard(icon: "calendar", value: "\(viewModel.upcomingEvents.count)", label: "Upcoming")
        }
    }

    private var teamInfoCard: some View {
        Group {
            if let team = viewModel.teams.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Team Info")
                        .font(.headline)

                    HStack {
                        if let coach = team.coach {
                            Label("Coach \(coach.fullName)", systemImage: "megaphone.fill")
                        }
                        Spacer()
                        if let season = team.season_name {
                            Text(season)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                }
                .cardStyle()
            }
        }
    }

    private var upcomingSchedule: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Schedule")
                .font(.headline)

            if viewModel.upcomingEvents.isEmpty {
                Text("You're all caught up! No events scheduled.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.upcomingEvents) { event in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.displayTitle)
                                .font(.subheadline.weight(.medium))
                            HStack {
                                Text(event.start_time.shortDateTime)
                                if let field = event.field_name {
                                    Text("at \(field)")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Quick RSVP
                        HStack(spacing: 6) {
                            Button {
                                Task { await viewModel.submitRsvp(eventId: event.id, status: "accepted") }
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            Button {
                                Task { await viewModel.submitRsvp(eventId: event.id, status: "declined") }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .font(.title3)
                    }
                    Divider()
                }
            }
        }
        .cardStyle()
    }

    private var teammatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Teammates")
                .font(.headline)

            LazyVStack(spacing: 0) {
                ForEach(viewModel.teammates.prefix(15)) { player in
                    HStack(spacing: 10) {
                        Text(player.jerseyDisplay ?? "--")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .frame(width: 32)
                        Text(player.displayName)
                            .font(.subheadline)
                        Spacer()
                        if let pos = player.position {
                            Text(pos)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    Divider()
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
                        Text(event.displayTitle)
                            .font(.subheadline)
                        Spacer()
                        if let score = event.scoreDisplay {
                            Text(score)
                                .font(.subheadline.monospacedDigit().weight(.bold))
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
    PlayerPortalView()
        .environment(AuthManager())
}
