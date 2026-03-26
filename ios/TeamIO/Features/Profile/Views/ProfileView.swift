import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var rolesManager = UserRolesManager()
    @AppStorage("activeViewMode") private var activeViewMode = "auto"

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
                                StatusBadge(text: user.role.displayName, color: Color.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // My Roles — let user declare additional roles and switch between them
                Section("My Roles") {
                    // Primary role (read-only)
                    HStack {
                        Label(authManager.currentUser?.role.displayName ?? "", systemImage: authManager.currentUser?.role.icon ?? "person")
                        Spacer()
                        Text("Primary")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Additional role toggles
                    if authManager.currentUser?.role != .coach {
                        Toggle(isOn: Binding(
                            get: { rolesManager.isCoach },
                            set: { newVal in
                                rolesManager.isCoach = newVal
                                saveRoles()
                            }
                        )) {
                            Label("I'm also a Coach", systemImage: "megaphone.fill")
                        }
                    }

                    if authManager.currentUser?.role != .parent && authManager.currentUser?.role != .guardian {
                        Toggle(isOn: Binding(
                            get: { rolesManager.isGuardian },
                            set: { newVal in
                                rolesManager.isGuardian = newVal
                                saveRoles()
                            }
                        )) {
                            Label("I'm also a Parent", systemImage: "figure.2.and.child.holdinghands")
                        }
                    }

                    Toggle(isOn: Binding(
                        get: { rolesManager.isReferee },
                        set: { newVal in
                            rolesManager.isReferee = newVal
                            saveRoles()
                        }
                    )) {
                        Label("I'm also a Referee", systemImage: "flag.fill")
                    }
                }

                // View mode switcher (always available for multi-role users)
                if rolesManager.isLoaded && rolesManager.hasMultipleRoles {
                    Section("Active View") {
                        Picker("Navigate as", selection: $activeViewMode) {
                            Text("\(authManager.currentUser?.role.displayName ?? "Auto")").tag("auto")
                            if rolesManager.isCoach && authManager.currentUser?.role != .coach {
                                Text("Coach").tag("coach")
                            }
                            if rolesManager.isGuardian && authManager.currentUser?.role != .parent && authManager.currentUser?.role != .guardian {
                                Text("Parent").tag("parent")
                            }
                        }

                        Text("Changes which portal appears in the tab bar and how data is filtered.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

                // Quick portal links
                Section("Portals") {
                    if rolesManager.isCoach {
                        NavigationLink {
                            CoachPortalView()
                        } label: {
                            Label("Coach Portal", systemImage: "megaphone.fill")
                        }
                    }
                    if rolesManager.isGuardian {
                        NavigationLink {
                            ParentPortalView()
                        } label: {
                            Label("Parent Portal", systemImage: "figure.2.and.child.holdinghands")
                        }
                    }
                    if authManager.currentUser?.role == .player {
                        NavigationLink {
                            PlayerPortalView()
                        } label: {
                            Label("Player Portal", systemImage: "figure.run")
                        }
                    }
                    NavigationLink {
                        MessagesView()
                    } label: {
                        Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
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
                        Task {
                            await authManager.logout()
                        }
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
            .task {
                if let user = authManager.currentUser, !rolesManager.isLoaded {
                    await rolesManager.detectRoles(userId: user.id, primaryRole: user.role)
                }
            }
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
}
