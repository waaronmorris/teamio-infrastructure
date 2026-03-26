import SwiftUI

@Observable
@MainActor
final class ConversationViewModel {
    var messages: [Message] = []
    var isLoading = false
    var isSending = false
    var error: String?

    func load(conversationId: String) async {
        isLoading = true
        do {
            messages = try await APIClient.shared.request(.conversationMessages(conversationId))
            messages.sort { ($0.sent_at ?? $0.created_at ?? .distantPast) < ($1.sent_at ?? $1.created_at ?? .distantPast) }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func send(conversationId: String, body: String) async {
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        do {
            let request = SendMessageRequest(
                conversation_id: conversationId,
                recipient_id: nil,
                body: body
            )
            let _: Message = try await APIClient.shared.request(.sendMessage(), body: request)
            await load(conversationId: conversationId)
        } catch {
            self.error = error.localizedDescription
        }
        isSending = false
    }
}

struct ConversationView: View {
    let conversation: Conversation
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = ConversationViewModel()
    @State private var messageText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromMe: message.sender_id == authManager.currentUser?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Compose bar
            HStack(spacing: 12) {
                TextField("Message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button {
                    let text = messageText
                    messageText = ""
                    Task {
                        await viewModel.send(conversationId: conversation.id, body: text)
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            }
            .padding()
        }
        .navigationTitle(conversation.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.load(conversationId: conversation.id)
        }
        .task {
            await viewModel.load(conversationId: conversation.id)
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromMe: Bool

    var body: some View {
        HStack {
            if isFromMe { Spacer(minLength: 60) }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                if !isFromMe, let name = message.sender_name {
                    Text(name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(message.body)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isFromMe ? Color.accentColor : Color(.secondarySystemBackground))
                    .foregroundStyle(isFromMe ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text((message.sent_at ?? message.created_at ?? Date()).shortTime)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if !isFromMe { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    NavigationStack {
        ConversationView(
            conversation: Conversation(
                id: "1",
                conversation_type: "direct",
                title: "Coach Smith",
                participants: nil,
                last_message: nil,
                unread_count: 0,
                created_at: .now
            )
        )
        .environment(AuthManager())
    }
}
