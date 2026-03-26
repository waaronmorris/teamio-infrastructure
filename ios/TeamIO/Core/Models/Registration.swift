import Foundation

struct Registration: Codable, Identifiable, Sendable {
    let id: String
    let season_id: String
    let season_name: String?
    let player_id: String
    let player_name: String?
    let guardian_id: String?
    let guardian_name: String?
    let status: String
    let registration_type: String?
    let division_preference: String?
    let division_name: String?
    let team_preference: String?
    let team_name: String?
    let notes: String?
    let waiver_signed: Bool?
    let waiver_signed_at: Date?
    let payment_status: String?
    let payment_amount: String?
    let paid_amount: String?
    let paid_at: Date?
    let created_at: Date?
    let updated_at: Date?
}
