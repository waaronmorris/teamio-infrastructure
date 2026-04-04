import SwiftUI

struct MainTabView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(UserRolesManager.self) private var rolesManager
    @State private var selectedTab = 0
    @State private var showOrgPicker = false

    private var isConsumerUser: Bool {
        let role = authManager.currentUser?.role ?? ""
        return (role == "parent" || role == "player") && authManager.currentOrganization == nil
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            if isConsumerUser {
                DiscoverView()
                    .tabItem { Label("Discover", systemImage: "magnifyingglass") }
                    .tag(0)
            } else {
                DashboardView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)
            }

            ScheduleView()
                .tabItem { Label("Schedule", systemImage: "calendar") }
                .tag(1)

            if isConsumerUser {
                DiscoverView()
                    .tabItem { Label("Discover", systemImage: "magnifyingglass") }
                    .tag(2)
            } else {
                TeamsView()
                    .tabItem { Label("My Hub", systemImage: "square.grid.2x2.fill") }
                    .tag(2)
            }

            MessagesView()
                .tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(3)

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
        .environment(UserRolesManager())
}
