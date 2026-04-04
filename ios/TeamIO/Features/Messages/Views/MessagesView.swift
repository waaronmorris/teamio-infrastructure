import SwiftUI

@Observable
@MainActor
final class MessagesViewModel {
    var conversations: [Conversation] = []
    var broadcasts: [Message] = []
    var isLoading = false
    var error: String?
    var selectedTab: MessageTab = .inbox

    enum MessageTab: String, CaseIterable {
        case inbox = "Inbox"
        case broadcasts = "Broadcasts"
    }

    var unreadCount: Int {
        conversations.reduce(0) { $0 + $1.unread_count }
    }

    func load(userId: String) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        // Load conversations
        do {
            self.conversations = try await APIClient.shared.request(.conversations(userId))
        } catch {
            print("[Messages] conversations error: \(error)")
        }

        // Load inbox/broadcasts
        do {
            let inbox: InboxResponse = try await APIClient.shared.request(.inbox(userId))
            self.broadcasts = inbox.messages.map { $0.message }.filter {
                $0.message_type == "broadcast" || $0.message_type == "announcement"
            }
        } catch {
            print("[Messages] inbox error: \(error)")
        }

        isLoading = false
    }
}

struct MessagesView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = MessagesViewModel()
    @State private var showCompose = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $viewModel.selectedTab) {
                    ForEach(MessagesViewModel.MessageTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch viewModel.selectedTab {
                case .inbox:
                    conversationsList
                case .broadcasts:
                    broadcastsList
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCompose = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposeMessageSheet()
            }
            .refreshable {
                if let userId = authManager.currentUser?.id {
                    await viewModel.load(userId: userId)
                }
            }
            .task {
                if let userId = authManager.currentUser?.id {
                    await viewModel.load(userId: userId)
                }
            }
        }
    }

    private var conversationsList: some View {
        Group {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                Spacer()
                ProgressView("Loading messages...")
                Spacer()
            } else if viewModel.conversations.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "All quiet here",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Start a conversation with your team!")
                )
                Spacer()
            } else {
                List(viewModel.conversations) { conversation in
                    NavigationLink {
                        ConversationView(conversation: conversation)
                    } label: {
                        ConversationRowView(conversation: conversation)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private var broadcastsList: some View {
        Group {
            if viewModel.broadcasts.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No broadcasts yet",
                    systemImage: "megaphone",
                    description: Text("Announcements from your league will appear here.")
                )
                Spacer()
            } else {
                List(viewModel.broadcasts) { broadcast in
                    BroadcastRowView(message: broadcast)
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

struct ConversationRowView: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: conversation.displayTitle, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.displayTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    if let time = conversation.last_message?.sent_at {
                        Text(time.relativeDisplay)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    if let lastMessage = conversation.last_message {
                        Text(lastMessage.body)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    if conversation.unread_count > 0 {
                        Text("\(conversation.unread_count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct BroadcastRowView: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if message.isUrgent {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
                Text(message.subject ?? "Announcement")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(message.created_at?.relativeDisplay ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(message.body)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MessagesView()
        .environment(AuthManager())
}
