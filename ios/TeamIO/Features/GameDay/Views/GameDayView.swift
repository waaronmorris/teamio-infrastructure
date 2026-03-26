import SwiftUI

@Observable
@MainActor
final class GameDayViewModel {
    var event: ScheduledEvent?
    var roster: [Player] = []
    var rsvps: [EventRsvp] = []
    var attendance: [AttendanceRecord] = []
    var isLoading = false
    var error: String?

    // Timer
    var timerSeconds: Int = 0
    var isTimerRunning = false
    var timerTask: Task<Void, Never>?

    // Scores
    var homeScore: Int = 0
    var awayScore: Int = 0

    var presentCount: Int {
        attendance.filter { $0.status == "present" }.count
    }

    var rsvpYesCount: Int {
        rsvps.filter { $0.status == "accepted" }.count
    }

    var rsvpNoCount: Int {
        rsvps.filter { $0.status == "declined" }.count
    }

    var timerDisplay: String {
        let minutes = timerSeconds / 60
        let seconds = timerSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func load(eventId: String) async {
        isLoading = true
        do {
            async let eventTask: ScheduledEvent = APIClient.shared.request(.event(eventId))
            async let rsvpTask: [EventRsvp] = APIClient.shared.request(.eventRsvps(eventId))
            async let attendanceTask: [AttendanceRecord] = APIClient.shared.request(.eventAttendance(eventId))

            let loadedEvent = try await eventTask
            self.event = loadedEvent
            self.rsvps = try await rsvpTask
            self.attendance = try await attendanceTask
            self.homeScore = loadedEvent.home_score ?? 0
            self.awayScore = loadedEvent.away_score ?? 0

            if let teamId = loadedEvent.home_team_id {
                self.roster = try await APIClient.shared.request(.teamRoster(teamId))
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func toggleTimer() {
        if isTimerRunning {
            timerTask?.cancel()
            timerTask = nil
            isTimerRunning = false
        } else {
            isTimerRunning = true
            timerTask = Task { @MainActor in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    if !Task.isCancelled {
                        timerSeconds += 1
                    }
                }
            }
        }
    }

    func resetTimer() {
        timerTask?.cancel()
        timerTask = nil
        isTimerRunning = false
        timerSeconds = 0
    }

    func toggleAttendance(playerId: String, eventId: String) async {
        let currentStatus = attendance.first(where: { $0.player_id == playerId })?.status
        let newStatus = currentStatus == "present" ? "absent" : "present"

        struct AttendanceRequest: Encodable, Sendable {
            let player_id: String
            let status: String
        }

        do {
            let request = AttendanceRequest(player_id: playerId, status: newStatus)
            let _: AttendanceRecord = try await APIClient.shared.request(
                .submitAttendance(eventId), body: request
            )
            await load(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct GameDayView: View {
    let eventId: String
    @State private var viewModel = GameDayViewModel()

    var body: some View {
        ScrollView {
            if let event = viewModel.event {
                VStack(spacing: AppTheme.spacingLG) {
                    liveBadge
                    timerSection
                    scoreSection(event)
                    quickStats
                    if let fieldName = event.field_name {
                        locationCard(fieldName: fieldName)
                    }
                    rosterCheckIn
                }
                .padding()
            } else if viewModel.isLoading {
                ProgressView("Loading game...")
                    .padding(.top, 100)
            }
        }
        .navigationTitle("Game Day")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.load(eventId: eventId)
        }
        .task {
            await viewModel.load(eventId: eventId)
        }
    }

    private var liveBadge: some View {
        HStack {
            Spacer()
            if viewModel.isTimerRunning {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.red.opacity(0.1))
                .clipShape(Capsule())
            }
            Spacer()
        }
    }

    private var timerSection: some View {
        VStack(spacing: 16) {
            Text(viewModel.timerDisplay)
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .contentTransition(.numericText())

            HStack(spacing: 20) {
                Button {
                    viewModel.resetTimer()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.toggleTimer()
                } label: {
                    Image(systemName: viewModel.isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .frame(width: 70, height: 70)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())

                Button {
                    // Lap / period marker
                } label: {
                    Image(systemName: "flag.fill")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func scoreSection(_ event: ScheduledEvent) -> some View {
        HStack(spacing: 0) {
            // Home team
            VStack(spacing: 8) {
                Text(event.home_team_name ?? "Home")
                    .font(.headline)
                    .lineLimit(1)
                Text("\(viewModel.homeScore)")
                    .font(.system(size: 56, weight: .bold))

                HStack(spacing: 16) {
                    Button {
                        if viewModel.homeScore > 0 { viewModel.homeScore -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                    }
                    Button {
                        viewModel.homeScore += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Text("vs")
                .font(.title3)
                .foregroundStyle(.secondary)

            // Away team
            VStack(spacing: 8) {
                Text(event.away_team_name ?? "Away")
                    .font(.headline)
                    .lineLimit(1)
                Text("\(viewModel.awayScore)")
                    .font(.system(size: 56, weight: .bold))

                HStack(spacing: 16) {
                    Button {
                        if viewModel.awayScore > 0 { viewModel.awayScore -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                    }
                    Button {
                        viewModel.awayScore += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .cardStyle()
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            StatCard(icon: "checkmark.circle.fill", value: "\(viewModel.presentCount)", label: "Present")
            StatCard(icon: "hand.thumbsup.fill", value: "\(viewModel.rsvpYesCount)", label: "RSVP'd Yes")
            StatCard(icon: "hand.thumbsdown.fill", value: "\(viewModel.rsvpNoCount)", label: "RSVP'd No")
        }
    }

    private func locationCard(fieldName: String) -> some View {
        Button {
            let query = fieldName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fieldName
            if let url = URL(string: "maps://?q=\(query)") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(fieldName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text("Tap for directions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(Color.accentColor)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var rosterCheckIn: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Roster Check-In")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.presentCount)/\(viewModel.roster.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 8) {
                ForEach(viewModel.roster) { player in
                    let isPresent = viewModel.attendance.contains { $0.player_id == player.id && $0.status == "present" }
                    Button {
                        Task {
                            await viewModel.toggleAttendance(playerId: player.id, eventId: eventId)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(player.jerseyDisplay ?? "--")
                                .font(.headline.monospacedDigit())
                            Text(player.displayName)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isPresent ? Color.green.opacity(0.15) : Color(.secondarySystemBackground))
                        .foregroundStyle(isPresent ? .green : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSM))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusSM)
                                .stroke(isPresent ? Color.green : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        GameDayView(eventId: "test")
    }
}
