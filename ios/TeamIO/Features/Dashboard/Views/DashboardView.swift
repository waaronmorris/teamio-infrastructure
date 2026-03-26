import SwiftUI

/// An event with role context tags showing WHY the user sees it
struct TaggedEvent: Identifiable {
    let event: ScheduledEvent
    var roles: Set<EventRoleTag>
    var id: String { event.id }
}

enum EventRoleTag: String, Hashable {
    case coach = "Coach"
    case parent = "Parent"
    case player = "Player"
    case referee = "Ref"
    case league = "League"

    var icon: String {
        switch self {
        case .coach: return "megaphone.fill"
        case .parent: return "figure.2.and.child.holdinghands"
        case .player: return "figure.run"
        case .referee: return "flag.fill"
        case .league: return "calendar"
        }
    }

    var color: Color {
        switch self {
        case .coach: return .teal
        case .parent: return .pink
        case .player: return .orange
        case .referee: return .purple
        case .league: return .secondary
        }
    }
}

@Observable
@MainActor
final class DashboardViewModel {
    var taggedEvents: [TaggedEvent] = []
    var teams: [Team] = []
    var coachedTeamIds: Set<String> = []
    var childrenTeamIds: Set<String> = []
    var playerTeamIds: Set<String> = []
    var isLoading = false
    var error: String?

    var upcomingEvents: [ScheduledEvent] {
        taggedEvents.map { $0.event }
    }

    func load(user: User?, rolesManager: UserRolesManager, eventLimit: Int = 10) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        var allTeams: [Team] = []
        var allEvents: [ScheduledEvent] = []

        // Fetch teams
        do {
            let resp: TeamsResponse = try await APIClient.shared.request(.teams(), queryItems: [URLQueryItem(name: "per_page", value: "50")])
            allTeams = resp.teams
        } catch {
            print("[Dashboard] Teams error: \(error)")
        }

        // Fetch events
        do {
            let resp: EventsResponse = try await APIClient.shared.request(.events(), queryItems: [URLQueryItem(name: "per_page", value: "200")])
            allEvents = resp.events
        } catch {
            print("[Dashboard] Events error: \(error)")
        }

        guard let user else {
            self.teams = allTeams
            self.taggedEvents = allEvents.filter { $0.isUpcoming }
                .sorted { $0.start_time < $1.start_time }
                .prefix(eventLimit)
                .map { TaggedEvent(event: $0, roles: [.league]) }
            isLoading = false
            return
        }

        // Determine team IDs per role
        if user.role == .coach || rolesManager.isCoach {
            coachedTeamIds = Set(allTeams.filter { $0.coach?.user_id == user.id }.map { $0.id })
        }

        if user.role == .parent || user.role == .guardian || rolesManager.isGuardian {
            // Try fetching children's teams (only works if primary role is guardian)
            if user.role == .parent || user.role == .guardian {
                do {
                    let portal: ParentDashboardResponse = try await APIClient.shared.request(.parentPortal(user.id))
                    childrenTeamIds = Set((portal.children ?? []).compactMap { $0.team_id })
                } catch {
                    print("[Dashboard] Parent portal: \(error)")
                }
            }
        }

        if user.role == .player {
            do {
                let portal: PlayerDashboardResponse = try await APIClient.shared.request(.playerPortal(user.id))
                playerTeamIds = Set((portal.teams ?? []).map { $0.id })
            } catch {
                print("[Dashboard] Player portal: \(error)")
            }
        }

        // Combine all "my" team IDs
        var allMyTeamIds: Set<String> = []
        allMyTeamIds.formUnion(coachedTeamIds)
        allMyTeamIds.formUnion(childrenTeamIds)
        allMyTeamIds.formUnion(playerTeamIds)

        // Filter teams
        if !allMyTeamIds.isEmpty && user.role != .admin && user.role != .commissioner {
            self.teams = allTeams.filter { allMyTeamIds.contains($0.id) }
        } else {
            self.teams = allTeams
        }

        // Build tagged events — each event gets role tags showing WHY the user sees it
        let relevant = allEvents.filter { $0.isUpcoming }
            .sorted { $0.start_time < $1.start_time }

        var tagged: [TaggedEvent] = []
        for event in relevant {
            var roles: Set<EventRoleTag> = []

            // Coach tag
            if let homeId = event.home_team_id, coachedTeamIds.contains(homeId) { roles.insert(.coach) }
            if let awayId = event.away_team_id, coachedTeamIds.contains(awayId) { roles.insert(.coach) }

            // Parent tag
            if let homeId = event.home_team_id, childrenTeamIds.contains(homeId) { roles.insert(.parent) }
            if let awayId = event.away_team_id, childrenTeamIds.contains(awayId) { roles.insert(.parent) }

            // Player tag
            if let homeId = event.home_team_id, playerTeamIds.contains(homeId) { roles.insert(.player) }
            if let awayId = event.away_team_id, playerTeamIds.contains(awayId) { roles.insert(.player) }

            // League-wide events (no team)
            if event.home_team_id == nil && event.away_team_id == nil { roles.insert(.league) }

            // Commissioner/Admin sees everything
            if user.role == .commissioner || user.role == .admin {
                if roles.isEmpty { roles.insert(.league) }
                tagged.append(TaggedEvent(event: event, roles: roles))
            } else if !roles.isEmpty {
                tagged.append(TaggedEvent(event: event, roles: roles))
            }
        }

        self.taggedEvents = Array(tagged.prefix(eventLimit))
        isLoading = false
    }
}

struct DashboardView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = DashboardViewModel()
    @State private var rolesManager = UserRolesManager()
    @State private var showSearch = false
    @State private var showEditShortcuts = false
    @AppStorage("dashboardEventCount") private var dashboardEventCount = 10
    @AppStorage("shortcutOrder") private var shortcutOrderString = ""
    @AppStorage("hiddenShortcuts") private var hiddenShortcutsString = ""

    private var shortcutOrder: [String] {
        shortcutOrderString.isEmpty ? [] : shortcutOrderString.components(separatedBy: ",")
    }

    private var hiddenIds: Set<String> {
        Set(hiddenShortcutsString.isEmpty ? [] : hiddenShortcutsString.components(separatedBy: ","))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingLG) {
                    // Quick actions bar (top, customizable)
                    quickActionsBar

                    // Admin summary (only for admins)
                    if authManager.currentUser?.role == .admin {
                        adminSummary
                    }

                    // Welcome header
                    if let user = authManager.currentUser {
                        welcomeCard(user: user)
                    }

                    // Upcoming Events
                    upcomingEventsSection

                    // My Teams
                    myTeamsSection
                }
                .padding()
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Button { showSearch = true } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        NavigationLink {
                            NotificationsView()
                        } label: {
                            Image(systemName: "bell.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                SearchSheet()
            }
            .refreshable {
                await viewModel.load(user: authManager.currentUser, rolesManager: rolesManager, eventLimit: dashboardEventCount)
            }
            .task {
                await viewModel.load(user: authManager.currentUser, rolesManager: rolesManager, eventLimit: dashboardEventCount)
                if let user = authManager.currentUser, !rolesManager.isLoaded {
                    await rolesManager.detectRoles(userId: user.id, primaryRole: user.role)
                }
            }
        }
    }

    private func welcomeCard(user: User) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(user.first_name)
                    .font(.title2.bold())
            }
            Spacer()
            AvatarView(name: user.fullName, size: 48)
        }
        .cardStyle()
    }

    private var adminSummary: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if let org = authManager.currentOrganization {
                    StatCard(icon: "building.2", value: org.name, label: "Organization")
                    StatCard(icon: "sportscourt", value: "\(org.league_count ?? 0)", label: "Leagues")
                    StatCard(icon: "mappin", value: "\(org.field_count ?? 0)", label: "Fields")
                }
            }

            HStack(spacing: 12) {
                StatCard(icon: "person.3.fill", value: "\(viewModel.teams.count)", label: "Teams")
                StatCard(icon: "calendar", value: "\(viewModel.upcomingEvents.count)", label: "Upcoming")
            }
        }
    }

    private func quickStatsRow(org: Organization) -> some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "sportscourt",
                value: "\(org.league_count ?? 0)",
                label: "Leagues"
            )
            StatCard(
                icon: "person.3.fill",
                value: "\(viewModel.teams.count)",
                label: "Teams"
            )
            StatCard(
                icon: "calendar",
                value: "\(viewModel.upcomingEvents.count)",
                label: "Upcoming"
            )
        }
    }

    // MARK: - All available shortcuts

    private var allShortcuts: [ShortcutItem] {
        var items: [ShortcutItem] = []

        // Multi-role aware: show ALL applicable portals
        if rolesManager.isCoach || authManager.currentUser?.role == .coach {
            items.append(ShortcutItem(id: "coach_portal", icon: "megaphone.fill", title: "Coach Portal", color: .teal, destination: .coachPortal))
        }
        if rolesManager.isGuardian || authManager.currentUser?.role == .parent || authManager.currentUser?.role == .guardian {
            items.append(ShortcutItem(id: "parent_portal", icon: "person.2.fill", title: "Parent Portal", color: .teal, destination: .parentPortal))
            items.append(ShortcutItem(id: "register", icon: "person.badge.plus", title: "Register", color: .indigo, destination: .registration))
        }
        if authManager.currentUser?.role == .player {
            items.append(ShortcutItem(id: "player_portal", icon: "figure.run", title: "Player Portal", color: .orange, destination: .playerPortal))
        }

        // Commissioner/Admin management
        if authManager.currentUser?.role == .commissioner || authManager.currentUser?.role == .admin {
            items.append(ShortcutItem(id: "management", icon: "gearshape.2.fill", title: "Manage", color: .gray, destination: .management))
        }

        // Common shortcuts
        items += [
            ShortcutItem(id: "standings", icon: "list.number", title: "Standings", color: .blue, destination: .standings),
            ShortcutItem(id: "stats", icon: "chart.bar.fill", title: "Stats", color: .purple, destination: .stats),
            ShortcutItem(id: "fields", icon: "mappin.and.ellipse", title: "Fields", color: .mint, destination: .fields),
            ShortcutItem(id: "tournaments", icon: "trophy.fill", title: "Tournaments", color: .yellow, destination: .tournaments),
            ShortcutItem(id: "drafts", icon: "list.clipboard.fill", title: "Drafts", color: .cyan, destination: .drafts),
            ShortcutItem(id: "photos", icon: "photo.on.rectangle", title: "Photos", color: .green, destination: .photos),
            ShortcutItem(id: "payments", icon: "creditcard.fill", title: "Payments", color: .pink, destination: .payments),
            ShortcutItem(id: "sponsors", icon: "heart.fill", title: "Sponsors", color: .red, destination: .sponsors),
            ShortcutItem(id: "calendar", icon: "calendar.badge.clock", title: "Calendar", color: .orange, destination: .calendar),
        ]
        return items
    }

    private var visibleShortcuts: [ShortcutItem] {
        let hidden = hiddenIds
        let order = shortcutOrder
        let visible = allShortcuts.filter { !hidden.contains($0.id) }

        if order.isEmpty { return visible }

        // Sort by saved order, then append any new ones at the end
        var ordered: [ShortcutItem] = []
        for id in order {
            if let item = visible.first(where: { $0.id == id }) {
                ordered.append(item)
            }
        }
        // Add any items not in the saved order (new shortcuts)
        for item in visible where !order.contains(item.id) {
            ordered.append(item)
        }
        return ordered
    }

    private var quickActionsBar: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(visibleShortcuts) { item in
                        NavigationLink {
                            item.destinationView
                        } label: {
                            CompactActionChip(icon: item.icon, title: item.title, color: item.color)
                        }
                    }
                }
            }

            // Edit button (always visible at the trailing edge)
            Button { showEditShortcuts = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 64)
            }
        }
        .sheet(isPresented: $showEditShortcuts) {
            EditShortcutsSheet(
                allShortcuts: allShortcuts,
                initialOrder: shortcutOrder,
                initialHidden: hiddenIds,
                onSave: { order, hidden in
                    shortcutOrderString = order.joined(separator: ",")
                    hiddenShortcutsString = hidden.joined(separator: ",")
                }
            )
        }
    }

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Events")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    ScheduleView()
                }
                .font(.subheadline)
            }

            if viewModel.isLoading && viewModel.taggedEvents.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.taggedEvents.isEmpty {
                ContentUnavailableView(
                    "No Upcoming Events",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Check back when events are scheduled.")
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.taggedEvents) { tagged in
                        NavigationLink(value: tagged.event) {
                            VStack(spacing: 0) {
                                EventRowView(event: tagged.event)
                                // Role tags
                                if tagged.roles.count > 0 && !tagged.roles.contains(.league) {
                                    HStack(spacing: 6) {
                                        ForEach(Array(tagged.roles).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { role in
                                            HStack(spacing: 3) {
                                                Image(systemName: role.icon)
                                                    .font(.system(size: 9))
                                                Text(role.rawValue)
                                                    .font(.system(size: 10, weight: .medium))
                                            }
                                            .foregroundStyle(role.color)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(role.color.opacity(0.1))
                                            .clipShape(Capsule())
                                        }
                                        Spacer()
                                    }
                                    .padding(.leading, 76) // align with event title
                                    .padding(.top, 2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationDestination(for: ScheduledEvent.self) { event in
            EventDetailView(eventId: event.id)
        }
    }

    private var myTeamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Teams")
                .font(.headline)

            if viewModel.teams.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No Teams",
                    systemImage: "person.3",
                    description: Text("You're not on any teams yet.")
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.teams) { team in
                        NavigationLink(value: team) {
                            TeamRowView(team: team)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationDestination(for: Team.self) { team in
            TeamDetailView(teamId: team.id)
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

struct TeamRowView: View {
    let team: Team

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(String(team.name.prefix(2)).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(team.name)
                    .font(.subheadline.weight(.semibold))
                if let coach = team.coach {
                    Text("Coach: \(coach.fullName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let count = team.player_count {
                Label("\(count)", systemImage: "person.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct QuickActionLabel: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD))
    }
}

// MARK: - Shortcut Models

enum ShortcutDestination {
    case coachPortal, parentPortal, playerPortal, registration
    case standings, stats, fields, tournaments, drafts
    case photos, payments, sponsors, calendar
    case management
}

struct ShortcutItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let color: Color
    let destination: ShortcutDestination

    @MainActor @ViewBuilder
    var destinationView: some View {
        switch destination {
        case .coachPortal: CoachPortalView()
        case .parentPortal: ParentPortalView()
        case .playerPortal: PlayerPortalView()
        case .registration: RegistrationView()
        case .standings: StandingsView()
        case .stats: StatsView()
        case .fields: FieldsView()
        case .tournaments: TournamentsView()
        case .drafts: DraftListView()
        case .photos: PhotosView()
        case .payments: PaymentsView()
        case .sponsors: SponsorsView()
        case .calendar: CalendarSubscriptionsView()
        case .management: LeagueManagementView()
        }
    }
}

struct CompactActionChip: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.primary)
        }
        .frame(width: 72, height: 64)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM))
    }
}

// MARK: - Edit Shortcuts Sheet

struct EditShortcutsSheet: View {
    let allShortcuts: [ShortcutItem]
    let initialOrder: [String]
    let initialHidden: Set<String>
    let onSave: ([String], Set<String>) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var orderedItems: [ShortcutItem] = []
    @State private var hidden: Set<String> = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Drag to reorder. Toggle visibility with the eye icon.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Visible") {
                    ForEach(orderedItems.filter { !hidden.contains($0.id) }) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.title3)
                                .foregroundStyle(item.color)
                                .frame(width: 32)

                            Text(item.title)
                                .font(.subheadline)

                            Spacer()

                            Button {
                                hidden.insert(item.id)
                            } label: {
                                Image(systemName: "eye.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .onMove { from, to in
                        var visible = orderedItems.filter { !hidden.contains($0.id) }
                        visible.move(fromOffsets: from, toOffset: to)
                        // Rebuild full order: visible items in new order, then hidden
                        let hiddenItems = orderedItems.filter { hidden.contains($0.id) }
                        orderedItems = visible + hiddenItems
                    }
                }

                if !hidden.isEmpty {
                    Section("Hidden") {
                        ForEach(orderedItems.filter { hidden.contains($0.id) }) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.icon)
                                    .font(.title3)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 32)

                                Text(item.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Button {
                                    hidden.remove(item.id)
                                } label: {
                                    Image(systemName: "eye.slash")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Customize Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(orderedItems.map { $0.id }, hidden)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                hidden = initialHidden
                // Build ordered list from saved order
                if initialOrder.isEmpty {
                    orderedItems = allShortcuts
                } else {
                    var ordered: [ShortcutItem] = []
                    for id in initialOrder {
                        if let item = allShortcuts.first(where: { $0.id == id }) {
                            ordered.append(item)
                        }
                    }
                    for item in allShortcuts where !initialOrder.contains(item.id) {
                        ordered.append(item)
                    }
                    orderedItems = ordered
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environment(AuthManager())
}
