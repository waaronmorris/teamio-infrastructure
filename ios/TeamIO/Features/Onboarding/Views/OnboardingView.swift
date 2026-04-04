import SwiftUI

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingView: View {
    @Binding var hasCompleted: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sportscourt.fill",
            title: "Welcome to TeamIO",
            description: "The all-in-one platform for managing your sports leagues, teams, and events.",
            color: .accentColor
        ),
        OnboardingPage(
            icon: "calendar.badge.clock",
            title: "Stay on Schedule",
            description: "View game schedules, RSVP to events, track attendance, and get real-time updates on game day.",
            color: .blue
        ),
        OnboardingPage(
            icon: "person.3.fill",
            title: "Team Management",
            description: "Whether you coach, parent, referee, or play -- see everything in one place. Manage rosters, track stats, and stay connected.",
            color: .green
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            title: "Never Miss a Moment",
            description: "Get push notifications for schedule changes, messages, and important announcements.",
            color: .orange
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: page.icon)
                            .font(.system(size: 80))
                            .foregroundStyle(page.color)
                            .symbolEffect(.bounce, value: currentPage)

                        Text(page.title)
                            .font(.title.bold())
                            .multilineTextAlignment(.center)

                        Text(page.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            // Bottom buttons
            VStack(spacing: 12) {
                if currentPage == pages.count - 1 {
                    Button {
                        withAnimation {
                            hasCompleted = true
                        }
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        Text("Next")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        withAnimation {
                            hasCompleted = true
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    OnboardingView(hasCompleted: .constant(false))
}
