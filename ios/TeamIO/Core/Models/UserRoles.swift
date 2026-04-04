import Foundation

/// Manages the user's active roles. A single user can be a coach, parent, AND referee.
/// Detects roles automatically via backend endpoints + user self-declaration fallback.
@Observable
@MainActor
final class UserRolesManager {
    var isCoach = false
    var isGuardian = false
    var isReferee = false
    var refereeId: String?
    var isLoaded = false

    /// Auto-detect roles by probing backend endpoints
    func detectRoles(userId: String, primaryRole: UserRole) async {
        // Primary role is always set
        switch primaryRole {
        case .coach: isCoach = true
        case .parent, .guardian: isGuardian = true
        default: break
        }

        // Load self-declared additional roles
        let additional = UserDefaults.standard.stringArray(forKey: "additionalRoles_\(userId)") ?? []
        if additional.contains("coach") { isCoach = true }
        if additional.contains("parent") { isGuardian = true }
        if additional.contains("referee") { isReferee = true }

        // Auto-detect coach (if not already)
        if !isCoach {
            do {
                let _: CoachProfile = try await APIClient.shared.request(.coachPortal(userId))
                isCoach = true
            } catch {}
        }

        // Auto-detect guardian (parent portal now accessible to all roles)
        if !isGuardian {
            do {
                let portal: ParentDashboardResponse = try await APIClient.shared.request(.parentPortal(userId))
                if let children = portal.children, !children.isEmpty {
                    isGuardian = true
                }
            } catch {}
        }

        // Auto-detect referee via new endpoint
        if !isReferee {
            do {
                let ref_profile: RefereePortalResponse = try await APIClient.shared.request(.refereePortal(userId))
                isReferee = true
                refereeId = ref_profile.referee_id
            } catch {}
        }

        isLoaded = true
    }

    /// Save user's additional roles
    static func saveAdditionalRoles(userId: String, roles: [String]) {
        UserDefaults.standard.set(roles, forKey: "additionalRoles_\(userId)")
    }

    /// Get saved additional roles
    static func getAdditionalRoles(userId: String) -> [String] {
        UserDefaults.standard.stringArray(forKey: "additionalRoles_\(userId)") ?? []
    }

    var hasMultipleRoles: Bool {
        var count = 0
        if isCoach { count += 1 }
        if isGuardian { count += 1 }
        if isReferee { count += 1 }
        return count > 1
    }

    var availablePortals: [(name: String, icon: String, destination: ShortcutDestination)] {
        var portals: [(String, String, ShortcutDestination)] = []
        if isCoach {
            portals.append(("Coach Portal", "megaphone.fill", .coachPortal))
        }
        if isGuardian {
            portals.append(("Parent Portal", "figure.2.and.child.holdinghands", .parentPortal))
        }
        return portals
    }
}
