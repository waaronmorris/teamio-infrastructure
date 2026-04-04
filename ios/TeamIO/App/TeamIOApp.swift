import SwiftUI

@main
struct TeamIOApp: App {
    @State private var authManager = AuthManager()
    @State private var rolesManager = UserRolesManager()
    @AppStorage("appearance") private var appearance: AppearanceMode = .system
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompleted: $hasCompletedOnboarding)
            } else {
                ContentView()
                    .environment(authManager)
                    .environment(rolesManager)
                    .preferredColorScheme(appearance.colorScheme)
            }
        }
    }
}
