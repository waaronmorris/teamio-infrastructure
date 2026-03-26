import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct APIEndpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let requiresAuth: Bool

    init(_ path: String, method: HTTPMethod = .get, requiresAuth: Bool = true) {
        self.path = path
        self.method = method
        self.requiresAuth = requiresAuth
    }
}

// MARK: - Auth Endpoints

extension APIEndpoint {
    static func login() -> APIEndpoint {
        APIEndpoint("/auth/login", method: .post, requiresAuth: false)
    }

    static func register() -> APIEndpoint {
        APIEndpoint("/auth/register", method: .post, requiresAuth: false)
    }

    static func refreshToken() -> APIEndpoint {
        APIEndpoint("/auth/refresh", method: .post, requiresAuth: false)
    }

    static func logout() -> APIEndpoint {
        APIEndpoint("/auth/logout", method: .post)
    }

    static func me() -> APIEndpoint {
        APIEndpoint("/auth/me")
    }

    static func forgotPassword() -> APIEndpoint {
        APIEndpoint("/auth/forgot-password", method: .post, requiresAuth: false)
    }

    static func resetPassword() -> APIEndpoint {
        APIEndpoint("/auth/reset-password", method: .post, requiresAuth: false)
    }
}

// MARK: - Organization Endpoints

extension APIEndpoint {
    static func organizations() -> APIEndpoint {
        APIEndpoint("/organizations")
    }

    static func organization(_ id: String) -> APIEndpoint {
        APIEndpoint("/organizations/\(id)")
    }
}

// MARK: - League Endpoints

extension APIEndpoint {
    static func leagues() -> APIEndpoint {
        APIEndpoint("/leagues")
    }

    static func league(_ id: String) -> APIEndpoint {
        APIEndpoint("/leagues/\(id)")
    }
}

// MARK: - Season Endpoints

extension APIEndpoint {
    static func seasons() -> APIEndpoint {
        APIEndpoint("/seasons")
    }

    static func season(_ id: String) -> APIEndpoint {
        APIEndpoint("/seasons/\(id)")
    }
}

// MARK: - Team Endpoints

extension APIEndpoint {
    static func teams() -> APIEndpoint {
        APIEndpoint("/teams")
    }

    static func team(_ id: String) -> APIEndpoint {
        APIEndpoint("/teams/\(id)")
    }

    static func teamRoster(_ teamId: String) -> APIEndpoint {
        APIEndpoint("/teams/\(teamId)/roster")
    }
}

// MARK: - Player Endpoints

extension APIEndpoint {
    static func players() -> APIEndpoint {
        APIEndpoint("/players")
    }

    static func player(_ id: String) -> APIEndpoint {
        APIEndpoint("/players/\(id)")
    }

    static func playerGuardians(_ playerId: String) -> APIEndpoint {
        APIEndpoint("/players/\(playerId)/guardians")
    }
}

// MARK: - Schedule/Event Endpoints

extension APIEndpoint {
    static func events() -> APIEndpoint {
        APIEndpoint("/schedule/events")
    }

    static func event(_ id: String) -> APIEndpoint {
        APIEndpoint("/schedule/events/\(id)")
    }

    static func eventRsvps(_ eventId: String) -> APIEndpoint {
        APIEndpoint("/schedule/events/\(eventId)/rsvps")
    }

    static func submitRsvp(_ eventId: String) -> APIEndpoint {
        APIEndpoint("/schedule/events/\(eventId)/rsvps", method: .post)
    }

    static func eventDuties(_ eventId: String) -> APIEndpoint {
        APIEndpoint("/schedule/events/\(eventId)/duties")
    }

    static func eventAttendance(_ eventId: String) -> APIEndpoint {
        APIEndpoint("/schedule/events/\(eventId)/attendance")
    }
}

// MARK: - Field Endpoints

extension APIEndpoint {
    static func fields() -> APIEndpoint {
        APIEndpoint("/fields")
    }

    static func field(_ id: String) -> APIEndpoint {
        APIEndpoint("/fields/\(id)")
    }
}

// MARK: - Division Endpoints

extension APIEndpoint {
    static func divisions() -> APIEndpoint {
        APIEndpoint("/divisions")
    }

    static func division(_ id: String) -> APIEndpoint {
        APIEndpoint("/divisions/\(id)")
    }
}

// MARK: - Message Endpoints

extension APIEndpoint {
    static func sendMessage() -> APIEndpoint {
        APIEndpoint("/messages", method: .post)
    }

    static func inbox(_ userId: String) -> APIEndpoint {
        APIEndpoint("/users/\(userId)/inbox")
    }

    static func conversations(_ userId: String) -> APIEndpoint {
        APIEndpoint("/users/\(userId)/conversations")
    }

    static func conversationMessages(_ conversationId: String) -> APIEndpoint {
        APIEndpoint("/conversations/\(conversationId)/messages")
    }
}

// MARK: - Broadcast Endpoints

extension APIEndpoint {
    static func broadcasts() -> APIEndpoint {
        APIEndpoint("/broadcasts")
    }

    static func sendBroadcast() -> APIEndpoint {
        APIEndpoint("/broadcasts", method: .post)
    }
}

// MARK: - Registration Endpoints

extension APIEndpoint {
    static func registrations() -> APIEndpoint {
        APIEndpoint("/registrations")
    }

    static func registration(_ id: String) -> APIEndpoint {
        APIEndpoint("/registrations/\(id)")
    }
}

// MARK: - Portal Endpoints

extension APIEndpoint {
    static func parentPortal(_ userId: String) -> APIEndpoint {
        APIEndpoint("/users/\(userId)/parent-portal")
    }

    static func playerPortal(_ userId: String) -> APIEndpoint {
        APIEndpoint("/users/\(userId)/player-portal")
    }

    static func coachPortal(_ userId: String) -> APIEndpoint {
        APIEndpoint("/users/\(userId)/coach")
    }
}

// MARK: - Notification Endpoints

extension APIEndpoint {
    static func notifications() -> APIEndpoint {
        APIEndpoint("/notifications")
    }

    static func markNotificationRead(_ id: String) -> APIEndpoint {
        APIEndpoint("/notifications/\(id)/read", method: .put)
    }
}

// MARK: - Stats Endpoints

extension APIEndpoint {
    static func playerStats(_ playerId: String) -> APIEndpoint {
        APIEndpoint("/stats/players/\(playerId)")
    }

    static func statTypes() -> APIEndpoint {
        APIEndpoint("/stats/types")
    }

    static func leaderboard(seasonId: String, statTypeId: String) -> APIEndpoint {
        APIEndpoint("/stats/leaderboard/\(seasonId)/\(statTypeId)")
    }

    static func standings(seasonId: String) -> APIEndpoint {
        APIEndpoint("/stats/standings/\(seasonId)")
    }
}

// MARK: - Event Creation

extension APIEndpoint {
    static func createEvent() -> APIEndpoint {
        APIEndpoint("/schedule/events", method: .post)
    }

    static func submitAttendance(_ eventId: String) -> APIEndpoint {
        APIEndpoint("/schedule/events/\(eventId)/attendance", method: .post)
    }
}

// MARK: - Registration Creation

extension APIEndpoint {
    static func createRegistration() -> APIEndpoint {
        APIEndpoint("/registrations", method: .post)
    }
}

// MARK: - Photo Endpoints

extension APIEndpoint {
    static func photos() -> APIEndpoint {
        APIEndpoint("/photos")
    }

    static func photo(_ id: String) -> APIEndpoint {
        APIEndpoint("/photos/\(id)")
    }
}

// MARK: - Calendar Subscription Endpoints

extension APIEndpoint {
    static func calendarSubscriptions() -> APIEndpoint {
        APIEndpoint("/calendar/subscriptions")
    }

    static func createCalendarSubscription() -> APIEndpoint {
        APIEndpoint("/calendar/subscriptions", method: .post)
    }

    static func deleteCalendarSubscription(_ id: String) -> APIEndpoint {
        APIEndpoint("/calendar/subscriptions/\(id)", method: .delete)
    }

    static func regenerateCalendarToken(_ id: String) -> APIEndpoint {
        APIEndpoint("/calendar/subscriptions/\(id)/regenerate", method: .post)
    }
}

// MARK: - Mark All Notifications Read

extension APIEndpoint {
    static func markAllNotificationsRead() -> APIEndpoint {
        APIEndpoint("/notifications/read-all", method: .put)
    }
}

// MARK: - Draft Endpoints

extension APIEndpoint {
    static func drafts() -> APIEndpoint {
        APIEndpoint("/drafts")
    }

    static func draft(_ id: String) -> APIEndpoint {
        APIEndpoint("/drafts/\(id)")
    }

    static func draftPlayers(_ draftId: String) -> APIEndpoint {
        APIEndpoint("/drafts/\(draftId)/players")
    }

    static func draftPicks(_ draftId: String) -> APIEndpoint {
        APIEndpoint("/drafts/\(draftId)/picks")
    }

    static func draftTurns(_ draftId: String) -> APIEndpoint {
        APIEndpoint("/drafts/\(draftId)/turns")
    }

    static func makeDraftPick(_ draftId: String) -> APIEndpoint {
        APIEndpoint("/drafts/\(draftId)/picks", method: .post)
    }

    static func skipDraftTurn(_ draftId: String) -> APIEndpoint {
        APIEndpoint("/drafts/\(draftId)/skip", method: .post)
    }

    static func undoDraftPick(_ draftId: String) -> APIEndpoint {
        APIEndpoint("/drafts/\(draftId)/undo", method: .post)
    }

    static func pauseDraft(_ draftId: String) -> APIEndpoint {
        APIEndpoint("/drafts/\(draftId)/pause", method: .post)
    }

    static func resumeDraft(_ draftId: String) -> APIEndpoint {
        APIEndpoint("/drafts/\(draftId)/resume", method: .post)
    }
}

// MARK: - Tournament Endpoints

extension APIEndpoint {
    static func tournaments() -> APIEndpoint {
        APIEndpoint("/tournaments")
    }

    static func tournament(_ id: String) -> APIEndpoint {
        APIEndpoint("/tournaments/\(id)")
    }

    static func tournamentMatchups(_ bracketId: String) -> APIEndpoint {
        APIEndpoint("/tournaments/\(bracketId)/matchups")
    }
}

// MARK: - Referee Endpoints

extension APIEndpoint {
    static func refereeAssignments(_ refereeId: String) -> APIEndpoint {
        APIEndpoint("/referees/\(refereeId)/assignments")
    }

    static func refereeAvailability(_ refereeId: String) -> APIEndpoint {
        APIEndpoint("/referees/\(refereeId)/availability")
    }

    static func refereeBlackouts(_ refereeId: String) -> APIEndpoint {
        APIEndpoint("/referees/\(refereeId)/blackouts")
    }

    static func updateAssignmentStatus(_ assignmentId: String) -> APIEndpoint {
        APIEndpoint("/referee-assignments/\(assignmentId)/status", method: .put)
    }
}

// MARK: - Search Endpoints

extension APIEndpoint {
    static func searchUsers() -> APIEndpoint {
        APIEndpoint("/users")
    }
}

// MARK: - Payment Endpoints

extension APIEndpoint {
    static func payments() -> APIEndpoint {
        APIEndpoint("/payments")
    }
}

// MARK: - Sponsor Endpoints

extension APIEndpoint {
    static func sponsors() -> APIEndpoint {
        APIEndpoint("/sponsors")
    }
}

// MARK: - Referee List (Admin/Commissioner)

extension APIEndpoint {
    static func refereesList() -> APIEndpoint {
        APIEndpoint("/referees")
    }
}
