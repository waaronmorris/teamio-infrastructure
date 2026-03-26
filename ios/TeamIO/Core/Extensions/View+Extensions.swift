import SwiftUI

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Event Type Helpers

extension String {
    var eventTypeIcon: String {
        switch self {
        case "game": return "sportscourt.fill"
        case "practice": return "figure.run"
        case "scrimmage": return "figure.2.and.child.holdinghands"
        case "tournament": return "trophy.fill"
        case "meeting", "team_meeting", "parent_meeting": return "person.3.fill"
        case "fundraiser": return "dollarsign.circle.fill"
        case "party", "social": return "party.popper.fill"
        default: return "calendar"
        }
    }

    var eventStatusColor: Color {
        switch self {
        case "scheduled": return .blue
        case "in_progress": return .orange
        case "completed": return .green
        case "cancelled": return .red
        case "postponed": return .yellow
        default: return .secondary
        }
    }

    var registrationStatusColor: Color {
        switch self {
        case "approved": return .green
        case "pending": return .orange
        case "rejected": return .red
        case "waitlisted": return .yellow
        case "cancelled": return .secondary
        default: return .secondary
        }
    }

    var rsvpIcon: String {
        switch self {
        case "accepted": return "checkmark.circle.fill"
        case "declined": return "xmark.circle.fill"
        case "tentative": return "questionmark.circle.fill"
        default: return "circle"
        }
    }

    var rsvpColor: Color {
        switch self {
        case "accepted": return .green
        case "declined": return .red
        case "tentative": return .orange
        default: return .secondary
        }
    }
}

// MARK: - Avatar View

struct AvatarView: View {
    let name: String
    var size: CGFloat = 40

    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    var body: some View {
        Circle()
            .fill(Color.accentColor.opacity(0.2))
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
    }
}
