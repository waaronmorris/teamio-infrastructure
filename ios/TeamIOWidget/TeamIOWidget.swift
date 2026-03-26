import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct EventEntry: TimelineEntry {
    let date: Date
    let events: [WidgetEvent]
}

struct WidgetEvent: Identifiable {
    let id: String
    let title: String
    let time: Date
    let eventType: String
    let fieldName: String?
}

// MARK: - Provider

struct EventProvider: TimelineProvider {
    func placeholder(in context: Context) -> EventEntry {
        EventEntry(date: .now, events: [
            WidgetEvent(id: "1", title: "Tigers vs Lions", time: .now.addingTimeInterval(3600), eventType: "game", fieldName: "Main Field"),
            WidgetEvent(id: "2", title: "Practice", time: .now.addingTimeInterval(86400), eventType: "practice", fieldName: "Field B"),
            WidgetEvent(id: "3", title: "Team Meeting", time: .now.addingTimeInterval(172800), eventType: "meeting", fieldName: nil),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (EventEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EventEntry>) -> Void) {
        // In a real implementation, fetch from shared UserDefaults or API
        let entry = placeholder(in: context)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views

struct TeamIOWidgetEntryView: View {
    var entry: EventProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            mediumWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sportscourt.fill")
                    .foregroundStyle(Color.accentColor)
                Text("TeamIO")
                    .font(.caption.bold())
            }

            if let event = entry.events.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Text(event.time, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let field = event.fieldName {
                        Label(field, systemImage: "mappin")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } else {
                Text("No upcoming events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding()
    }

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sportscourt.fill")
                    .foregroundStyle(Color.accentColor)
                Text("Upcoming Events")
                    .font(.subheadline.bold())
                Spacer()
                Text("TeamIO")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if entry.events.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("No upcoming events")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.events.prefix(3)) { event in
                    HStack(spacing: 8) {
                        Image(systemName: iconForType(event.eventType))
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(event.title)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                            HStack(spacing: 4) {
                                Text(event.time, style: .relative)
                                if let field = event.fieldName {
                                    Text("at \(field)")
                                }
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "game": return "sportscourt.fill"
        case "practice": return "figure.run"
        case "meeting": return "person.3.fill"
        case "tournament": return "trophy.fill"
        default: return "calendar"
        }
    }
}

// MARK: - Widget Configuration

struct TeamIOWidget: Widget {
    let kind: String = "TeamIOWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EventProvider()) { entry in
            TeamIOWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Upcoming Events")
        .description("See your next games and practices at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    TeamIOWidget()
} timeline: {
    EventEntry(date: .now, events: [
        WidgetEvent(id: "1", title: "Tigers vs Lions", time: .now.addingTimeInterval(3600), eventType: "game", fieldName: "Main Field"),
        WidgetEvent(id: "2", title: "Practice", time: .now.addingTimeInterval(86400), eventType: "practice", fieldName: "Field B"),
        WidgetEvent(id: "3", title: "Team Meeting", time: .now.addingTimeInterval(172800), eventType: "meeting", fieldName: nil),
    ])
}
