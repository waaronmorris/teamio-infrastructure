import Foundation

struct Season: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let league_id: String
    let league_name: String?
    let name: String
    let year: Int?
    let season_type: String?
    let status: SeasonStatus
    let registration_start: Date?
    let registration_end: Date?
    let draft_date: Date?
    let season_start: Date?
    let season_end: Date?
    let playoffs_start: Date?
    let draft_count: Int?
    let event_count: Int?
    let created_at: Date?
    let updated_at: Date?
}

enum SeasonStatus: String, Codable, Sendable {
    case planning
    case registration
    case registration_open
    case draft
    case in_progress
    case playoffs
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .planning: return "Planning"
        case .registration, .registration_open: return "Registration"
        case .draft: return "Draft"
        case .in_progress: return "In Progress"
        case .playoffs: return "Playoffs"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var isActive: Bool {
        switch self {
        case .in_progress, .playoffs: return true
        default: return false
        }
    }
}
