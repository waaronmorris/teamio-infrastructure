import SwiftUI

@Observable
@MainActor
final class RefereePortalViewModel {
    var assignments: [RefereeAssignment] = []
    var availability: [RefereeAvailability] = []
    var blackouts: [RefereeBlackout] = []
    var isLoading = false
    var error: String?
    var selectedTab: RefTab = .dashboard

    enum RefTab: String, CaseIterable {
        case dashboard = "Dashboard"
        case availability = "Availability"
        case assignments = "Assignments"
    }

    var upcomingGames: Int {
        assignments.filter { $0.status == "confirmed" || $0.status == "assigned" }.count
    }

    var totalEarned: Double {
        assignments.filter { $0.status == "completed" }.compactMap { $0.pay_amount }.reduce(0, +)
    }

    func load(refereeId: String) async {
        isLoading = true
        do {
            async let assignTask: [RefereeAssignment] = APIClient.shared.request(.refereeAssignments(refereeId))
            async let availTask: [RefereeAvailability] = APIClient.shared.request(.refereeAvailability(refereeId))
            async let blackoutTask: [RefereeBlackout] = APIClient.shared.request(.refereeBlackouts(refereeId))

            self.assignments = try await assignTask
            self.availability = try await availTask
            self.blackouts = try await blackoutTask
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func respondToAssignment(_ id: String, accept: Bool, refereeId: String) async {
        struct StatusUpdate: Encodable, Sendable { let status: String }
        do {
            try await APIClient.shared.requestVoid(
                .updateAssignmentStatus(id),
                body: StatusUpdate(status: accept ? "confirmed" : "declined")
            )
            await load(refereeId: refereeId)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct RefereePortalView: View {
    let refereeId: String
    @State private var viewModel = RefereePortalViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $viewModel.selectedTab) {
                    ForEach(RefereePortalViewModel.RefTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    switch viewModel.selectedTab {
                    case .dashboard:
                        dashboardContent
                    case .availability:
                        availabilityContent
                    case .assignments:
                        assignmentsContent
                    }
                }
            }
            .navigationTitle("Referee Portal")
            .task { await viewModel.load(refereeId: refereeId) }
            .refreshable { await viewModel.load(refereeId: refereeId) }
        }
    }

    private var dashboardContent: some View {
        VStack(spacing: AppTheme.spacingLG) {
            HStack(spacing: 12) {
                StatCard(icon: "sportscourt.fill", value: "\(viewModel.upcomingGames)", label: "Upcoming")
                StatCard(icon: "dollarsign.circle", value: String(format: "$%.0f", viewModel.totalEarned), label: "Earned")
            }

            if let next = viewModel.assignments.first(where: { $0.status == "confirmed" || $0.status == "assigned" }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Assignment")
                        .font(.headline)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(next.event_title ?? "Game")
                                .font(.subheadline.weight(.medium))
                            if let date = next.event_date {
                                Text(date.shortDateTime)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let pos = next.position {
                            StatusBadge(text: pos, color: Color.accentColor)
                        }
                        if let pay = next.pay_amount {
                            Text(String(format: "$%.0f", pay))
                                .font(.subheadline.weight(.bold))
                        }
                    }
                }
                .cardStyle()
            }
        }
        .padding()
    }

    private var availabilityContent: some View {
        VStack(spacing: AppTheme.spacingLG) {
            VStack(alignment: .leading, spacing: 8) {
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
                            Text("\(slot.start_time) - \(slot.end_time)")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        } else {
                            Text("Unavailable")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    Divider()
                }
            }
            .cardStyle()

            VStack(alignment: .leading, spacing: 8) {
                Text("Blackout Dates")
                    .font(.headline)

                if viewModel.blackouts.isEmpty {
                    Text("No blackout dates set")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.blackouts) { blackout in
                        HStack {
                            Text(blackout.date.shortDate)
                                .font(.subheadline)
                            if let reason = blackout.reason {
                                Text("- \(reason)")
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
        }
        .padding()
    }

    private var assignmentsContent: some View {
        VStack(spacing: AppTheme.spacingMD) {
            if viewModel.assignments.isEmpty {
                ContentUnavailableView("No Assignments", systemImage: "megaphone", description: Text("No games assigned yet."))
            } else {
                ForEach(viewModel.assignments) { assignment in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(assignment.event_title ?? "Game")
                                .font(.subheadline.weight(.medium))
                            if let date = assignment.event_date {
                                Text(date.shortDateTime)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if let pos = assignment.position {
                            Text(pos)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let pay = assignment.pay_amount {
                            Text(String(format: "$%.0f", pay))
                                .font(.caption.weight(.bold))
                        }

                        StatusBadge(
                            text: assignment.status.capitalized,
                            color: assignment.status == "confirmed" ? .green : assignment.status == "assigned" ? .blue : .secondary
                        )

                        if assignment.status == "assigned" {
                            HStack(spacing: 4) {
                                Button {
                                    Task { await viewModel.respondToAssignment(assignment.id, accept: true, refereeId: refereeId) }
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                Button {
                                    Task { await viewModel.respondToAssignment(assignment.id, accept: false, refereeId: refereeId) }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    .cardStyle()
                }
            }
        }
        .padding()
    }
}

#Preview {
    RefereePortalView(refereeId: "test")
}
