import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        Group {
            switch authManager.state {
            case .loading:
                LaunchView()
            case .unauthenticated:
                LoginView()
            case .authenticated:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.state)
    }
}

struct LaunchView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                AppLogo(size: 72)
                Text("TeamIO")
                    .font(.largeTitle.bold())
                ProgressView()
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
