import SwiftUI

struct EventRowView: View {
    let event: ScheduledEvent

    var body: some View {
        HStack(spacing: 12) {
            // Date badge
            VStack(spacing: 2) {
                Text(event.start_time.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(event.start_time.formatted(.dateTime.day()))
                    .font(.title3.bold())
            }
            .frame(width: 44)

            // Event type icon
            Image(systemName: event.event_type.eventTypeIcon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(event.start_time.shortTime, systemImage: "clock")

                    if let fieldName = event.field_name {
                        Label(fieldName, systemImage: "mappin")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                if let score = event.scoreDisplay {
                    Text(score)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                }
            }

            Spacer()

            // Status
            StatusBadge(
                text: event.status.capitalized,
                color: event.status.eventStatusColor
            )
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        EventRowView(event: ScheduledEvent(
            id: "1",
            season_id: "s1",
            event_type: "game",
            title: nil,
            description: nil,
            notes: nil,
            start_time: .now.addingTimeInterval(3600),
            end_time: .now.addingTimeInterval(7200),
            field_id: "f1",
            field_name: "Main Field",
            home_team_id: "t1",
            home_team_name: "Tigers",
            away_team_id: "t2",
            away_team_name: "Lions",
            status: "scheduled",
            home_score: nil,
            away_score: nil,
            is_forfeit: false,
            is_inter_league: false,
            external_league_name: nil,
            external_team_name: nil,
            created_at: .now,
            updated_at: .now
        ))
    }
}
