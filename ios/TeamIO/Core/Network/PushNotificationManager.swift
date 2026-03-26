import Foundation
import UserNotifications
import UIKit

@MainActor
@Observable
final class PushNotificationManager: NSObject {
    static let shared = PushNotificationManager()

    var isAuthorized = false
    var deviceToken: String?

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            isAuthorized = false
        }
    }

    func checkStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func handleDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        Task {
            await registerTokenWithServer(token)
        }
    }

    private func registerTokenWithServer(_ token: String) async {
        struct TokenRequest: Encodable, Sendable {
            let device_token: String
            let platform: String
        }
        do {
            try await APIClient.shared.requestVoid(
                APIEndpoint("/notifications/device-token", method: .post),
                body: TokenRequest(device_token: token, platform: "ios")
            )
        } catch {
            // Best effort
        }
    }

    func scheduleLocalNotification(title: String, body: String, timeInterval: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Notification Payload Parsing

struct PushPayload {
    let type: PushType
    let resourceId: String?

    enum PushType: String {
        case event
        case message
        case broadcast
        case registration
        case draft
        case unknown
    }

    init(userInfo: [AnyHashable: Any]) {
        let typeString = userInfo["type"] as? String ?? "unknown"
        self.type = PushType(rawValue: typeString) ?? .unknown
        self.resourceId = userInfo["resource_id"] as? String
    }
}
