import SwiftUI

@Observable
@MainActor
final class ParentPortalViewModel {
    var children: [ChildInfo] = []
    var registrations: [Registration] = []
    var upcomingEvents: [ScheduledEvent] = []
    var isLoading = false
    var error: String?

    var activeRegistrations: Int {
        registrations.filter { $0.status == "approved" }.count
    }

    var pendingRegistrations: Int {
        registrations.filter { $0.status == "pending" }.count
    }

    var paymentsDue: Int {
        registrations.filter { $0.payment_status == "pending" }.count
    }

    func load(userId: String) async {
        isLoading = true
        do {
            let portal: ParentDashboardResponse = try await APIClient.shared.request(.parentPortal(userId))
            self.children = portal.children ?? []
            self.registrations = portal.pending_registrations ?? []
            self.upcomingEvents = (portal.family_schedule ?? [])
                .filter { $0.isUpcoming }
                .sorted { $0.start_time < $1.start_time }
                .prefix(20)
                .map { $0 }
        } catch {
            print("[ParentPortal] decode error: \(error)")
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct ParentPortalView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = ParentPortalViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingLG) {
                    statsRow
                    myPlayersSection
                    registrationsSection
                    scheduleSection
                }
                .padding()
            }
            .navigationTitle("Parent Portal")
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

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(icon: "figure.run", value: "\(viewModel.children.count)", label: "My Players")
            StatCard(icon: "checkmark.seal.fill", value: "\(viewModel.activeRegistrations)", label: "Active")
            StatCard(icon: "clock.fill", value: "\(viewModel.pendingRegistrations)", label: "Pending")
            StatCard(icon: "dollarsign.circle", value: "\(viewModel.paymentsDue)", label: "Due")
        }
    }

    private var myPlayersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Players")
                .font(.headline)

            if viewModel.children.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No players yet",
                    systemImage: "person.badge.plus",
                    description: Text("Register a player to get started!")
                )
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.children) { child in
                        NavigationLink {
                            PlayerDetailView(playerId: child.player.id)
                        } label: {
                            ChildCard(child: child)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var registrationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Registrations")
                .font(.headline)

            if viewModel.registrations.isEmpty {
                Text("No registrations yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.registrations) { reg in
                        RegistrationRow(registration: reg)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Schedule")
                .font(.headline)

            if viewModel.upcomingEvents.isEmpty && !viewModel.isLoading {
                Text("You're all caught up! No events scheduled.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.upcomingEvents) { event in
                        NavigationLink {
                            EventDetailView(eventId: event.id)
                        } label: {
                            EventRowView(event: event)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct ChildCard: View {
    let child: ChildInfo

    var body: some View {
        VStack(spacing: 8) {
            AvatarView(name: child.player.name, size: 48)
            Text(child.player.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            if let jersey = child.player.jersey_number {
                Text("#\(jersey)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let team = child.teams.first {
                Text(team.name)
                    .font(.caption2)
                    .foregroundStyle(.pink)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

struct RegistrationRow: View {
    let registration: Registration

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(registration.player_name ?? "Player")
                    .font(.subheadline.weight(.medium))
                Text(registration.season_name ?? "Season")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(text: registration.status.capitalized, color: registration.status.registrationStatusColor)
                if let paymentStatus = registration.payment_status {
                    Text(paymentStatus.capitalized)
                        .font(.caption2)
                        .foregroundStyle(paymentStatus == "paid" ? .green : .orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ParentPortalView()
        .environment(AuthManager())
}
