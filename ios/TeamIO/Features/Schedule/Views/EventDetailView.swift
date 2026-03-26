import SwiftUI

@Observable
@MainActor
final class EventDetailViewModel {
    var event: ScheduledEvent?
    var rsvps: [EventRsvp] = []
    var duties: [EventDuty] = []
    var attendance: [AttendanceRecord] = []
    var isLoading = false
    var error: String?

    func load(eventId: String) async {
        isLoading = true
        error = nil

        do {
            async let eventTask: ScheduledEvent = APIClient.shared.request(.event(eventId))
            async let rsvpTask: [EventRsvp] = APIClient.shared.request(.eventRsvps(eventId))
            async let dutiesTask: [EventDuty] = APIClient.shared.request(.eventDuties(eventId))

            let (loadedEvent, loadedRsvps, loadedDuties) = try await (eventTask, rsvpTask, dutiesTask)
            self.event = loadedEvent
            self.rsvps = loadedRsvps
            self.duties = loadedDuties

            if loadedEvent.isPast || loadedEvent.status == "in_progress" {
                self.attendance = try await APIClient.shared.request(.eventAttendance(eventId))
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func submitRsvp(eventId: String, status: String, playerId: String?) async {
        let request = RsvpRequest(status: status, player_id: playerId, note: nil)
        do {
            let _: EventRsvp = try await APIClient.shared.request(.submitRsvp(eventId), body: request)
            await load(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct EventDetailView: View {
    let eventId: String
    @State private var viewModel = EventDetailViewModel()

    var body: some View {
        Group {
            if let event = viewModel.event {
                ScrollView {
                    VStack(spacing: AppTheme.spacingLG) {
                        eventHeader(event)
                        if event.isGame {
                            matchupCard(event)
                        }
                        detailsCard(event)
                        rsvpSection(event)
                        if !viewModel.duties.isEmpty {
                            dutiesSection
                        }
                        if !viewModel.attendance.isEmpty {
                            attendanceSection
                        }
                    }
                    .padding()
                }
            } else if viewModel.isLoading {
                ProgressView("Loading event...")
            } else if let error = viewModel.error {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            }
        }
        .navigationTitle(viewModel.event?.displayTitle ?? "Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let event = viewModel.event, event.isGame {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        GameDayView(eventId: event.id)
                    } label: {
                        Label("Game Day", systemImage: "sportscourt.fill")
                    }
                }
            }
        }
        .task {
            await viewModel.load(eventId: eventId)
        }
        .refreshable {
            await viewModel.load(eventId: eventId)
        }
    }

    // MARK: - Header

    private func eventHeader(_ event: ScheduledEvent) -> some View {
        VStack(spacing: 8) {
            Image(systemName: event.event_type.eventTypeIcon)
                .font(.system(size: 40))
                .foregroundStyle(Color.accentColor)

            Text(event.displayTitle)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            StatusBadge(text: event.status.capitalized, color: event.status.eventStatusColor)
        }
    }

    // MARK: - Matchup

    private func matchupCard(_ event: ScheduledEvent) -> some View {
        HStack {
            VStack(spacing: 4) {
                Text(event.home_team_name ?? "Home")
                    .font(.headline)
                if let score = event.home_score {
                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)

            Text("vs")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text(event.away_team_name ?? "Away")
                    .font(.headline)
                if let score = event.away_score {
                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .cardStyle()
    }

    // MARK: - Details

    private func detailsCard(_ event: ScheduledEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                VStack(alignment: .leading) {
                    Text(event.start_time.formatted(date: .long, time: .shortened))
                    Text("to \(event.end_time.formatted(date: .omitted, time: .shortened))")
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "clock")
                    .foregroundStyle(Color.accentColor)
            }

            if let fieldName = event.field_name {
                Label(fieldName, systemImage: "mappin.and.ellipse")
                    .foregroundStyle(.primary)
            }

            if let notes = event.notes, !notes.isEmpty {
                Divider()
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    // MARK: - RSVP

    private func rsvpSection(_ event: ScheduledEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RSVP")
                .font(.headline)

            HStack(spacing: 12) {
                rsvpButton("Going", status: "accepted", icon: "checkmark.circle.fill", color: .green)
                rsvpButton("Maybe", status: "tentative", icon: "questionmark.circle.fill", color: .orange)
                rsvpButton("Can't Go", status: "declined", icon: "xmark.circle.fill", color: .red)
            }

            if !viewModel.rsvps.isEmpty {
                Divider()
                ForEach(viewModel.rsvps) { rsvp in
                    HStack {
                        Image(systemName: rsvp.status.rsvpIcon)
                            .foregroundStyle(rsvp.status.rsvpColor)
                        Text(rsvp.displayName)
                            .font(.subheadline)
                        Spacer()
                        Text(rsvp.status.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func rsvpButton(_ label: String, status: String, icon: String, color: Color) -> some View {
        Button {
            Task {
                await viewModel.submitRsvp(eventId: eventId, status: status, playerId: nil)
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .tint(color)
    }

    // MARK: - Duties

    private var dutiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Volunteer Duties")
                .font(.headline)

            ForEach(viewModel.duties) { duty in
                HStack {
                    VStack(alignment: .leading) {
                        Text(duty.dutyDisplayName)
                            .font(.subheadline.weight(.medium))
                        if let assignee = duty.assigned_to {
                            Text(assignee)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    StatusBadge(
                        text: duty.status.capitalized,
                        color: duty.status == "completed" ? .green : duty.status == "assigned" ? .blue : .orange
                    )
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Attendance

    private var attendanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attendance")
                .font(.headline)

            ForEach(viewModel.attendance) { record in
                HStack {
                    Image(systemName: record.statusIcon)
                        .foregroundStyle(record.status == "present" ? .green : record.status == "absent" ? .red : .orange)
                    Text(record.player_id)
                        .font(.subheadline)
                    Spacer()
                    Text(record.status.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        EventDetailView(eventId: "test-id")
    }
}
