import Foundation

// MARK: - Paginated List Wrappers
// The backend wraps all list endpoints in named containers

struct EventsResponse: Decodable, Sendable {
    let events: [ScheduledEvent]
    let pagination: PaginationInfo?
}

struct TeamsResponse: Decodable, Sendable {
    let teams: [Team]
    let pagination: PaginationInfo?
}

struct PlayersResponse: Decodable, Sendable {
    let players: [Player]
    let pagination: PaginationInfo?
}

struct OrganizationsResponse: Decodable, Sendable {
    let organizations: [Organization]
    let pagination: PaginationInfo?
}

struct LeaguesResponse: Decodable, Sendable {
    let leagues: [League]
    let pagination: PaginationInfo?
}

struct SeasonsResponse: Decodable, Sendable {
    let seasons: [Season]
    let pagination: PaginationInfo?
}

struct DivisionsResponse: Decodable, Sendable {
    let divisions: [Division]
    let pagination: PaginationInfo?
}

struct FieldsResponse: Decodable, Sendable {
    let fields: [Field]
    let pagination: PaginationInfo?
}

struct UsersResponse: Decodable, Sendable {
    let users: [User]
    let pagination: PaginationInfo?
}

struct SponsorsResponse: Decodable, Sendable {
    let sponsors: [Sponsor]
    let pagination: PaginationInfo?
}

struct PaymentsResponse: Decodable, Sendable {
    let transactions: [PaymentTransaction]
    let pagination: PaginationInfo?
}

struct PhotosResponse: Decodable, Sendable {
    let photos: [Photo]
    let pagination: PaginationInfo?
}

struct DraftsResponse: Decodable, Sendable {
    let drafts: [Draft]
    let pagination: PaginationInfo?
}

struct RegistrationsResponse: Decodable, Sendable {
    let registrations: [Registration]
    let total: Int?
    let page: Int?
    let per_page: Int?
    let total_pages: Int?
}

struct SubscriptionsResponse: Decodable, Sendable {
    let subscriptions: [CalendarSubscription]
}

struct InboxResponse: Decodable, Sendable {
    let messages: [InboxMessage]
    let unread_count: Int?
    let total: Int?
    let page: Int?
    let per_page: Int?
}

// MARK: - Portal Responses

struct ParentDashboardResponse: Decodable, Sendable {
    let guardian: Guardian?
    let children: [Player]?
    let family_schedule: [ScheduledEvent]?
    let pending_registrations: [Registration]?
    let unread_messages: Int?
}

struct PlayerDashboardResponse: Decodable, Sendable {
    let player: Player?
    let teams: [Team]?
    let upcoming_events: [ScheduledEvent]?
    let stats_summary: PlayerStatsSummary?
    let guardians: [Guardian]?
}

struct PlayerStatsSummary: Decodable, Sendable {
    let games_played: Int?
    let stats: [String: Double]?
}

struct CoachProfile: Decodable, Sendable {
    let id: String
    let user_id: String
    let user_name: String?
    let user_email: String?
    let certification_level: String?
    let years_experience: Int?
    let status: String?
    let team_count: Int?
    let created_at: Date?
    let updated_at: Date?
}

// MARK: - Pagination

struct PaginationInfo: Decodable, Sendable {
    let page: Int
    let per_page: Int
    let total: Int
    let total_pages: Int

    var hasNextPage: Bool {
        page < total_pages
    }
}

// MARK: - Generic Wrappers (unused, kept for reference)

struct APIResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let data: T
    let message: String?
}

// MARK: - Notification (no table exists yet, but used in UI)

struct Notification: Codable, Identifiable, Sendable {
    let id: String
    let user_id: String?
    let title: String?
    let body: String?
    let notification_type: String?
    let is_read: Bool
    let read_at: Date?
    let created_at: Date?
}
