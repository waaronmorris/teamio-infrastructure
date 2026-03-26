import Foundation

/// Manages the user's active roles. Since a single user can be a coach, parent, AND referee,
/// this tracks all applicable roles and lets the user switch between them.
///
/// Detection strategy: Primary role from JWT + user self-declaration in settings.
/// The backend restricts portal access by primary role, so we can't probe endpoints.
@Observable
@MainActor
final class UserRolesManager {
    var isCoach = false
    var isGuardian = false
    var isReferee = false
    var refereeId: String?
    var isLoaded = false

    /// Detect roles from primary + stored additional roles
    func detectRoles(userId: String, primaryRole: UserRole) async {
        // Primary role
        switch primaryRole {
        case .coach: isCoach = true
        case .parent, .guardian: isGuardian = true
        case .admin, .commissioner: isCoach = false; isGuardian = false // admins see everything
        default: break
        }

        // Load additional roles from UserDefaults (user self-declared)
        let additionalRoles = UserDefaults.standard.stringArray(forKey: "additionalRoles_\(userId)") ?? []
        if additionalRoles.contains("coach") { isCoach = true }
        if additionalRoles.contains("parent") { isGuardian = true }
        if additionalRoles.contains("referee") { isReferee = true }

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
