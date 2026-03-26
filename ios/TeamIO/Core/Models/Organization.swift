import Foundation

struct Organization: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let slug: String
    let org_type: OrgType
    let parent_id: String?
    let parent_name: String?
    let description: String?
    let address: String?
    let city: String?
    let state: String?
    let zip_code: String?
    let latitude: Double?
    let longitude: Double?
    let phone: String?
    let email: String?
    let website: String?
    let logo_url: String?
    let primary_color: String?
    let secondary_color: String?
    let sport: String?
    let competition_level: String?
    let seeking_opponents: Bool
    let seeking_tournaments: Bool
    let travel_radius_miles: Int?
    let is_active: Bool
    let is_verified: Bool
    let child_count: Int?
    let league_count: Int?
    let field_count: Int?
    let created_at: Date?
    let updated_at: Date?

    var locationDisplay: String? {
        [city, state].compactMap { $0 }.joined(separator: ", ")
    }
}

enum OrgType: String, Codable, Sendable, CaseIterable {
    case parks_rec
    case league_org
    case travel_team
    case tournament_org
    case club
    case school
    case `private`

    var displayName: String {
        switch self {
        case .parks_rec: return "Parks & Rec"
        case .league_org: return "League"
        case .travel_team: return "Travel Team"
        case .tournament_org: return "Tournament"
        case .club: return "Club"
        case .school: return "School"
        case .private: return "Private"
        }
    }

    var icon: String {
        switch self {
        case .parks_rec: return "leaf.fill"
        case .league_org: return "trophy.fill"
        case .travel_team: return "car.fill"
        case .tournament_org: return "trophy.fill"
        case .club: return "building.2.fill"
        case .school: return "graduationcap.fill"
        case .private: return "lock.fill"
        }
    }
}
