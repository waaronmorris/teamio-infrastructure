import Foundation

struct User: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let email: String
    let first_name: String
    let last_name: String
    let phone: String?
    let role: UserRole
    let is_active: Bool?
    let created_at: Date?
    let updated_at: Date?

    var fullName: String {
        "\(first_name) \(last_name)"
    }

    var initials: String {
        let f = first_name.prefix(1)
        let l = last_name.prefix(1)
        return "\(f)\(l)".uppercased()
    }
}

enum UserRole: String, Codable, Sendable, CaseIterable {
    case admin
    case commissioner
    case coach
    case player
    case parent
    case guardian

    var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .commissioner: return "Commissioner"
        case .coach: return "Coach"
        case .player: return "Player"
        case .parent: return "Parent"
        case .guardian: return "Guardian"
        }
    }

    var icon: String {
        switch self {
        case .admin: return "shield.fill"
        case .commissioner: return "crown.fill"
        case .coach: return "megaphone.fill"
        case .player: return "figure.run"
        case .parent, .guardian: return "person.2.fill"
        }
    }
}
