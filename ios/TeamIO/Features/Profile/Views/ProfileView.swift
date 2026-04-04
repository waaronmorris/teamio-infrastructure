import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(UserRolesManager.self) private var rolesManager

    var body: some View {
        NavigationStack {
            List {
                // User info
                if let user = authManager.currentUser {
                    Section {
                        HStack(spacing: 16) {
                            AvatarView(name: user.fullName, size: 56)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.fullName)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                // Show all detected roles
                                HStack(spacing: 4) {
                                    StatusBadge(text: user.role.displayName, color: Color.accentColor)
                                    if rolesManager.isCoach && user.role != .coach {
                                        StatusBadge(text: "Coach", color: .teal)
                                    }
                                    if rolesManager.isGuardian && user.role != .parent && user.role != .guardian {
                                        StatusBadge(text: "Parent", color: .pink)
                                    }
                                    if rolesManager.isReferee {
                                        StatusBadge(text: "Referee", color: .purple)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // My Roles — auto-detected, with manual override for undetected
                if rolesManager.isLoaded {
                    Section("My Roles") {
                        // Show detected roles as confirmed
                        if rolesManager.isCoach {
                            Label("Coach", systemImage: "megaphone.fill")
                                .foregroundStyle(.teal)
                        }
                        if rolesManager.isGuardian {
                            Label("Parent", systemImage: "figure.2.and.child.holdinghands")
                                .foregroundStyle(.pink)
                        }
                        if rolesManager.isReferee {
                            Label("Referee", systemImage: "flag.fill")
                                .foregroundStyle(.purple)
                        }

                        // Only show toggles for roles NOT auto-detected
                        if !rolesManager.isCoach && authManager.currentUser?.role != .coach {
                            Toggle(isOn: Binding(
                                get: { rolesManager.isCoach },
                                set: { newVal in rolesManager.isCoach = newVal; saveRoles() }
                            )) {
                                Label("I'm also a Coach", systemImage: "megaphone.fill")
                            }
                        }
                        if !rolesManager.isGuardian && authManager.currentUser?.role != .parent && authManager.currentUser?.role != .guardian {
                            Toggle(isOn: Binding(
                                get: { rolesManager.isGuardian },
                                set: { newVal in rolesManager.isGuardian = newVal; saveRoles() }
                            )) {
                                Label("I'm also a Parent", systemImage: "figure.2.and.child.holdinghands")
                            }
                        }
                        if !rolesManager.isReferee {
                            Toggle(isOn: Binding(
                                get: { rolesManager.isReferee },
                                set: { newVal in rolesManager.isReferee = newVal; saveRoles() }
                            )) {
                                Label("I'm also a Referee", systemImage: "flag.fill")
                            }
                        }
                    }
                }

                // Organization
                if let org = authManager.currentOrganization {
                    Section("Organization") {
                        HStack {
                            Label(org.name, systemImage: org.org_type.icon)
                            Spacer()
                            NavigationLink("Switch") {
                                OrgSwitcherView()
                            }
                            .font(.subheadline)
                        }
                    }
                }

                // Settings
                Section("Settings") {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Preferences", systemImage: "gear")
                    }

                    NavigationLink {
                        NotificationsView()
                    } label: {
                        Label("Notifications", systemImage: "bell.badge")
                    }

                    NavigationLink {
                        CalendarSubscriptionsView()
                    } label: {
                        Label("Calendar Sync", systemImage: "calendar.badge.clock")
                    }
                }

                // Support
                Section("Support") {
                    Link(destination: URL(string: "https://getteamio.com/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    Link(destination: URL(string: "https://getteamio.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                }

                // Logout
                Section {
                    Button(role: .destructive) {
                        Task { await authManager.logout() }
                    } label: {
                        HStack {
                            Spacer()
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            Spacer()
                        }
                    }
                }

                // App info
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("TeamIO")
                                .font(.footnote.weight(.medium))
                            Text("Version 1.0.0")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Profile")
        }
    }

    private func saveRoles() {
        guard let userId = authManager.currentUser?.id else { return }
        var roles: [String] = []
        if rolesManager.isCoach && authManager.currentUser?.role != .coach { roles.append("coach") }
        if rolesManager.isGuardian && authManager.currentUser?.role != .parent && authManager.currentUser?.role != .guardian { roles.append("parent") }
        if rolesManager.isReferee { roles.append("referee") }
        UserRolesManager.saveAdditionalRoles(userId: userId, roles: roles)
    }
}

#Preview {
    ProfileView()
        .environment(AuthManager())
        .environment(UserRolesManager())
}
