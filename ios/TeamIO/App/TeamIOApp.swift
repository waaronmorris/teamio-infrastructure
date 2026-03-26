import SwiftUI

@main
struct TeamIOApp: App {
    @State private var authManager = AuthManager()
    @AppStorage("appearance") private var appearance: AppearanceMode = .system
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompleted: $hasCompletedOnboarding)
            } else {
                ContentView()
                    .environment(authManager)
                    .preferredColorScheme(appearance.colorScheme)
            }
        }
    }
}
