import Foundation

struct Field: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let organization_id: String?
    let name: String
    let address: String?
    let city: String?
    let state: String?
    let zip_code: String?
    let latitude: Double?
    let longitude: Double?
    let field_type: String?
    let surface_type: String?
    let has_lights: Bool?
    let has_restrooms: Bool?
    let has_parking: Bool?
    let is_active: Bool
    let created_at: Date?
    let updated_at: Date?

    var locationDisplay: String? {
        [address, city, state].compactMap { $0 }.joined(separator: ", ")
    }

    var amenities: [String] {
        var list: [String] = []
        if has_lights == true { list.append("Lights") }
        if has_restrooms == true { list.append("Restrooms") }
        if has_parking == true { list.append("Parking") }
        return list
    }
}
