import Foundation

struct League: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let description: String?
    let sport: String?
    let status: LeagueStatus?
    let organization_id: String?
    let organization_name: String?
    let max_teams: Int?
    let min_players: Int?
    let max_players: Int?
    let team_count: Int?
    let division_count: Int?
    let booking_tier_id: String?
    let booking_tier_name: String?
    let commissioner: LeagueCommissioner?
    let active_season: LeagueActiveSeason?
    let registration_start: Date?
    let registration_end: Date?
    let season_start: Date?
    let season_end: Date?
    let created_at: Date?
    let updated_at: Date?
}

struct LeagueCommissioner: Codable, Sendable, Hashable {
    let id: String?
    let first_name: String?
    let last_name: String?
    let email: String?
}

struct LeagueActiveSeason: Codable, Sendable, Hashable {
    let id: String?
    let name: String?
    let status: String?
}

enum LeagueStatus: String, Codable, Sendable {
    case active
    case inactive
    case archived
    case draft
    case registration
    case closed
    case completed
}
