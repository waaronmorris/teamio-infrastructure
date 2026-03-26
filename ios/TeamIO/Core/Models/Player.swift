import Foundation

struct Player: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let user_id: String?
    let team_id: String?
    let jersey_number: String?
    let position: String?
    let status: String?
    let first_name: String?
    let last_name: String?
    let date_of_birth: Date?
    let name: String?
    let joined_at: Date?
    let created_at: Date?
    let updated_at: Date?

    // Nested objects from roster endpoint
    let user: PlayerUser?
    let team: PlayerTeamRef?

    var displayName: String {
        if let name, !name.isEmpty { return name }
        if let f = first_name, let l = last_name, !f.isEmpty { return "\(f) \(l)" }
        if let userName = user?.first_name, let userLast = user?.last_name {
            return "\(userName) \(userLast)"
        }
        return "Unknown Player"
    }

    var jerseyDisplay: String? {
        guard let jersey_number, !jersey_number.isEmpty else { return nil }
        return "#\(jersey_number)"
    }

    var isActive: Bool {
        status == "active" || status == nil
    }
}

struct PlayerUser: Codable, Sendable, Hashable {
    let id: String?
    let first_name: String?
    let last_name: String?
    let email: String?
}

struct PlayerTeamRef: Codable, Sendable, Hashable {
    let id: String?
    let name: String?
}

struct PlayerStats: Codable, Identifiable, Sendable {
    let id: String
    let player_id: String
    let season_id: String?
    let stat_type: String?
    let stat_type_id: String?
    let value: Double
    let created_at: Date?
}

struct Guardian: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let user_id: String?
    let first_name: String?
    let last_name: String?
    let email: String?
    let phone: String?
    let relationship: String?
    let relationship_type: String?

    var fullName: String {
        [first_name, last_name].compactMap { $0 }.joined(separator: " ")
    }
}
