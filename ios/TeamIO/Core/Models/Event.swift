import Foundation

struct ScheduledEvent: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let season_id: String?
    let event_type: String
    let title: String?
    let description: String?
    let notes: String?
    let start_time: Date
    let end_time: Date
    let field_id: String?
    let field_name: String?
    let home_team_id: String?
    let home_team_name: String?
    let away_team_id: String?
    let away_team_name: String?
    let status: String
    let home_score: Int?
    let away_score: Int?
    let is_forfeit: Bool?
    let is_inter_league: Bool?
    let external_league_name: String?
    let external_team_name: String?
    let created_at: Date?
    let updated_at: Date?

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        if let home = home_team_name, let away = away_team_name {
            return "\(home) vs \(away)"
        }
        return event_type.capitalized
    }

    var scoreDisplay: String? {
        guard let home = home_score, let away = away_score else { return nil }
        return "\(home) - \(away)"
    }

    var isGame: Bool {
        event_type == "game" || event_type == "scrimmage"
    }

    var isUpcoming: Bool {
        start_time > Date.now && status == "scheduled"
    }

    var isPast: Bool {
        end_time < Date.now || status == "completed"
    }
}

struct EventRsvp: Codable, Identifiable, Sendable {
    let id: String
    let event_id: String
    let user_id: String
    let player_id: String?
    let status: String
    let note: String?
    let first_name: String?
    let last_name: String?
    let created_at: Date?

    var displayName: String {
        [first_name, last_name].compactMap { $0 }.joined(separator: " ")
    }
}

struct EventDuty: Codable, Identifiable, Sendable {
    let id: String
    let event_id: String
    let duty_type: String
    let assigned_to: String?
    let assigned_player_id: String?
    let status: String
    let notes: String?
    let created_at: Date?

    var dutyDisplayName: String {
        duty_type.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

struct AttendanceRecord: Codable, Identifiable, Sendable {
    let id: String
    let event_id: String
    let player_id: String
    let status: String
    let checked_in_at: Date?
    let notes: String?
    let created_at: Date?

    var statusIcon: String {
        switch status {
        case "present": return "checkmark.circle.fill"
        case "absent": return "xmark.circle.fill"
        case "late": return "clock.fill"
        case "excused": return "hand.raised.fill"
        default: return "questionmark.circle"
        }
    }
}

struct RsvpRequest: Encodable, Sendable {
    let status: String
    let player_id: String?
    let note: String?
}
