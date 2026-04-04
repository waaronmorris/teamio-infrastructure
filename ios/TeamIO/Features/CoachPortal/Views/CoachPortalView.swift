import SwiftUI

@Observable
@MainActor
final class CoachPortalViewModel {
    var teams: [Team] = []
    var selectedTeamIndex: Int = 0
    var rosters: [String: [Player]] = [:] // teamId -> players
    var upcomingEvents: [ScheduledEvent] = []
    var recentResults: [ScheduledEvent] = []
    var seasons: [Season] = []
    var isLoading = false
    var error: String?
    var showSchedulePractice = false

    var selectedTeam: Team? {
        guard selectedTeamIndex < teams.count else { return nil }
        return teams[selectedTeamIndex]
    }

    var currentRoster: [Player] {
        guard let team = selectedTeam else { return [] }
        return rosters[team.id] ?? []
    }

    /// Events filtered to the currently selected team
    var selectedTeamUpcoming: [ScheduledEvent] {
        guard let teamId = selectedTeam?.id else { return upcomingEvents }
        return upcomingEvents.filter { event in
            event.home_team_id == teamId || event.away_team_id == teamId
        }
    }

    var selectedTeamResults: [ScheduledEvent] {
        guard let teamId = selectedTeam?.id else { return recentResults }
        return recentResults.filter { event in
            event.home_team_id == teamId || event.away_team_id == teamId
        }
    }

    var seasonRecord: (wins: Int, losses: Int, ties: Int) {
        var w = 0, l = 0, t = 0
        for event in selectedTeamResults {
            guard let home = event.home_score, let away = event.away_score else { continue }
            let isHome = event.home_team_id == selectedTeam?.id
            let myScore = isHome ? home : away
            let theirScore = isHome ? away : home
            if myScore > theirScore { w += 1 }
            else if myScore < theirScore { l += 1 }
            else { t += 1 }
        }
        return (w, l, t)
    }

    func resultForTeam(_ event: ScheduledEvent) -> String? {
        guard let home = event.home_score, let away = event.away_score else { return nil }
        let isHome = event.home_team_id == selectedTeam?.id
        let myScore = isHome ? home : away
        let theirScore = isHome ? away : home
        if myScore > theirScore { return "W" }
        else if myScore < theirScore { return "L" }
        else { return "T" }
    }

    func load(userId: String) async {
        isLoading = true
        error = nil

        // Fetch each resource independently so one failure doesn't block others
        var coachUserId = userId

        // 1. Coach profile
        do {
            let profile: CoachProfile = try await APIClient.shared.request(.coachPortal(userId))
            coachUserId = profile.user_id
        } catch {
            // Profile failed — use userId as fallback for team filtering
            print("[CoachPortal] Profile decode error: \(error)")
        }

        // 2. Teams
        do {
            let teamsResp: TeamsResponse = try await APIClient.shared.request(.teams(), queryItems: [URLQueryItem(name: "per_page", value: "50")])
            self.teams = teamsResp.teams.filter { $0.coach?.user_id == coachUserId }
        } catch {
            print("[CoachPortal] Teams decode error: \(error)")
        }

        // 3. Seasons
        do {
            let seasonsResp: SeasonsResponse = try await APIClient.shared.request(.seasons())
            self.seasons = seasonsResp.seasons
        } catch {
            print("[CoachPortal] Seasons decode error: \(error)")
        }

        // 4. Events
        do {
            let eventsResp: EventsResponse = try await APIClient.shared.request(.events(), queryItems: [URLQueryItem(name: "per_page", value: "200")])
            let myTeamIds = Set(teams.map { $0.id })
            let myEvents = eventsResp.events.filter { event in
                if let homeId = event.home_team_id, myTeamIds.contains(homeId) { return true }
                if let awayId = event.away_team_id, myTeamIds.contains(awayId) { return true }
                return false
            }
            self.upcomingEvents = myEvents
                .filter { $0.isUpcoming }
                .sorted { $0.start_time < $1.start_time }
            self.recentResults = myEvents
                .filter { $0.status == "completed" }
                .sorted { $0.start_time > $1.start_time }
        } catch {
            print("[CoachPortal] Events decode error: \(error)")
        }

        // 5. Rosters for each team
        await withTaskGroup(of: (String, [Player]).self) { group in
            for team in self.teams {
                group.addTask {
                    let roster: [Player] = (try? await APIClient.shared.request(.teamRoster(team.id))) ?? []
                    return (team.id, roster)
                }
            }
            for await (teamId, roster) in group {
                self.rosters[teamId] = roster
            }
        }

        clampSelection()
        isLoading = false
    }

    func selectTeam(at index: Int) {
        guard index < teams.count else { return }
        selectedTeamIndex = index
    }

    /// Ensure selectedTeamIndex is valid after data reload
    private func clampSelection() {
        if selectedTeamIndex >= teams.count {
            selectedTeamIndex = max(0, teams.count - 1)
        }
    }
}

struct CoachPortalView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = CoachPortalViewModel()
    @State private var showFullRoster = false
    @State private var showMessageCompose = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.teams.isEmpty && viewModel.upcomingEvents.isEmpty {
                    ProgressView("Loading...")
                } else {
                    mainContent
                }
            }
            .navigationTitle(viewModel.teams.count == 1 ? viewModel.teams.first?.name ?? "Coach Portal" : "Coach Portal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            viewModel.showSchedulePractice = true
                        } label: {
                            Label("Schedule Practice", systemImage: "figure.run")
                        }
                        Button {
                            showFullRoster = true
                        } label: {
                            Label("View Full Roster", systemImage: "person.3")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $showFullRoster) {
                if let team = viewModel.selectedTeam {
                    TeamDetailView(teamId: team.id)
                }
            }
            .sheet(isPresented: $viewModel.showSchedulePractice) {
                SchedulePracticeSheet(teams: viewModel.teams)
            }
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

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLG) {
                // Team selector (only if multiple teams)
                if viewModel.teams.count > 1 {
                    teamSelector
                }

                // Stats row
                statsRow

                // Quick action buttons
                quickActions

                // Next event callout
                if let nextEvent = viewModel.selectedTeamUpcoming.first {
                    nextEventCard(nextEvent)
                }

                // Roster
                rosterSection

                // Upcoming events
                upcomingSection

                // Recent results
                resultsSection
            }
            .padding()
        }
    }

    // MARK: - Team Selector

    private var teamSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(viewModel.teams.enumerated()), id: \.element.id) { index, team in
                    Button {
                        withAnimation { viewModel.selectTeam(at: index) }
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.accentColor.opacity(index == viewModel.selectedTeamIndex ? 1 : 0.2))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Text(String(team.name.prefix(2)).uppercased())
                                        .font(.caption2.bold())
                                        .foregroundStyle(index == viewModel.selectedTeamIndex ? .white : Color.accentColor)
                                }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(team.name)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(viewModel.rosters[team.id]?.count ?? 0) players")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            index == viewModel.selectedTeamIndex
                                ? Color.accentColor.opacity(0.1)
                                : Color(.secondarySystemBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                                .stroke(index == viewModel.selectedTeamIndex ? Color.accentColor : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(icon: "person.fill", value: "\(viewModel.currentRoster.count)", label: "Roster")
            StatCard(icon: "calendar", value: "\(viewModel.selectedTeamUpcoming.count)", label: "Upcoming")
            let record = viewModel.seasonRecord
            StatCard(icon: "trophy", value: "\(record.wins)-\(record.losses)-\(record.ties)", label: "Record")
        }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            // Message Team
            Button { showMessageCompose = true } label: {
                Label("Message Team", systemImage: "bubble.left.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(Color.accentColor)
            .sheet(isPresented: $showMessageCompose) {
                ComposeMessageSheet()
            }

            // Game Day (if next event is a game)
            if let next = viewModel.selectedTeamUpcoming.first, next.isGame {
                NavigationLink {
                    GameDayView(eventId: next.id)
                } label: {
                    Label("Game Day", systemImage: "sportscourt.fill")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Next Event Callout

    private func nextEventCard(_ event: ScheduledEvent) -> some View {
        NavigationLink {
            if event.isGame { GameDayView(eventId: event.id) }
            else { EventDetailView(eventId: event.id) }
        } label: {
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Image(systemName: event.event_type.eventTypeIcon)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    if event.start_time.isToday {
                        Text("TODAY")
                            .font(.caption2.bold())
                            .foregroundStyle(.red)
                    }
                }
                .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next: \(event.displayTitle)")
                        .font(.subheadline.weight(.semibold))
                    HStack {
                        Label(event.start_time.shortDateTime, systemImage: "clock")
                        if let field = event.field_name {
                            Label(field, systemImage: "mappin")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color.accentColor.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Roster

    private var rosterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Roster")
                    .font(.headline)
                Spacer()
                if let team = viewModel.selectedTeam {
                    Text(team.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.currentRoster.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.3")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("Roster is empty -- players will appear once added.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    Spacer()
                }
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.currentRoster) { player in
                        NavigationLink {
                            PlayerDetailView(playerId: player.id)
                        } label: {
                            HStack(spacing: 12) {
                                Text(player.jerseyDisplay ?? "--")
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.displayName)
                                        .font(.subheadline.weight(.medium))
                                    if let pos = player.position {
                                        Text(pos.capitalized)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 8)
                        if player.id != viewModel.currentRoster.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Upcoming Events

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Schedule")
                .font(.headline)

            if viewModel.selectedTeamUpcoming.isEmpty {
                HStack {
                    Spacer()
                    Text("You're all caught up! No events scheduled.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                    Spacer()
                }
            } else {
                ForEach(viewModel.selectedTeamUpcoming.prefix(8)) { event in
                    NavigationLink {
                        if event.isGame { GameDayView(eventId: event.id) }
                        else { EventDetailView(eventId: event.id) }
                    } label: {
                        HStack(spacing: 10) {
                            // Date column
                            VStack(spacing: 2) {
                                Text(event.start_time.formatted(.dateTime.month(.abbreviated)))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(event.start_time.formatted(.dateTime.day()))
                                    .font(.title3.bold())
                            }
                            .frame(width: 40)

                            Image(systemName: event.event_type.eventTypeIcon)
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.displayTitle)
                                    .font(.subheadline.weight(.medium))
                                HStack(spacing: 4) {
                                    Text(event.start_time.shortTime)
                                    if let field = event.field_name {
                                        Text("at \(field)")
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            StatusBadge(
                                text: event.event_type.capitalized,
                                color: event.isGame ? .blue : event.event_type == "practice" ? .green : .purple
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)

                    if event.id != viewModel.selectedTeamUpcoming.prefix(8).last?.id {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Recent Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Results")
                .font(.headline)

            if viewModel.selectedTeamResults.isEmpty {
                HStack {
                    Spacer()
                    Text("No results yet -- games are still being played!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                    Spacer()
                }
            } else {
                ForEach(viewModel.selectedTeamResults.prefix(5)) { event in
                    HStack(spacing: 10) {
                        // W/L/T badge
                        if let result = viewModel.resultForTeam(event) {
                            Text(result)
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 26)
                                .background(result == "W" ? .green : result == "L" ? .red : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }

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
                        if event.is_forfeit == true {
                            StatusBadge(text: "Forfeit", color: .red)
                        }
                    }
                    Divider()
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Schedule Practice Sheet

struct SchedulePracticeSheet: View {
    let teams: [Team]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTeamId: String = ""
    @State private var date = Date()
    @State private var duration: Int = 60
    @State private var notes = ""
    @State private var isSaving = false

    private let durations = [30, 45, 60, 90, 120]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    Picker("Team", selection: $selectedTeamId) {
                        Text("Select team").tag("")
                        ForEach(teams) { team in
                            Text(team.name).tag(team.id)
                        }
                    }
                    DatePicker("Date & Time", selection: $date, in: Date()...)
                    Picker("Duration", selection: $duration) {
                        ForEach(durations, id: \.self) { d in
                            Text("\(d) min").tag(d)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Schedule Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePractice() }
                        .disabled(selectedTeamId.isEmpty || isSaving)
                }
            }
        }
    }

    private func savePractice() {
        isSaving = true
        Task {
            struct CreateEventRequest: Encodable, Sendable {
                let event_type: String
                let home_team_id: String
                let start_time: Date
                let end_time: Date
                let notes: String?
            }
            let endTime = date.addingTimeInterval(Double(duration) * 60)
            let request = CreateEventRequest(
                event_type: "practice",
                home_team_id: selectedTeamId,
                start_time: date,
                end_time: endTime,
                notes: notes.isEmpty ? nil : notes
            )
            do {
                let _: ScheduledEvent = try await APIClient.shared.request(.createEvent(), body: request)
                dismiss()
            } catch {
                isSaving = false
            }
        }
    }
}

#Preview {
    CoachPortalView()
        .environment(AuthManager())
}
