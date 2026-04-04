import Foundation
import CoreLocation

struct DiscoverOrg: Codable, Identifiable {
    let id: String
    let name: String
    let slug: String
    let org_type: String
    let description: String?
    let city: String?
    let state: String?
    let sport: String?
    let age_groups: [String]?
    let competition_level: String?
    let logo_url: String?
    let primary_color: String?
    let is_verified: Bool
    let allow_direct_join: Bool
    let distance_miles: Double
    let league_count: Int
    let open_season_count: Int

    var locationDisplay: String {
        [city, state].compactMap { $0 }.joined(separator: ", ")
    }
}

struct DiscoverResponse: Codable {
    let organizations: [DiscoverOrg]
    let total: Int
    let page: Int
    let per_page: Int
}

struct GeoLocation: Codable {
    let zip_code: String
    let city: String
    let state: String
    let latitude: Double
    let longitude: Double
}

struct JoinRequestResponse: Codable {
    let id: String
    let status: String
    let message: String
}

@Observable
final class DiscoverViewModel {
    var organizations: [DiscoverOrg] = []
    var total = 0
    var isLoading = false
    var searchText = ""
    var selectedSport: String?
    var radiusMiles = 15
    var selectedOrgType: String?

    func search(latitude: Double, longitude: Double) async {
        isLoading = true
        defer { isLoading = false }

        var queryItems: [String: String] = [
            "latitude": String(latitude),
            "longitude": String(longitude),
            "radius_miles": String(radiusMiles),
        ]
        if let sport = selectedSport, !sport.isEmpty {
            queryItems["sport"] = sport
        }
        if let orgType = selectedOrgType, !orgType.isEmpty {
            queryItems["org_type"] = orgType
        }
        if !searchText.isEmpty {
            queryItems["search"] = searchText
        }

        let queryString = queryItems.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let endpoint = APIEndpoint("/discover/organizations?\(queryString)", requiresAuth: false)

        do {
            let response: DiscoverResponse = try await APIClient.shared.request(endpoint)
            organizations = response.organizations
            total = response.total
        } catch {
            organizations = []
            total = 0
        }
    }

    func geocodeZip(_ zip: String) async -> GeoLocation? {
        let endpoint = APIEndpoint("/geocode/zip/\(zip)", requiresAuth: false)
        return try? await APIClient.shared.request(endpoint)
    }

    func joinOrganization(orgId: String, role: String) async -> JoinRequestResponse? {
        let endpoint = APIEndpoint("/join-requests", method: .post)
        let body: [String: String] = [
            "organization_id": orgId,
            "role": role,
        ]
        return try? await APIClient.shared.request(endpoint, body: body)
    }
}
