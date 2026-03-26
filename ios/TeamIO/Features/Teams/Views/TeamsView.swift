import SwiftUI

@Observable
@MainActor
final class TeamsViewModel {
    var myTeams: [Team] = []
    var allTeams: [Team] = []
    var allEvents: [ScheduledEvent] = []
    var seasons: [Season] = []
    var registrations: [Registration] = []
    var isLoading = false
    var error: String?
    var searchText = ""

    // Commissioner stats
    var totalPlayers: Int { allTeams.compactMap { $0.player_count }.reduce(0, +) }
    var upcomingGames: [ScheduledEvent] { allEvents.filter { $0.isUpcoming && $0.isGame }.sorted { $0.start_time < $1.start_time } }
    var completedGames: [ScheduledEvent] { allEvents.filter { $0.status == "completed" && $0.isGame }.sorted { $0.start_time > $1.start_time } }

    var filteredTeams: [Team] {
        let source = myTeams.isEmpty ? allTeams : myTeams
        if searchText.isEmpty { return source }
        return source.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func load(user: User?) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        // Fetch teams
        do {
            let response: TeamsResponse = try await APIClient.shared.request(
                .teams(), queryItems: [URLQueryItem(name: "per_page", value: "50")]
            )
            self.allTeams = response.teams
        } catch {
            print("[Teams] teams decode error: \(error)")
        }

        // Scope teams by role
        if let user {
            switch user.role {
            case .coach:
                self.myTeams = allTeams.filter { $0.coach?.user_id == user.id }
            case .parent, .guardian:
                // Fetch children's team IDs
                do {
                    let portal: ParentDashboardResponse = try await APIClient.shared.request(.parentPortal(user.id))
                    let childTeamIds = Set((portal.children ?? []).compactMap { $0.team_id })
                    if !childTeamIds.isEmpty {
                        self.myTeams = allTeams.filter { childTeamIds.contains($0.id) }
                    } else {
                        self.myTeams = allTeams
                    }
                } catch {
                    print("[Teams] parent portal decode error: \(error)")
                    self.myTeams = allTeams
                }
            case .player:
                do {
                    let portal: PlayerDashboardResponse = try await APIClient.shared.request(.playerPortal(user.id))
                    let playerTeamIds = Set((portal.teams ?? []).map { $0.id })
                    if !playerTeamIds.isEmpty {
                        self.myTeams = allTeams.filter { playerTeamIds.contains($0.id) }
                    } else {
                        self.myTeams = allTeams
                    }
                } catch {
                    print("[Teams] player portal decode error: \(error)")
                    self.myTeams = allTeams
                }
            default:
                self.myTeams = allTeams
            }
        } else {
            self.myTeams = allTeams
        }

        // Commissioner/Admin: also fetch events, seasons, registrations for dashboard
        if let role = user?.role, role == .commissioner || role == .admin {
            do {
                let eventsResp: EventsResponse = try await APIClient.shared.request(
                    .events(), queryItems: [URLQueryItem(name: "per_page", value: "200")]
                )
                self.allEvents = eventsResp.events
            } catch {
                print("[Teams] events decode error: \(error)")
            }

            do {
                let seasonsResp: SeasonsResponse = try await APIClient.shared.request(.seasons())
                self.seasons = seasonsResp.seasons
            } catch {
                print("[Teams] seasons decode error: \(error)")
            }
        }

        isLoading = false
    }
}

struct TeamsView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = TeamsViewModel()
    @State private var showAllTeams = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.allTeams.isEmpty {
                    ProgressView("Loading...")
                } else {
                    roleBasedContent
                }
            }
            .navigationTitle(tabTitle)
            .searchable(text: $viewModel.searchText, prompt: "Search teams")
            .navigationDestination(for: Team.self) { team in
                TeamDetailView(teamId: team.id)
            }
            .navigationDestination(for: ScheduledEvent.self) { event in
                EventDetailView(eventId: event.id)
            }
            .refreshable {
                await viewModel.load(user: authManager.currentUser)
            }
            .task {
                await viewModel.load(user: authManager.currentUser)
            }
        }
    }

    private var tabTitle: String {
        switch authManager.currentUser?.role {
        case .coach: return "My Teams"
        case .parent, .guardian: return "Family"
        case .commissioner: return "League"
        case .admin: return "Organization"
        default: return "Teams"
        }
    }

    @ViewBuilder
    private var roleBasedContent: some View {
        switch authManager.currentUser?.role {
        case .commissioner, .admin:
            commissionerDashboard
        case .coach:
            coachTeamsList
        default:
            defaultTeamsList
        }
    }

    // MARK: - Commissioner Dashboard

    private var commissionerDashboard: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLG) {
                // Stats overview
                HStack(spacing: 12) {
                    StatCard(icon: "person.3.fill", value: "\(viewModel.allTeams.count)", label: "Teams")
                    StatCard(icon: "figure.run", value: "\(viewModel.totalPlayers)", label: "Players")
                    StatCard(icon: "calendar", value: "\(viewModel.upcomingGames.count)", label: "Upcoming")
                }

                // Active season
                if let activeSeason = viewModel.seasons.first(where: { $0.status.isActive }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Active Season")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(activeSeason.name)
                                .font(.headline)
                        }
                        Spacer()
                        StatusBadge(text: activeSeason.status.displayName, color: .green)
                    }
                    .cardStyle()
                }

                // This week's games
                thisWeeksGames

                // Recent results
                if !viewModel.completedGames.isEmpty {
                    recentResultsSection
                }

                // All teams
                allTeamsSection
            }
            .padding()
        }
    }

    private var thisWeeksGames: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Games")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    ScheduleView()
                }
                .font(.subheadline)
            }

            if viewModel.upcomingGames.isEmpty {
                Text("No upcoming games")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.upcomingGames.prefix(5)) { event in
                    NavigationLink(value: event) {
                        EventRowView(event: event)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }

    private var recentResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Results")
                    .font(.headline)
                Spacer()
                NavigationLink("Standings") {
                    StandingsView()
                }
                .font(.subheadline)
            }

            ForEach(viewModel.completedGames.prefix(5)) { event in
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
                if event.id != viewModel.completedGames.prefix(5).last?.id {
                    Divider()
                }
            }
        }
        .cardStyle()
    }

    private var allTeamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Teams")
                .font(.headline)

            ForEach(viewModel.filteredTeams) { team in
                NavigationLink(value: team) {
                    TeamRowView(team: team)
                }
                .buttonStyle(.plain)
            }
        }
        .cardStyle()
    }

    // MARK: - Coach Teams List

    private var coachTeamsList: some View {
        List {
            if !viewModel.myTeams.isEmpty {
                Section("Teams I Coach") {
                    ForEach(viewModel.filteredTeams) { team in
                        NavigationLink(value: team) {
                            TeamRowView(team: team)
                        }
                    }
                }
            }

            if viewModel.allTeams.count > viewModel.myTeams.count {
                if showAllTeams {
                    Section("Other Teams") {
                        ForEach(viewModel.allTeams.filter { team in
                            !viewModel.myTeams.contains(where: { $0.id == team.id })
                        }) { team in
                            NavigationLink(value: team) {
                                TeamRowView(team: team)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        withAnimation { showAllTeams.toggle() }
                    } label: {
                        Label(
                            showAllTeams ? "Hide Other Teams" : "Browse All Teams",
                            systemImage: showAllTeams ? "chevron.up" : "chevron.down"
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Default Teams List

    private var defaultTeamsList: some View {
        Group {
            if viewModel.filteredTeams.isEmpty && !viewModel.searchText.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            } else if viewModel.filteredTeams.isEmpty {
                ContentUnavailableView(
                    "No Teams",
                    systemImage: "person.3",
                    description: Text("You're not on any teams yet.")
                )
            } else {
                List(viewModel.filteredTeams) { team in
                    NavigationLink(value: team) {
                        TeamRowView(team: team)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

#Preview {
    TeamsView()
        .environment(AuthManager())
}
