import Foundation

struct Team: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let league_id: String?
    let league_name: String?
    let season_id: String?
    let season_name: String?
    let division_id: String?
    let division_name: String?
    let name: String
    let color_primary: String?
    let color_secondary: String?
    let player_count: Int?
    let created_at: Date?
    let updated_at: Date?

    // Joined data from API
    let coach: TeamCoach?
    let captain: TeamCoach?
    let home_field: TeamField?
}

struct TeamCoach: Codable, Sendable, Hashable {
    let id: String?
    let user_id: String?
    let user_name: String?
    let user_email: String?
    let first_name: String?
    let last_name: String?
    let email: String?
    let certification_level: String?

    var fullName: String {
        if let name = user_name, !name.isEmpty { return name }
        return [first_name, last_name].compactMap { $0 }.joined(separator: " ")
    }
}

struct TeamField: Codable, Sendable, Hashable {
    let id: String
    let name: String
    let field_type: String?
}
