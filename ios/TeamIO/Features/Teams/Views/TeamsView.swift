import SwiftUI

/// "My Hub" — a personal command center showing only what's relevant to the user.
/// No "browse all teams." Each section maps to a role the user has.
struct TeamsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(UserRolesManager.self) private var rolesManager
    @State private var coachData = CoachHubData()
    @State private var parentData = ParentHubData()
    @State private var refereeData = RefereeHubData()
    @State private var adminData = AdminHubData()
    @State private var playerData = PlayerHubData()
    @State private var isLoading = false
    @State private var showBroadcastSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingLG) {
                    if isLoading {
                        ProgressView("Loading...")
                            .padding(.top, 40)
                    } else {
                        // Coach section
                        if rolesManager.isCoach {
                            coachSection
                        }

                        // Parent section
                        if rolesManager.isGuardian {
                            parentSection
                        }

                        // Referee section
                        if rolesManager.isReferee {
                            refereeSection
                        }

                        // Commissioner/Admin section
                        if authManager.currentUser?.role == .commissioner || authManager.currentUser?.role == .admin {
                            adminSection
                        }

                        // Empty state if nothing loaded
                        if !rolesManager.isCoach && !rolesManager.isGuardian && !rolesManager.isReferee
                            && authManager.currentUser?.role != .commissioner && authManager.currentUser?.role != .admin {
                            playerSection
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("My Hub")
            .refreshable { await loadAll() }
            .task { await loadAll() }
            .sheet(isPresented: $showBroadcastSheet) {
                ComposeMessageSheet()
            }
        }
    }

    private func loadAll() async {
        isLoading = true
        guard let user = authManager.currentUser else { isLoading = false; return }

        await withTaskGroup(of: Void.self) { group in
            if rolesManager.isCoach {
                group.addTask { await coachData.load(userId: user.id) }
            }
            if rolesManager.isGuardian {
                group.addTask { await parentData.load(userId: user.id) }
            }
            if rolesManager.isReferee {
                group.addTask { await refereeData.load(userId: user.id) }
            }
            if user.role == .commissioner || user.role == .admin {
                group.addTask { await adminData.load() }
            }
            // Always load player data for fallback section
            group.addTask { await playerData.load(userId: user.id) }
        }
        isLoading = false
    }

    // MARK: - Coach Section

    private var coachSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("My Teams", systemImage: "megaphone.fill")
                        .font(.headline)
                        .foregroundStyle(.teal)
                    Text("Tap to manage rosters and schedules")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                NavigationLink("Coach Portal") {
                    CoachPortalView()
                }
                .font(.subheadline)
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .controlSize(.small)
            }

            if coachData.teams.isEmpty {
                Text("No teams yet -- check back soon!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(coachData.teams) { team in
                    NavigationLink {
                        TeamDetailView(teamId: team.id)
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.teal.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Text(String(team.name.prefix(2)).uppercased())
                                        .font(.caption.bold())
                                        .foregroundStyle(.teal)
                                }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(team.name)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(team.player_count ?? 0) players")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Parent Section

    private var parentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("My Family", systemImage: "figure.2.and.child.holdinghands")
                        .font(.headline)
                        .foregroundStyle(.pink)
                    Text("Tap to view schedules and registrations")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                NavigationLink("Family Portal") {
                    ParentPortalView()
                }
                .font(.subheadline)
                .buttonStyle(.borderedProminent)
                .tint(.pink)
                .controlSize(.small)
            }

            if parentData.children.isEmpty {
                Text("No children linked yet -- register a player to get started!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(parentData.children) { child in
                    HStack(spacing: 12) {
                        AvatarView(name: child.player.name, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(child.player.name)
                                .font(.subheadline.weight(.semibold))
                            if let pos = child.player.position {
                                Text(pos.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let team = child.teams.first {
                                Text(team.name)
                                    .font(.caption2)
                                    .foregroundStyle(.pink)
                            }
                        }
                        Spacer()
                        if let jersey = child.player.jersey_number {
                            Text("#\(jersey)")
                                .font(.caption.monospacedDigit().bold())
                                .foregroundStyle(.pink)
                        }
                    }
                }
            }

            if !parentData.pendingRegistrations.isEmpty {
                Divider()
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text("\(parentData.pendingRegistrations.count) pending registration(s)")
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Referee Section

    private var refereeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Officiating", systemImage: "flag.fill")
                        .font(.headline)
                        .foregroundStyle(.purple)
                    Text("Tap to manage assignments and availability")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let refId = rolesManager.refereeId {
                    NavigationLink("Referee Portal") {
                        RefereePortalView(refereeId: refId)
                    }
                    .font(.subheadline)
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .controlSize(.small)
                }
            }

            HStack(spacing: 16) {
                VStack {
                    Text("\(refereeData.assignmentCount)")
                        .font(.title2.bold())
                    Text("Assigned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Text(refereeData.earnedDisplay)
                        .font(.title2.bold())
                    Text("Earned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(text: refereeData.certification ?? "No cert", color: .purple)
            }
        }
        .cardStyle()
    }

    // MARK: - Admin/Commissioner Section

    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("League Overview", systemImage: "building.2.fill")
                        .font(.headline)
                    Text("Tap to manage teams, registrations, and officials")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if authManager.currentUser?.role == .commissioner || authManager.currentUser?.role == .admin {
                    NavigationLink("Manage") {
                        LeagueManagementView()
                    }
                    .font(.subheadline)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            // Pending registrations alert
            if adminData.pendingRegistrationCount > 0 {
                NavigationLink {
                    RegistrationManagementView()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("\(adminData.pendingRegistrationCount) registration\(adminData.pendingRegistrationCount == 1 ? "" : "s") need\(adminData.pendingRegistrationCount == 1 ? "s" : "") approval")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM))
                }
                .buttonStyle(.plain)
            }

            // Quick broadcast
            Button {
                showBroadcastSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "megaphone.fill")
                    Text("Send Broadcast")
                        .font(.subheadline.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM))
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                StatCard(icon: "person.3.fill", value: "\(adminData.teamCount)", label: "Teams")
                StatCard(icon: "figure.run", value: "\(adminData.playerCount)", label: "Players")
                StatCard(icon: "calendar", value: "\(adminData.upcomingGameCount)", label: "Games")
            }
        }
    }

    // MARK: - Player Section (fallback)

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("My Team", systemImage: "figure.run")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text("Tap to view stats and schedule")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                NavigationLink("Player Portal") {
                    PlayerPortalView()
                }
                .font(.subheadline)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.small)
            }

            if let teamName = playerData.teamName {
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(teamName)
                            .font(.subheadline.weight(.semibold))
                        Text("Team")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let jersey = playerData.jerseyNumber {
                        VStack(spacing: 4) {
                            Text("#\(jersey)")
                                .font(.subheadline.weight(.bold).monospacedDigit())
                                .foregroundStyle(.orange)
                            Text("Jersey")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let position = playerData.position {
                        VStack(spacing: 4) {
                            Text(position.capitalized)
                                .font(.subheadline.weight(.medium))
                            Text("Position")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(10)
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM))
            }

            if let stats = playerData.statsSummary {
                HStack(spacing: 12) {
                    if let gamesPlayed = stats.games_played, gamesPlayed > 0 {
                        StatCard(icon: "sportscourt.fill", value: "\(gamesPlayed)", label: "Games")
                    }
                    if let statValues = stats.stats {
                        ForEach(Array(statValues.prefix(2)), id: \.key) { key, value in
                            StatCard(icon: "chart.bar.fill", value: String(format: "%.0f", value), label: key.capitalized)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Data Models

@Observable @MainActor
final class CoachHubData {
    var teams: [Team] = []

    func load(userId: String) async {
        do {
            let resp: TeamsResponse = try await APIClient.shared.request(.teams(), queryItems: [URLQueryItem(name: "per_page", value: "50")])
            teams = resp.teams.filter { $0.coach?.user_id == userId }
        } catch {
            print("[MyHub] coach teams error: \(error)")
        }
    }
}

@Observable @MainActor
final class ParentHubData {
    var children: [ChildInfo] = []
    var pendingRegistrations: [Registration] = []

    func load(userId: String) async {
        do {
            let portal: ParentDashboardResponse = try await APIClient.shared.request(.parentPortal(userId))
            children = portal.children ?? []
            pendingRegistrations = (portal.pending_registrations ?? []).filter { $0.status == "pending" }
        } catch {
            print("[MyHub] parent data error: \(error)")
        }
    }
}

@Observable @MainActor
final class RefereeHubData {
    var assignmentCount: Int = 0
    var totalEarnedCents: Int = 0
    var certification: String?

    var earnedDisplay: String {
        totalEarnedCents == 0 ? "$0" : String(format: "$%.0f", Double(totalEarnedCents) / 100.0)
    }

    func load(userId: String) async {
        do {
            let ref: RefereePortalResponse = try await APIClient.shared.request(.refereePortal(userId))
            assignmentCount = ref.assignment_count
            totalEarnedCents = ref.total_earned_cents
            certification = ref.certification_level
        } catch {
            print("[MyHub] referee data error: \(error)")
        }
    }
}

@Observable @MainActor
final class AdminHubData {
    var teamCount: Int = 0
    var playerCount: Int = 0
    var upcomingGameCount: Int = 0
    var pendingRegistrationCount: Int = 0

    func load() async {
        do {
            let teams: TeamsResponse = try await APIClient.shared.request(.teams(), queryItems: [URLQueryItem(name: "per_page", value: "50")])
            teamCount = teams.teams.count
            playerCount = teams.teams.compactMap { $0.player_count }.reduce(0, +)
        } catch {
            print("[MyHub] admin teams error: \(error)")
        }
        do {
            let events: EventsResponse = try await APIClient.shared.request(.events(), queryItems: [URLQueryItem(name: "per_page", value: "100")])
            upcomingGameCount = events.events.filter { $0.isUpcoming && $0.isGame }.count
        } catch {
            print("[MyHub] admin events error: \(error)")
        }
        do {
            let regs: RegistrationsResponse = try await APIClient.shared.request(
                .registrations(),
                queryItems: [URLQueryItem(name: "status", value: "pending"), URLQueryItem(name: "per_page", value: "100")]
            )
            pendingRegistrationCount = regs.registrations.filter { $0.status == "pending" }.count
        } catch {
            print("[MyHub] admin registrations error: \(error)")
        }
    }
}

@Observable @MainActor
final class PlayerHubData {
    var teamName: String?
    var jerseyNumber: String?
    var position: String?
    var statsSummary: PlayerStatsSummary?

    func load(userId: String) async {
        do {
            let portal: PlayerDashboardResponse = try await APIClient.shared.request(.playerPortal(userId))
            teamName = portal.teams?.first?.name
            jerseyNumber = portal.player?.jersey_number
            position = portal.player?.position
            statsSummary = portal.stats_summary
        } catch {
            // Player portal may not be available for all users
            print("[MyHub] player data: \(error)")
        }
    }
}

#Preview {
    TeamsView()
        .environment(AuthManager())
        .environment(UserRolesManager())
}
