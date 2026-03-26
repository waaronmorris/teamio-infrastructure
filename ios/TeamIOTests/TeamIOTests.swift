import Testing
@testable import TeamIO

@Suite("Model Decoding")
struct ModelDecodingTests {
    @Test("User decodes from JSON")
    func userDecoding() throws {
        let json = """
        {
            "id": "123",
            "email": "test@example.com",
            "first_name": "John",
            "last_name": "Doe",
            "role": "coach",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder.api.decode(User.self, from: json)
        #expect(user.id == "123")
        #expect(user.email == "test@example.com")
        #expect(user.fullName == "John Doe")
        #expect(user.role == .coach)
    }

    @Test("ScheduledEvent decodes from JSON")
    func eventDecoding() throws {
        let json = """
        {
            "id": "evt-1",
            "season_id": "s1",
            "event_type": "game",
            "title": null,
            "description": null,
            "notes": null,
            "start_time": "2024-06-15T14:00:00Z",
            "end_time": "2024-06-15T16:00:00Z",
            "field_id": "f1",
            "field_name": "Main Field",
            "home_team_id": "t1",
            "home_team_name": "Tigers",
            "away_team_id": "t2",
            "away_team_name": "Lions",
            "status": "scheduled",
            "home_score": null,
            "away_score": null,
            "is_forfeit": false,
            "is_inter_league": false,
            "external_league_name": null,
            "external_team_name": null,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let event = try JSONDecoder.api.decode(ScheduledEvent.self, from: json)
        #expect(event.id == "evt-1")
        #expect(event.displayTitle == "Tigers vs Lions")
        #expect(event.isGame == true)
    }

    @Test("Team decodes from JSON")
    func teamDecoding() throws {
        let json = """
        {
            "id": "t1",
            "league_id": "l1",
            "season_id": "s1",
            "division_id": null,
            "name": "Tigers",
            "description": null,
            "coach_id": null,
            "captain_id": null,
            "home_field_id": null,
            "color_primary": "#FF6600",
            "color_secondary": null,
            "is_active": true,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z",
            "season_name": "Spring 2024",
            "players_count": 12,
            "coach": null,
            "home_field": null
        }
        """.data(using: .utf8)!

        let team = try JSONDecoder.api.decode(Team.self, from: json)
        #expect(team.id == "t1")
        #expect(team.name == "Tigers")
        #expect(team.players_count == 12)
    }
}
