import Foundation

struct Division: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let league_id: String
    let league_name: String?
    let name: String
    let age_group: String?
    let min_age: Int?
    let max_age: Int?
    let skill_level: String?
    let gender: String?
    let sort_order: Int
    let is_active: Bool
    let team_count: Int?
    let created_at: Date?
    let updated_at: Date?

    var ageDisplay: String? {
        if let min = min_age, let max = max_age {
            return "Ages \(min)-\(max)"
        }
        return age_group
    }
}
