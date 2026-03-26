import SwiftUI

@Observable
@MainActor
final class ScheduleViewModel {
    var taggedEvents: [TaggedEvent] = []
    var isLoading = false
    var error: String?
    var selectedFilter: EventFilter = .upcoming

    enum EventFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case past = "Past"
        case all = "All"
    }

    var filteredEvents: [TaggedEvent] {
        switch selectedFilter {
        case .upcoming:
            return taggedEvents.filter { $0.event.isUpcoming }.sorted { $0.event.start_time < $1.event.start_time }
        case .past:
            return taggedEvents.filter { $0.event.isPast }.sorted { $0.event.start_time > $1.event.start_time }
        case .all:
            return taggedEvents.sorted { $0.event.start_time < $1.event.start_time }
        }
    }

    var groupedEvents: [(String, [TaggedEvent])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"

        let grouped = Dictionary(grouping: filteredEvents) { tagged in
            if tagged.event.start_time.isToday { return "Today" }
            if tagged.event.start_time.isTomorrow { return "Tomorrow" }
            return formatter.string(from: tagged.event.start_time)
        }

        return grouped.sorted { lhs, rhs in
            guard let lhsDate = lhs.value.first?.event.start_time,
                  let rhsDate = rhs.value.first?.event.start_time else { return false }
            return selectedFilter == .past ? lhsDate > rhsDate : lhsDate < rhsDate
        }
    }

    func load(user: User?, coachedTeamIds: Set<String>, childrenTeamIds: Set<String>, playerTeamIds: Set<String>) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            let response: EventsResponse = try await APIClient.shared.request(
                .events(), queryItems: [URLQueryItem(name: "per_page", value: "200")]
            )

            let allMyTeamIds = coachedTeamIds.union(childrenTeamIds).union(playerTeamIds)
            let isAdmin = user?.role == .commissioner || user?.role == .admin

            var tagged: [TaggedEvent] = []
            for event in response.events {
                var roles: Set<EventRoleTag> = []

                if let h = event.home_team_id {
                    if coachedTeamIds.contains(h) { roles.insert(.coach) }
                    if childrenTeamIds.contains(h) { roles.insert(.parent) }
                    if playerTeamIds.contains(h) { roles.insert(.player) }
                }
                if let a = event.away_team_id {
                    if coachedTeamIds.contains(a) { roles.insert(.coach) }
                    if childrenTeamIds.contains(a) { roles.insert(.parent) }
                    if playerTeamIds.contains(a) { roles.insert(.player) }
                }
                if event.home_team_id == nil && event.away_team_id == nil {
                    roles.insert(.league)
                }

                if isAdmin {
                    if roles.isEmpty { roles.insert(.league) }
                    tagged.append(TaggedEvent(event: event, roles: roles))
                } else if !roles.isEmpty || allMyTeamIds.isEmpty {
                    tagged.append(TaggedEvent(event: event, roles: roles))
                }
            }

            self.taggedEvents = tagged
        } catch {
            print("[Schedule] decode error: \(error)")
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct ScheduleView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = ScheduleViewModel()
    @State private var rolesManager = UserRolesManager()

    /// Resolve team IDs per role for tagging
    private func loadTeamIds() async -> (coached: Set<String>, children: Set<String>, player: Set<String>) {
        guard let user = authManager.currentUser else { return ([], [], []) }
        var coached: Set<String> = []
        var children: Set<String> = []
        var player: Set<String> = []

        if user.role == .coach || rolesManager.isCoach {
            do {
                let resp: TeamsResponse = try await APIClient.shared.request(.teams(), queryItems: [URLQueryItem(name: "per_page", value: "50")])
                coached = Set(resp.teams.filter { $0.coach?.user_id == user.id }.map { $0.id })
            } catch {}
        }
        if user.role == .parent || user.role == .guardian {
            do {
                let portal: ParentDashboardResponse = try await APIClient.shared.request(.parentPortal(user.id))
                children = Set((portal.children ?? []).compactMap { $0.team_id })
            } catch {}
        }
        if user.role == .player {
            do {
                let portal: PlayerDashboardResponse = try await APIClient.shared.request(.playerPortal(user.id))
                player = Set((portal.teams ?? []).map { $0.id })
            } catch {}
        }
        return (coached, children, player)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filter", selection: $viewModel.selectedFilter) {
                    ForEach(ScheduleViewModel.EventFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if viewModel.isLoading && viewModel.taggedEvents.isEmpty {
                    Spacer()
                    ProgressView("Loading schedule...")
                    Spacer()
                } else if viewModel.filteredEvents.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Events",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("No \(viewModel.selectedFilter.rawValue.lowercased()) events found.")
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.groupedEvents, id: \.0) { section in
                            Section(section.0) {
                                ForEach(section.1) { tagged in
                                    NavigationLink(value: tagged.event) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            EventRowView(event: tagged.event)
                                            // Role tags
                                            if !tagged.roles.isEmpty && !tagged.roles.contains(.league) {
                                                HStack(spacing: 4) {
                                                    ForEach(Array(tagged.roles).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { role in
                                                        HStack(spacing: 2) {
                                                            Image(systemName: role.icon)
                                                                .font(.system(size: 8))
                                                            Text(role.rawValue)
                                                                .font(.system(size: 9, weight: .medium))
                                                        }
                                                        .foregroundStyle(role.color)
                                                        .padding(.horizontal, 5)
                                                        .padding(.vertical, 1)
                                                        .background(role.color.opacity(0.1))
                                                        .clipShape(Capsule())
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Schedule")
            .navigationDestination(for: ScheduledEvent.self) { event in
                EventDetailView(eventId: event.id)
            }
            .refreshable {
                let ids = await loadTeamIds()
                await viewModel.load(user: authManager.currentUser, coachedTeamIds: ids.coached, childrenTeamIds: ids.children, playerTeamIds: ids.player)
            }
            .task {
                if let user = authManager.currentUser, !rolesManager.isLoaded {
                    await rolesManager.detectRoles(userId: user.id, primaryRole: user.role)
                }
                let ids = await loadTeamIds()
                await viewModel.load(user: authManager.currentUser, coachedTeamIds: ids.coached, childrenTeamIds: ids.children, playerTeamIds: ids.player)
            }
        }
    }
}

#Preview {
    ScheduleView()
        .environment(AuthManager())
}
