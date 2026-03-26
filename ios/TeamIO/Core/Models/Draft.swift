import Foundation

struct Draft: Codable, Identifiable, Sendable {
    let id: String
    let season_id: String?
    let name: String?
    let status: DraftStatus
    let draft_type: String?
    let current_round: Int?
    let current_pick: Int?
    let total_rounds: Int?
    let created_at: Date?
    let updated_at: Date?
}

enum DraftStatus: String, Codable, Sendable {
    case setup
    case in_progress
    case paused
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .setup: return "Setup"
        case .in_progress: return "In Progress"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var isLive: Bool {
        self == .in_progress || self == .paused
    }
}

struct DraftPick: Codable, Identifiable, Sendable {
    let id: String
    let draft_id: String
    let round: Int
    let pick_number: Int
    let team_id: String?
    let team_name: String?
    let player_id: String?
    let player_name: String?
    let is_skipped: Bool?
    let created_at: Date?
}

struct DraftTurn: Codable, Identifiable, Sendable {
    let id: String
    let draft_id: String
    let round: Int
    let pick_number: Int
    let team_id: String
    let team_name: String?
    let status: String
}

struct DraftPlayer: Codable, Identifiable, Sendable {
    let id: String
    let first_name: String?
    let last_name: String?
    let position: String?
    let jersey_number: String?
    let is_picked: Bool?

    var displayName: String {
        [first_name, last_name].compactMap { $0 }.joined(separator: " ")
    }
}

struct Tournament: Codable, Identifiable, Sendable {
    let id: String
    let season_id: String?
    let name: String
    let description: String?
    let bracket_type: String?
    let status: String?
    let team_count: Int?
    let round_count: Int?
    let created_at: Date?
    let updated_at: Date?
}

struct TournamentMatchup: Codable, Identifiable, Sendable {
    let id: String
    let bracket_id: String
    let round: Int
    let position: Int
    let team1_id: String?
    let team1_name: String?
    let team1_seed: Int?
    let team1_score: Int?
    let team2_id: String?
    let team2_name: String?
    let team2_seed: Int?
    let team2_score: Int?
    let winner_id: String?
    let status: String?
}

struct Sponsor: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let logo_url: String?
    let website_url: String?
    let description: String?
    let tier: String?
    let is_active: Bool
    let created_at: Date?
}

struct PaymentTransaction: Codable, Identifiable, Sendable {
    let id: String
    let provider: String?
    let amount_cents: Int?
    let currency: String?
    let status: String?
    let payer_name: String?
    let payer_email: String?
    let payment_method: String?
    let created_at: Date?

    var amountDisplay: String {
        guard let cents = amount_cents else { return "--" }
        let dollars = Double(cents) / 100.0
        return String(format: "$%.2f", dollars)
    }
}

struct Referee: Codable, Identifiable, Sendable {
    let id: String
    let user_id: String?
    let first_name: String?
    let last_name: String?
    let email: String?
    let phone: String?
    let certification_level: String?
    let is_active: Bool
    let created_at: Date?

    var fullName: String {
        [first_name, last_name].compactMap { $0 }.joined(separator: " ")
    }
}

struct RefereeAssignment: Codable, Identifiable, Sendable {
    let id: String
    let referee_id: String
    let event_id: String
    let position: String?
    let status: String
    let pay_amount: Double?
    let event_date: Date?
    let event_title: String?
    let created_at: Date?
}

struct RefereeAvailability: Codable, Identifiable, Sendable {
    let id: String
    let referee_id: String
    let day_of_week: Int
    let start_time: String
    let end_time: String
}

struct RefereeBlackout: Codable, Identifiable, Sendable {
    let id: String
    let referee_id: String
    let date: Date
    let reason: String?
}
