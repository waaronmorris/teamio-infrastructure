import SwiftUI

/// Commissioner/Admin management hub — the central place for league operations
struct LeagueManagementView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        NavigationStack {
            List {
                Section("Team Management") {
                    NavigationLink {
                        CoachAssignmentView()
                    } label: {
                        Label("Manage Coaches", systemImage: "megaphone.fill")
                        Text("Assign and change team coaches")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        RegistrationManagementView()
                    } label: {
                        Label("Registrations", systemImage: "person.badge.plus")
                        Text("Approve, reject, or waitlist players")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Officials") {
                    NavigationLink {
                        RefereeManagementView()
                    } label: {
                        Label("Manage Referees", systemImage: "flag.fill")
                        Text("View referees and assign to games")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Communication") {
                    NavigationLink {
                        ComposeMessageSheet()
                    } label: {
                        Label("Send Broadcast", systemImage: "megaphone")
                        Text("Announce to league, team, or individuals")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("League Operations") {
                    NavigationLink {
                        StandingsView()
                    } label: {
                        Label("Standings", systemImage: "list.number")
                    }

                    NavigationLink {
                        DraftListView()
                    } label: {
                        Label("Drafts", systemImage: "list.clipboard.fill")
                    }

                    NavigationLink {
                        TournamentsView()
                    } label: {
                        Label("Tournaments", systemImage: "trophy.fill")
                    }

                    NavigationLink {
                        FieldsView()
                    } label: {
                        Label("Fields", systemImage: "mappin.and.ellipse")
                    }
                }
            }
            .navigationTitle("League Management")
        }
    }
}

// MARK: - Coach Assignment View

@Observable
@MainActor
final class CoachAssignmentViewModel {
    var teams: [Team] = []
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        do {
            let resp: TeamsResponse = try await APIClient.shared.request(
                .teams(), queryItems: [URLQueryItem(name: "per_page", value: "50")]
            )
            teams = resp.teams.sorted { $0.name < $1.name }
        } catch {
            print("[CoachAssignment] error: \(error)")
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct CoachAssignmentView: View {
    @State private var viewModel = CoachAssignmentViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.teams.isEmpty {
                ProgressView("Loading teams...")
            } else {
                List(viewModel.teams) { team in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Text(String(team.name.prefix(2)).uppercased())
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.accentColor)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(team.name)
                                .font(.subheadline.weight(.semibold))
                            if let coach = team.coach {
                                Text("Coach: \(coach.fullName)")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else {
                                Text("No coach assigned")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }

                        Spacer()

                        if let count = team.player_count {
                            Text("\(count) players")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        NavigationLink {
                            TeamDetailView(teamId: team.id)
                        } label: {
                            EmptyView()
                        }
                        .frame(width: 0).opacity(0)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Coach Assignments")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }
}

// MARK: - Registration Management View

@Observable
@MainActor
final class RegistrationManagementViewModel {
    var registrations: [Registration] = []
    var isLoading = false
    var error: String?

    var pending: [Registration] { registrations.filter { $0.status == "pending" } }
    var approved: [Registration] { registrations.filter { $0.status == "approved" } }
    var rejected: [Registration] { registrations.filter { $0.status == "rejected" } }
    var waitlisted: [Registration] { registrations.filter { $0.status == "waitlisted" } }

    func load() async {
        isLoading = true
        do {
            let resp: RegistrationsResponse = try await APIClient.shared.request(
                .registrations(), queryItems: [URLQueryItem(name: "per_page", value: "100")]
            )
            registrations = resp.registrations
        } catch {
            print("[RegistrationMgmt] error: \(error)")
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func approve(_ id: String) async {
        do {
            try await APIClient.shared.requestVoid(.approveRegistration(id))
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func waitlist(_ id: String) async {
        do {
            try await APIClient.shared.requestVoid(.waitlistRegistration(id))
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func cancel(_ id: String) async {
        do {
            try await APIClient.shared.requestVoid(.cancelRegistration(id))
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func markPaid(_ id: String, method: String) async {
        struct PaymentUpdate: Encodable, Sendable {
            let payment_status: String
            let payment_method: String?
        }
        do {
            let body = PaymentUpdate(payment_status: "paid", payment_method: method)
            try await APIClient.shared.requestVoid(.updateRegistration(id), body: body)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func waiveFee(_ id: String) async {
        struct WaiveUpdate: Encodable, Sendable {
            let payment_status: String
        }
        do {
            let body = WaiveUpdate(payment_status: "waived")
            try await APIClient.shared.requestVoid(.updateRegistration(id), body: body)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct RegistrationManagementView: View {
    @State private var viewModel = RegistrationManagementViewModel()
    @State private var selectedFilter = "pending"

    private let filters = ["pending", "approved", "waitlisted", "rejected", "all"]

    private var displayedRegistrations: [Registration] {
        switch selectedFilter {
        case "pending": return viewModel.pending
        case "approved": return viewModel.approved
        case "rejected": return viewModel.rejected
        case "waitlisted": return viewModel.waitlisted
        default: return viewModel.registrations
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters, id: \.self) { filter in
                        let count: Int = {
                            switch filter {
                            case "pending": return viewModel.pending.count
                            case "approved": return viewModel.approved.count
                            case "rejected": return viewModel.rejected.count
                            case "waitlisted": return viewModel.waitlisted.count
                            default: return viewModel.registrations.count
                            }
                        }()

                        Button {
                            selectedFilter = filter
                        } label: {
                            Text("\(filter.capitalized) (\(count))")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedFilter == filter ? Color.accentColor : Color(.secondarySystemBackground))
                                .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            if viewModel.isLoading && viewModel.registrations.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if displayedRegistrations.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No \(selectedFilter.capitalized) Registrations",
                    systemImage: "person.badge.plus",
                    description: Text("Registrations will appear here.")
                )
                Spacer()
            } else {
                List(displayedRegistrations) { reg in
                    VStack(alignment: .leading, spacing: 8) {
                        // Player + status
                        HStack {
                            Text(reg.player_name ?? "Unknown Player")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            StatusBadge(text: reg.status.capitalized, color: reg.status.registrationStatusColor)
                        }

                        // Season + payment
                        HStack {
                            if let season = reg.season_name {
                                Label(season, systemImage: "calendar")
                            }
                            Spacer()
                            if let payment = reg.payment_status {
                                Label(payment.capitalized, systemImage: payment == "paid" ? "checkmark.circle.fill" : "clock")
                                    .foregroundStyle(payment == "paid" ? .green : .orange)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        // Waiver
                        if let waiver = reg.waiver_signed {
                            HStack {
                                Image(systemName: waiver ? "checkmark.seal.fill" : "xmark.seal")
                                    .foregroundStyle(waiver ? .green : .orange)
                                Text(waiver ? "Waiver signed" : "Waiver not signed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Action buttons (for pending registrations)
                        if reg.status == "pending" {
                            HStack(spacing: 10) {
                                Button {
                                    Task { await viewModel.approve(reg.id) }
                                } label: {
                                    Label("Approve", systemImage: "checkmark.circle.fill")
                                        .font(.caption.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)

                                Button {
                                    Task { await viewModel.waitlist(reg.id) }
                                } label: {
                                    Label("Waitlist", systemImage: "clock")
                                        .font(.caption.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.bordered)
                                .tint(.orange)

                                Button {
                                    Task { await viewModel.cancel(reg.id) }
                                } label: {
                                    Label("Reject", systemImage: "xmark.circle.fill")
                                        .font(.caption.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                        }

                        // Waitlisted: show approve option
                        if reg.status == "waitlisted" {
                            Button {
                                Task { await viewModel.approve(reg.id) }
                            } label: {
                                Label("Approve from Waitlist", systemImage: "checkmark.circle.fill")
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }

                        // Payment actions (for approved registrations with pending payment)
                        if reg.status == "approved" && reg.payment_status != "paid" && reg.payment_status != "waived" {
                            Divider()
                            Text("Record Payment")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                Button {
                                    Task { await viewModel.markPaid(reg.id, method: "cash") }
                                } label: {
                                    Label("Cash", systemImage: "banknote")
                                        .font(.caption.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.bordered)
                                .tint(.green)

                                Button {
                                    Task { await viewModel.markPaid(reg.id, method: "check") }
                                } label: {
                                    Label("Check", systemImage: "doc.text")
                                        .font(.caption.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.bordered)
                                .tint(.green)

                                Button {
                                    Task { await viewModel.waiveFee(reg.id) }
                                } label: {
                                    Label("Waive", systemImage: "hand.raised")
                                        .font(.caption.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.bordered)
                                .tint(.purple)
                            }
                        }

                        // Show payment method if already paid
                        if reg.payment_status == "waived" {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundStyle(.purple)
                                Text("Fee waived")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.purple)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Registrations")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }
}

// MARK: - Referee Management View

@Observable
@MainActor
final class RefereeManagementViewModel {
    var referees: [RefereeListItem] = []
    var upcomingGames: [ScheduledEvent] = []
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        do {
            let resp: RefereesResponse = try await APIClient.shared.request(.refereesList())
            referees = resp.referees
        } catch {
            print("[RefereeMgmt] referees error: \(error)")
        }

        do {
            let eventsResp: EventsResponse = try await APIClient.shared.request(
                .events(), queryItems: [URLQueryItem(name: "per_page", value: "100")]
            )
            upcomingGames = eventsResp.events
                .filter { $0.isUpcoming && $0.isGame }
                .sorted { $0.start_time < $1.start_time }
        } catch {
            print("[RefereeMgmt] events error: \(error)")
        }
        isLoading = false
    }
}

struct RefereeListItem: Decodable, Identifiable, Sendable {
    let id: String
    let user_id: String?
    let first_name: String?
    let last_name: String?
    let email: String?
    let phone: String?
    let certification_level: String?
    let is_active: Bool
    let sport: String?
    let created_at: Date?

    var fullName: String {
        [first_name, last_name].compactMap { $0 }.joined(separator: " ")
    }
}

struct RefereesResponse: Decodable, Sendable {
    let referees: [RefereeListItem]
    let pagination: PaginationInfo?
}

struct RefereeManagementView: View {
    @State private var viewModel = RefereeManagementViewModel()
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedTab) {
                Text("Referees").tag(0)
                Text("Unassigned Games").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                refereesList
            } else {
                unassignedGames
            }
        }
        .navigationTitle("Referee Management")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }

    private var refereesList: some View {
        Group {
            if viewModel.referees.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No Referees",
                    systemImage: "flag.fill",
                    description: Text("No referees have been registered yet.")
                )
            } else {
                List(viewModel.referees) { ref in
                    HStack(spacing: 12) {
                        AvatarView(name: ref.fullName, size: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(ref.fullName)
                                .font(.subheadline.weight(.semibold))
                            HStack(spacing: 8) {
                                if let cert = ref.certification_level {
                                    Text(cert)
                                }
                                if let email = ref.email {
                                    Text(email)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        StatusBadge(
                            text: ref.is_active ? "Active" : "Inactive",
                            color: ref.is_active ? .green : .red
                        )
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private var unassignedGames: some View {
        Group {
            if viewModel.upcomingGames.isEmpty {
                ContentUnavailableView(
                    "You're all caught up!",
                    systemImage: "calendar",
                    description: Text("No games need referee assignment right now.")
                )
            } else {
                List(viewModel.upcomingGames) { event in
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

                        // TODO: Add assign referee button when backend supports it
                        Image(systemName: "flag.badge.ellipsis")
                            .foregroundStyle(.orange)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

#Preview {
    LeagueManagementView()
        .environment(AuthManager())
}
