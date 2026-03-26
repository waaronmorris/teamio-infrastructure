import SwiftUI

struct SettingsView: View {
    @AppStorage("appearance") private var appearance: AppearanceMode = .system
    @AppStorage("haptics_enabled") private var hapticsEnabled = true
    @AppStorage("biometric_enabled") private var biometricEnabled = false
    @AppStorage("dashboardEventCount") private var dashboardEventCount = 10
    @State private var pushNotifications = PushNotificationManager.shared

    var body: some View {
        List {
            Section("Appearance") {
                Picker("Theme", selection: $appearance) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }

            Section("Security") {
                if BiometricAuthManager.shared.isAvailable {
                    Toggle(isOn: $biometricEnabled) {
                        Label(
                            "Unlock with \(BiometricAuthManager.shared.biometricName)",
                            systemImage: BiometricAuthManager.shared.biometricIcon
                        )
                    }
                }
            }

            Section("Notifications") {
                if pushNotifications.isAuthorized {
                    Label("Push Notifications Enabled", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button {
                        Task { await pushNotifications.requestPermission() }
                    } label: {
                        Label("Enable Push Notifications", systemImage: "bell.badge")
                    }
                }
            }

            Section("Dashboard") {
                Picker("Events on Home Screen", selection: $dashboardEventCount) {
                    Text("5").tag(5)
                    Text("10").tag(10)
                    Text("15").tag(15)
                    Text("20").tag(20)
                    Text("All").tag(50)
                }
            }

            Section("General") {
                Toggle("Haptic Feedback", isOn: $hapticsEnabled)
            }

            Section("Data") {
                Button(role: .destructive) {
                    clearCache()
                } label: {
                    Label("Clear Cache", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await pushNotifications.checkStatus()
        }
    }

    private func clearCache() {
        URLCache.shared.removeAllCachedResponses()
    }
}

enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
