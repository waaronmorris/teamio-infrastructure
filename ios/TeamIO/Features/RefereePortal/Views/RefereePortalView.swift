import SwiftUI

// MARK: - View Model

@Observable
@MainActor
final class OfficiatingViewModel {
    var profile: RefereePortalResponse?
    var assignments: [GameAssignment] = []
    var availability: [RefereeAvailability] = []
    var blackouts: [RefereeBlackout] = []
    var upcomingGames: [ScheduledEvent] = []
    var isLoading = false
    var error: String?

    var refereeId: String? { profile?.referee_id }

    var pendingAssignments: [GameAssignment] {
        assignments.filter { $0.status == "assigned" }
    }

    var confirmedAssignments: [GameAssignment] {
        assignments.filter { $0.status == "confirmed" }
    }

    var completedAssignments: [GameAssignment] {
        assignments.filter { $0.status == "completed" }
    }

    var nextAssignment: GameAssignment? {
        (pendingAssignments + confirmedAssignments)
            .sorted { ($0.event_date ?? .distantFuture) < ($1.event_date ?? .distantFuture) }
            .first
    }

    var totalEarned: Double {
        Double(profile?.total_earned_cents ?? 0) / 100.0
    }

    var gamesThisMonth: Int {
        let cal = Calendar.current
        return assignments.filter { a in
            guard let date = a.event_date else { return false }
            return cal.isDate(date, equalTo: .now, toGranularity: .month)
        }.count
    }

    func load(userId: String) async {
        isLoading = true

        // Fetch referee profile
        do {
            profile = try await APIClient.shared.request(.refereePortal(userId))
        } catch {
            print("[Officiating] profile error: \(error)")
            isLoading = false
            return
        }

        guard let refId = refereeId else { isLoading = false; return }

        // Fetch assignments, availability, blackouts in parallel
        do {
            assignments = try await APIClient.shared.request(.refereeAssignments(refId))
        } catch {
            print("[Officiating] assignments error: \(error)")
        }

        do {
            availability = try await APIClient.shared.request(.refereeAvailability(refId))
        } catch {
            print("[Officiating] availability error: \(error)")
        }

        do {
            blackouts = try await APIClient.shared.request(.refereeBlackouts(refId))
        } catch {
            print("[Officiating] blackouts error: \(error)")
        }

        // Fetch upcoming games (for "available to ref" view)
        do {
            let resp: EventsResponse = try await APIClient.shared.request(
                .events(), queryItems: [URLQueryItem(name: "per_page", value: "50")]
            )
            upcomingGames = resp.events
                .filter { $0.isUpcoming && $0.isGame }
                .sorted { $0.start_time < $1.start_time }
        } catch {
            print("[Officiating] games error: \(error)")
        }

        isLoading = false
    }

    func respondToAssignment(_ id: String, accept: Bool) async {
        struct StatusUpdate: Encodable, Sendable { let status: String }
        guard let userId = profile?.user_id else { return }
        do {
            try await APIClient.shared.requestVoid(
                .updateAssignmentStatus(id),
                body: StatusUpdate(status: accept ? "confirmed" : "declined")
            )
            await load(userId: userId)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// Game assignment from the API
struct GameAssignment: Codable, Identifiable, Sendable {
    let id: String
    let referee_id: String
    let event_id: String
    let role: String?
    let status: String
    let notes: String?
    let pay_amount_cents: Int?
    let pay_status: String?
    let created_at: Date?

    // Joined event info (may not always be present)
    let event_date: Date?
    let event_title: String?

    var payDisplay: String {
        guard let cents = pay_amount_cents else { return "--" }
        return String(format: "$%.0f", Double(cents) / 100.0)
    }
}

// MARK: - Officiating Portal View

struct RefereePortalView: View {
    let refereeId: String
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = OfficiatingViewModel()
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedTab) {
                Text("Dashboard").tag(0)
                Text("My Games").tag(1)
                Text("Availability").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                switch selectedTab {
                case 0: dashboardTab
                case 1: gamesTab
                case 2: availabilityTab
                default: dashboardTab
                }
            }
        }
        .navigationTitle("Officiating")
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

    // MARK: - Dashboard Tab

    private var dashboardTab: some View {
        VStack(spacing: AppTheme.spacingLG) {
            // Stats
            HStack(spacing: 12) {
                StatCard(icon: "sportscourt.fill", value: "\(viewModel.confirmedAssignments.count + viewModel.pendingAssignments.count)", label: "Upcoming")
                StatCard(icon: "calendar", value: "\(viewModel.gamesThisMonth)", label: "This Month")
                StatCard(icon: "dollarsign.circle", value: String(format: "$%.0f", viewModel.totalEarned), label: "Earned")
            }

            // Certification
            if let profile = viewModel.profile {
                HStack {
                    Label("Certification", systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                    Spacer()
                    StatusBadge(text: profile.certification_level ?? "None", color: .purple)
                }
                .cardStyle()
            }

            // Next assignment
            if let next = viewModel.nextAssignment {
                nextAssignmentCard(next)
            }

            // Pending responses
            if !viewModel.pendingAssignments.isEmpty {
                pendingSection
            }

            // Recent completed
            if !viewModel.completedAssignments.isEmpty {
                completedSection
            }
        }
        .padding()
    }

    private func nextAssignmentCard(_ assignment: GameAssignment) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Image(systemName: "flag.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
                if let date = assignment.event_date, Calendar.current.isDateInToday(date) {
                    Text("TODAY")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
            }
            .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text("Next: \(assignment.event_title ?? "Game")")
                    .font(.subheadline.weight(.semibold))
                HStack {
                    if let date = assignment.event_date {
                        Label(date.shortDateTime, systemImage: "clock")
                    }
                    if let role = assignment.role {
                        StatusBadge(text: role.capitalized, color: .purple)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(assignment.payDisplay)
                .font(.headline)
                .foregroundStyle(.green)
        }
        .padding()
        .background(Color.purple.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Needs Response")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.pendingAssignments.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
            }

            ForEach(viewModel.pendingAssignments) { assignment in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(assignment.event_title ?? "Game")
                            .font(.subheadline.weight(.medium))
                        HStack {
                            if let date = assignment.event_date {
                                Text(date.shortDateTime)
                            }
                            Text(assignment.payDisplay)
                                .foregroundStyle(.green)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button {
                            Task { await viewModel.respondToAssignment(assignment.id, accept: true) }
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                        }
                        Button {
                            Task { await viewModel.respondToAssignment(assignment.id, accept: false) }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                        }
                    }
                }
                Divider()
            }
        }
        .cardStyle()
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed")
                .font(.headline)

            ForEach(viewModel.completedAssignments.prefix(5)) { assignment in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(assignment.event_title ?? "Game")
                            .font(.subheadline)
                        if let date = assignment.event_date {
                            Text(date.shortDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(assignment.payDisplay)
                        .font(.subheadline.weight(.bold))
                    StatusBadge(
                        text: assignment.pay_status?.capitalized ?? "Pending",
                        color: assignment.pay_status == "paid" ? .green : .orange
                    )
                }
                Divider()
            }
        }
        .cardStyle()
    }

    // MARK: - My Games Tab

    private var gamesTab: some View {
        VStack(spacing: AppTheme.spacingLG) {
            if viewModel.assignments.isEmpty {
                ContentUnavailableView(
                    "No Assignments",
                    systemImage: "flag.slash",
                    description: Text("You haven't been assigned to any games yet.")
                )
                .padding(.top, 40)
            } else {
                ForEach(viewModel.assignments.sorted(by: { ($0.event_date ?? .distantFuture) < ($1.event_date ?? .distantFuture) })) { assignment in
                    HStack(spacing: 12) {
                        // Status indicator
                        Circle()
                            .fill(statusColor(assignment.status))
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(assignment.event_title ?? "Game")
                                .font(.subheadline.weight(.medium))
                            HStack(spacing: 8) {
                                if let date = assignment.event_date {
                                    Text(date.shortDateTime)
                                }
                                if let role = assignment.role {
                                    Text(role.capitalized)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(assignment.payDisplay)
                                .font(.subheadline.weight(.bold))
                            StatusBadge(text: assignment.status.capitalized, color: statusColor(assignment.status))
                        }
                    }
                    .cardStyle()
                }
            }
        }
        .padding()
    }

    // MARK: - Availability Tab

    private var availabilityTab: some View {
        VStack(spacing: AppTheme.spacingLG) {
            // Weekly schedule
            VStack(alignment: .leading, spacing: 12) {
                Text("Weekly Availability")
                    .font(.headline)

                let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                ForEach(0..<7, id: \.self) { day in
                    let slot = viewModel.availability.first { $0.day_of_week == day }
                    HStack {
                        Text(days[day])
                            .font(.subheadline.weight(.medium))
                            .frame(width: 40, alignment: .leading)
                        if let slot {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text("\(slot.start_time) - \(slot.end_time)")
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                            }
                        } else {
                            Text("Not available")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                    if day < 6 { Divider() }
                }
            }
            .cardStyle()

            // Blackout dates
            VStack(alignment: .leading, spacing: 12) {
                Text("Blackout Dates")
                    .font(.headline)

                if viewModel.blackouts.isEmpty {
                    Text("No blackout dates set")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.blackouts) { blackout in
                        HStack {
                            Image(systemName: "calendar.badge.minus")
                                .foregroundStyle(.red)
                            Text(blackout.date.shortDate)
                                .font(.subheadline)
                            if let reason = blackout.reason {
                                Text("— \(reason)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        Divider()
                    }
                }
            }
            .cardStyle()

            // Upcoming games to claim
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Games")
                    .font(.headline)

                if viewModel.upcomingGames.isEmpty {
                    Text("You're all caught up! No games scheduled.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.upcomingGames.prefix(8)) { event in
                        HStack(spacing: 10) {
                            VStack(spacing: 2) {
                                Text(event.start_time.formatted(.dateTime.month(.abbreviated)))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(event.start_time.formatted(.dateTime.day()))
                                    .font(.title3.bold())
                            }
                            .frame(width: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.displayTitle)
                                    .font(.subheadline.weight(.medium))
                                HStack {
                                    Text(event.start_time.shortTime)
                                    if let field = event.field_name {
                                        Text("at \(field)")
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        if event.id != viewModel.upcomingGames.prefix(8).last?.id {
                            Divider()
                        }
                    }
                }
            }
            .cardStyle()
        }
        .padding()
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "confirmed": return .green
        case "assigned": return .orange
        case "completed": return .blue
        case "declined": return .red
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        RefereePortalView(refereeId: "test")
            .environment(AuthManager())
    }
}
