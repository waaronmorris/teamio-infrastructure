import SwiftUI

struct MainTabView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var selectedTab = 0
    @State private var showOrgPicker = false
    @State private var rolesManager = UserRolesManager()
    @AppStorage("activeViewMode") private var activeViewMode = "auto"

    /// The effective role for navigation — either auto-detected or user-chosen
    private var effectiveRole: UserRole {
        if activeViewMode != "auto", let override = UserRole(rawValue: activeViewMode) {
            return override
        }
        return authManager.currentUser?.role ?? .player
    }

    private var isManagementRole: Bool {
        effectiveRole == .commissioner || effectiveRole == .admin
    }

    /// Roles this user can switch between
    private var availableRoles: [UserRole] {
        var roles: [UserRole] = []
        if let primary = authManager.currentUser?.role {
            roles.append(primary)
        }
        if rolesManager.isCoach && authManager.currentUser?.role != .coach {
            roles.append(.coach)
        }
        if rolesManager.isGuardian && authManager.currentUser?.role != .parent && authManager.currentUser?.role != .guardian {
            roles.append(.parent)
        }
        return roles
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home (universal)
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            // Tab 2: Schedule (universal, label varies)
            ScheduleView()
                .tabItem { Label(scheduleLabel, systemImage: "calendar") }
                .tag(1)

            // Tab 3: Role-specific primary view
            tab3View
                .tabItem { Label(tab3Label, systemImage: tab3Icon) }
                .tag(2)

            // Tab 4: Messages or Manage
            tab4View
                .tabItem { Label(tab4Label, systemImage: tab4Icon) }
                .tag(3)

            // Tab 5: Profile (universal)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(4)
        }
        .tint(Color.accentColor)
        .onAppear { loadOrgContext() }
        .sheet(isPresented: $showOrgPicker) { OrgSwitcherView() }
        .task {
            if let user = authManager.currentUser, !rolesManager.isLoaded {
                await rolesManager.detectRoles(userId: user.id, primaryRole: user.role)
            }
        }
    }

    // MARK: - Tab 2

    private var scheduleLabel: String {
        effectiveRole == .parent || effectiveRole == .guardian ? "Calendar" : "Schedule"
    }

    // MARK: - Tab 3: Role Portal

    @ViewBuilder
    private var tab3View: some View {
        switch effectiveRole {
        case .coach: CoachPortalView()
        case .parent, .guardian: ParentPortalView()
        case .player: PlayerPortalView()
        case .commissioner, .admin: TeamsView()
        }
    }

    private var tab3Label: String {
        switch effectiveRole {
        case .coach: return "Coach"
        case .parent, .guardian: return "Family"
        case .player: return "My Team"
        case .commissioner: return "League"
        case .admin: return "Org"
        }
    }

    private var tab3Icon: String {
        switch effectiveRole {
        case .coach: return "megaphone.fill"
        case .parent, .guardian: return "figure.2.and.child.holdinghands"
        case .player: return "person.fill"
        case .commissioner, .admin: return "person.3.fill"
        }
    }

    // MARK: - Tab 4

    @ViewBuilder
    private var tab4View: some View {
        if isManagementRole {
            LeagueManagementView()
        } else {
            MessagesView()
        }
    }

    private var tab4Label: String {
        isManagementRole ? "Manage" : "Messages"
    }

    private var tab4Icon: String {
        isManagementRole ? "gearshape.2.fill" : "bubble.left.and.bubble.right.fill"
    }

    // MARK: - Org Context

    private func loadOrgContext() {
        if authManager.currentOrganization == nil {
            Task {
                do {
                    let response: OrganizationsResponse = try await APIClient.shared.request(.organizations())
                    let orgs = response.organizations
                    if let first = orgs.first {
                        await authManager.setOrganization(first)
                    }
                    if orgs.count > 1 {
                        showOrgPicker = true
                    }
                } catch {}
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthManager())
}
