import SwiftUI

@Observable
@MainActor
final class NotificationsViewModel {
    var notifications: [Notification] = []
    var isLoading = false
    var error: String?

    var unreadCount: Int {
        notifications.filter { !$0.is_read }.count
    }

    func load() async {
        isLoading = true
        do {
            notifications = try await APIClient.shared.request(.notifications())
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func markRead(_ id: String) async {
        do {
            try await APIClient.shared.requestVoid(.markNotificationRead(id))
            if let idx = notifications.firstIndex(where: { $0.id == id }) {
                let old = notifications[idx]
                notifications[idx] = Notification(
                    id: old.id,
                    user_id: old.user_id,
                    title: old.title,
                    body: old.body,
                    notification_type: old.notification_type,
                    is_read: true,
                    read_at: Date(),
                    created_at: old.created_at
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func markAllRead() async {
        do {
            try await APIClient.shared.requestVoid(.markAllNotificationsRead())
            for i in notifications.indices {
                let old = notifications[i]
                notifications[i] = Notification(
                    id: old.id,
                    user_id: old.user_id,
                    title: old.title,
                    body: old.body,
                    notification_type: old.notification_type,
                    is_read: true,
                    read_at: Date(),
                    created_at: old.created_at
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct NotificationsView: View {
    @State private var viewModel = NotificationsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView("Loading notifications...")
                } else if viewModel.notifications.isEmpty {
                    ContentUnavailableView(
                        "No Notifications",
                        systemImage: "bell.slash",
                        description: Text("You're all caught up.")
                    )
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRow(notification: notification)
                                .onTapGesture {
                                    if !notification.is_read {
                                        Task { await viewModel.markRead(notification.id) }
                                    }
                                }
                                .listRowBackground(
                                    notification.is_read ? Color.clear : Color.accentColor.opacity(0.05)
                                )
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                if viewModel.unreadCount > 0 {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Mark All Read") {
                            Task { await viewModel.markAllRead() }
                        }
                        .font(.subheadline)
                    }
                }
            }
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
        }
    }
}

struct NotificationRow: View {
    let notification: Notification

    var body: some View {
        HStack(spacing: 12) {
            if !notification.is_read {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 8, height: 8)
            }

            Image(systemName: notificationIcon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title ?? "Notification")
                    .font(.subheadline.weight(notification.is_read ? .regular : .semibold))
                if let body = notification.body {
                    Text(body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Text(notification.created_at?.relativeDisplay ?? "")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var notificationIcon: String {
        switch notification.notification_type {
        case "message": return "bubble.left.fill"
        case "event": return "calendar.badge.exclamationmark"
        case "registration": return "person.badge.plus"
        case "schedule": return "clock.badge.exclamationmark"
        case "broadcast": return "megaphone.fill"
        default: return "bell.fill"
        }
    }
}

#Preview {
    NotificationsView()
}
