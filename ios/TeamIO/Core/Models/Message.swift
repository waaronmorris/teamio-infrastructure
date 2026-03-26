import Foundation

struct Message: Codable, Identifiable, Sendable {
    let id: String
    let sender_id: String
    let sender_name: String?
    let message_type: String?
    let subject: String?
    let body: String
    let priority: String?
    let scope_type: String?
    let scope_id: String?
    let recipient_count: Int?
    let read_count: Int?
    let sent_at: Date?
    let created_at: Date?

    var isUrgent: Bool {
        priority == "urgent" || priority == "emergency"
    }
}

struct Conversation: Codable, Identifiable, Sendable {
    let id: String
    let conversation_type: String?
    let title: String?
    let participants: [ConversationParticipant]?
    let last_message: LastMessage?
    let unread_count: Int
    let created_at: Date?

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return participants?.map { $0.name }.joined(separator: ", ") ?? "Conversation"
    }
}

struct ConversationParticipant: Codable, Sendable {
    let user_id: String
    let name: String
    let email: String?
}

struct LastMessage: Codable, Sendable {
    let id: String
    let body: String
    let sent_at: Date?
}

struct InboxMessage: Codable, Identifiable, Sendable {
    let message: Message
    let is_read: Bool
    let read_at: Date?

    var id: String { message.id }
}

struct SendMessageRequest: Encodable, Sendable {
    let conversation_id: String?
    let recipient_id: String?
    let body: String
}

struct Broadcast: Codable, Identifiable, Sendable {
    let id: String
    let subject: String?
    let body: String
    let priority: String?
    let scope_type: String?
    let scope_id: String?
    let broadcast_type: String?
    let created_at: Date?
}
