import SwiftUI

@Observable
@MainActor
final class OrgSwitcherViewModel {
    var organizations: [Organization] = []
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        do {
            organizations = try await APIClient.shared.request(.organizations())
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct OrgSwitcherView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = OrgSwitcherViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading organizations...")
                } else if viewModel.organizations.isEmpty {
                    ContentUnavailableView(
                        "No Organizations",
                        systemImage: "building.2",
                        description: Text("You're not a member of any organizations yet.")
                    )
                } else {
                    List(viewModel.organizations) { org in
                        Button {
                            selectOrg(org)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: org.org_type.icon)
                                    .font(.title3)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(org.name)
                                        .font(.subheadline.weight(.semibold))
                                    if let location = org.locationDisplay {
                                        Text(location)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                if org.id == authManager.currentOrganization?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Select Organization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
        }
    }

    private func selectOrg(_ org: Organization) {
        Task {
            await authManager.setOrganization(org)
            dismiss()
        }
    }
}

#Preview {
    OrgSwitcherView()
        .environment(AuthManager())
}
