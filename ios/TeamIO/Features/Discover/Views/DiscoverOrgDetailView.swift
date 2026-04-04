import SwiftUI

struct DiscoverOrgDetailView: View {
    let org: DiscoverOrg
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @State private var joinResult: String?
    @State private var isJoining = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 64, height: 64)

                            if let url = org.logo_url, let imageURL = URL(string: url) {
                                AsyncImage(url: imageURL) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Image(systemName: "trophy.fill")
                                        .font(.title)
                                        .foregroundStyle(.accent)
                                }
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                Image(systemName: "trophy.fill")
                                    .font(.title)
                                    .foregroundStyle(.accent)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(org.name)
                                    .font(.title2.bold())
                                if org.is_verified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.accent)
                                }
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                    .font(.caption)
                                Text(org.locationDisplay)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    // Join button
                    Button {
                        Task { await handleJoin() }
                    } label: {
                        HStack {
                            if isJoining {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(org.allow_direct_join ? "Join \(org.name)" : "Request to Join")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isJoining || joinResult != nil)

                    if let result = joinResult {
                        Label(result, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }

                    // Description
                    if let desc = org.description, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.headline)
                            Text(desc)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)

                        if let sport = org.sport {
                            DetailRow(icon: "sportscourt", label: "Sport", value: sport)
                        }
                        if let level = org.competition_level {
                            DetailRow(icon: "chart.bar", label: "Level", value: level.capitalized)
                        }
                        DetailRow(
                            icon: "trophy",
                            label: "Leagues",
                            value: "\(org.league_count)"
                        )
                        if org.open_season_count > 0 {
                            DetailRow(
                                icon: "calendar.badge.clock",
                                label: "Open Registrations",
                                value: "\(org.open_season_count)"
                            )
                        }
                        DetailRow(
                            icon: "location",
                            label: "Distance",
                            value: String(format: "%.1f miles", org.distance_miles)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle(org.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func handleJoin() async {
        guard authManager.isAuthenticated else {
            // TODO: Navigate to login/register
            return
        }

        isJoining = true
        defer { isJoining = false }

        let vm = DiscoverViewModel()
        let role = authManager.currentUser?.role == "player" ? "player" : "parent"
        if let result = await vm.joinOrganization(orgId: org.id, role: role) {
            joinResult = result.message
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}
